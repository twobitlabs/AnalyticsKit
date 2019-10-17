#import "MPExceptionHandler.h"
#import "MPMessage.h"
#import "MPIConstants.h"
#import <dispatch/dispatch.h>
#import <execinfo.h>
#import <signal.h>
#import <sys/sysctl.h>
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPBreadcrumb.h"
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <libkern/OSAtomic.h>
#import "MPCurrentState.h"
#import "MPIUserDefaults.h"
#import "MPMessageBuilder.h"
#import <UIKit/UIKit.h>
#import "MPPersistenceController.h"
#import "MPILogger.h"
#import "MPMessageBuilder.h"
#import "MPApplication.h"
#import "mParticle.h"
#import "MPArchivist.h"

#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    #import <mParticle-CrashReporter/CrashReporter.h>
    static PLCrashReporter *_crashReporter;
#endif

NSString *const kMPAppImageBaseAddressKey = @"iba";
NSString *const kMPAppImageSizeKey = @"is";

static BOOL handlingExceptions;

void SignalHandler(int signal);
void EndUncaughtExceptionLogging(void);
void handleException(NSException *exception);
static bool debuggerRunning(void);

typedef struct Binaryimage {
    struct Binaryimage *previous;
    struct Binaryimage *next;
    uintptr_t header;
    char *name;
} BinaryImage;

typedef struct BinaryImageList {
    BinaryImage *headBinaryImage;
    BinaryImage *tailBinaryImage;
    BinaryImage *free;
    int32_t referenceCount;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSSpinLock write_lock;
#pragma clang diagnostic pop
} BinaryImageList;

//
// C functions prototype declarations
//
static BinaryImageList sharedImageList = { 0 }; // Shared dyld image list
static void appendImageList(BinaryImageList *list, uintptr_t header, const char *name);
static void flagReadingImageList(BinaryImageList *list, bool enable);
static BinaryImage *nextImageList(BinaryImageList *list, BinaryImage *current);
static void addImageListCallback(const struct mach_header *mh, intptr_t vmaddr_slide);
static void processBinaryImage(const char *name, const void *header, struct uuid_command *out_uuid, uintptr_t *out_baseaddr, uintptr_t *out_cmdsize);

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@implementation MPExceptionHandler

+ (void)initialize {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    _crashReporter = nil;
#endif
    handlingExceptions = NO;
}

- (instancetype)init {
    return [self initWithSession:nil];
}

- (instancetype)initWithSession:(MPSession *)session {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _session = session;
    
    [self registerCallback];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleCrashReportOccurred:)
                               name:kMPCrashReportOccurredNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleConfigureExceptionHandling:)
                               name:kMPConfigureExceptionHandlingNotification
                             object:nil];
    
    [self processPendingCrashReport];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:kMPCrashReportOccurredNotification object:nil];
    [notificationCenter removeObserver:self name:kMPConfigureExceptionHandlingNotification object:nil];
}

#pragma mark Private methods
- (MPSession *)crashSession {
    MPSession *crashSession = nil;
    NSArray<MPSession *> *sessions = [[MParticle sharedInstance].persistenceController fetchPossibleSessionsFromCrash];
    
    for (MPSession *session in sessions) {
        if (![session isEqual:_session]) {
            crashSession = session;
            break;
        }
    }
    
    return crashSession;
}

- (void)logException:(NSException *)exception {
    NSMutableDictionary *exceptionInfo = [@{kMPCrashingSeverity:@"fatal",
                                            kMPCrashWasHandled:@"false",
                                            kMPCrashingClass:exception.name,
                                            kMPErrorMessage:exception.reason,
                                            kMPStackTrace:exception.userInfo[kMPStackTrace]}
                                          mutableCopy];
    
    id topmostContext = [self topmostContext];
    if (topmostContext) {
        exceptionInfo[kMPTopmostContext] = topmostContext;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:self.session messageInfo:exceptionInfo];
    MPMessage *message = [messageBuilder build];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *crashLogsDirectoryPath = CRASH_LOGS_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:crashLogsDirectoryPath]) {
        [fileManager createDirectoryAtPath:crashLogsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *crashLogPath = [crashLogsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%.0f.log", message.uuid, message.timestamp]];
    NSError *error = nil;
    BOOL success = [MPArchivist archiveDataWithRootObject:message toFile:crashLogPath error:&error];
    if (!success) {
        NSLog(@"mParticle -> Crash log not archived. error=%@", error);
    }
}

- (id)topViewControllerForController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerForController:((UITabBarController *)viewController).selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerForController:((UINavigationController *)viewController).visibleViewController];
    } else if (viewController.presentedViewController) {
        return [self topViewControllerForController:viewController.presentedViewController];
    } else {
        return viewController;
    }
}

- (NSString *)topmostContext {
    if (![MPStateMachine isAppExtension]) {
        UIViewController *rootViewController = [MPApplication sharedUIApplication].keyWindow.rootViewController;
        id topmostContext = [self topViewControllerForController:rootViewController];
        NSString *topmostContextName = [[topmostContext class] description];
        return topmostContextName;
    }
    return @"extension_context";
}

- (NSDictionary *)loadArchivedCrashInfo {
    __block NSMutableDictionary *crashInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:archivedMessagesDirectoryPath]) {
        id topmostContext = [self topmostContext];
        if (topmostContext) {
            crashInfo[kMPTopmostContext] = topmostContext;
        }
    }
    
    typedef NS_ENUM(NSUInteger, CrashArchiveType) {
        CrashArchiveTypeCurrentState = 0,
        CrashArchiveTypeTopmostController,
        CrashArchiveTypeException,
        CrashArchiveTypeStackTrace,
        CrashArchiveTypeAppImageInfo
    };
    
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:archivedMessagesDirectoryPath error:nil];
    NSArray *predicateStrings = @[@"self ENDSWITH '.cs'",
                                  @"self ENDSWITH '.tc'",
                                  @"self ENDSWITH '.ex'",
                                  @"self ENDSWITH '.st'",
                                  @"self ENDSWITH '.aii'"];
    
    NSArray *keys = @[kMPStateInformationKey,
                      kMPTopmostContext,
                      kMPCrashExceptionKey,
                      kMPStackTrace,
                      @"AppImageInfo"];
    
    [predicateStrings enumerateObjectsUsingBlock:^(NSString *predicateString, CrashArchiveType idx, BOOL *stop) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
        NSArray *fileNames = [directoryContents filteredArrayUsingPredicate:predicate];
        NSString *fileName = [fileNames lastObject];
        NSString *key = keys[idx];
        NSDictionary *unarchivedDictionary;
        
        if (fileName && !crashInfo[key]) {
            NSString *filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:fileName];
            
            id value = nil;
            switch (idx) {
                case CrashArchiveTypeCurrentState:
                    value = [MPArchivist unarchiveObjectOfClass:[NSObject class] withFile:filePath error:nil];
                    break;

                case CrashArchiveTypeException: {
                    NSException *exception = [MPArchivist unarchiveObjectOfClass:[NSException class] withFile:filePath error:nil];
                    
                    crashInfo[kMPErrorMessage] = [exception reason];
                    crashInfo[kMPCrashingClass] = [exception name];
                }
                    break;
                    
                case CrashArchiveTypeAppImageInfo:
                    unarchivedDictionary = [MPArchivist unarchiveObjectOfClass:[NSDictionary class] withFile:filePath error:nil];
                    
                    key = kMPAppImageBaseAddressKey;
                    value = unarchivedDictionary[key];
                    crashInfo[key] = value;
                    
                    key = kMPAppImageSizeKey;
                    value = unarchivedDictionary[key];
                    break;
                    
                default:
                    unarchivedDictionary = [MPArchivist unarchiveObjectOfClass:[NSDictionary class] withFile:filePath error:nil];
                    value = unarchivedDictionary[key];
                    break;
            }
            
            if (value) {
                crashInfo[key] = value;
            }
            
            for (fileName in fileNames) {
                filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:fileName];
                [fileManager removeItemAtPath:filePath error:nil];
            }
        }
    }];
    
    return [crashInfo copy];
}

- (void)processPendingCrashReport {
    NSData *crashData = nil;
    
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    if (![PLCrashReporter hasPendingCrashReport]) {
        return;
    }
    
    NSError *error = nil;
    crashData = [PLCrashReporter loadPendingCrashReportDataAndReturnError:&error];
#endif
    
    if (crashData) {
        NSString *base64CrashString = [crashData base64EncodedStringWithOptions:0];
        
        NSMutableDictionary *messageInfo = [@{kMPCrashingSeverity:@"fatal",
                                              kMPCrashWasHandled:@"false",
                                              kMPPLCrashReport:base64CrashString}
                                            mutableCopy];
        
        NSDictionary *archivedCrashInfo = [self loadArchivedCrashInfo];
        [messageInfo addEntriesFromDictionary:archivedCrashInfo];
        
        MPSession *crashSession = [self crashSession];
        
        MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
        NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [persistence fetchBreadcrumbs];
        
        if (fetchedbreadcrumbs) {
            NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
            
            for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
                [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
            }
            
            messageInfo[kMPMessageTypeLeaveBreadcrumbs] = breadcrumbs;
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:crashSession messageInfo:messageInfo];
        MPMessage *message = [messageBuilder build];
        [persistence saveMessage:message];
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    } else {
        MPILogError(@"Could not process pending crash report with error: %@", error);
#endif
    }
    
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    [PLCrashReporter purgePendingCrashReport];
#endif
}

- (void)registerCallback {
    _dyld_register_func_for_add_image(addImageListCallback);
}

#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
+ (PLCrashReporter *)crashReporter {
    if (_crashReporter) {
        return _crashReporter;
    }
    
    PLCrashReporterConfig *crashReporterConfig = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach
                                                                                    symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
    
    _crashReporter = [[PLCrashReporter alloc] initWithConfiguration:crashReporterConfig];
    
    return _crashReporter;
}
#endif

#pragma mark Notification handlers
- (void)handleCrashReportOccurred:(NSNotification *)notification {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Previous Session State
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSDictionary *previousSessionStateDictionary = @{kMPASTPreviousSessionSuccessfullyClosedKey:@NO};
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        [fileManager removeItemAtPath:previousSessionStateFile error:nil];
    }
    [previousSessionStateDictionary writeToFile:previousSessionStateFile atomically:YES];

    // Archived messages directory
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:archivedMessagesDirectoryPath]) {
        [fileManager createDirectoryAtPath:archivedMessagesDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSTimeInterval timestamp = trunc([[NSDate date] timeIntervalSince1970]);
    NSString *filePath;
    BOOL success;

    // Current State
    filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"CurrentState-%.0f.cs", timestamp]];
    MPCurrentState *currentState = [[MPCurrentState alloc] init];
    NSError *error = nil;
    success = [MPArchivist archiveDataWithRootObject:[currentState dictionaryRepresentation] toFile:filePath error:&error];
    if (!success) {
        MPILogError(@"Application will crash, current state not archived. error=%@", error);
    }
    
    // Topmost Context
    NSString *topmostContextName = [self topmostContext];
    NSDictionary *archiveDictionary = nil;
    if (topmostContextName) {
        archiveDictionary = @{kMPTopmostContext:topmostContextName};
        filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"TopmostContext-%.0f.tc", timestamp]];
        NSError *error = nil;
        success = [MPArchivist archiveDataWithRootObject:archiveDictionary toFile:filePath error:&error];
        if (!success) {
            MPILogError(@"Application will crash, topmost context not archived. error=%@", error);
        }
    }
    
    // Exception
    NSDictionary *userInfo = [notification userInfo];
    NSException *exception = userInfo[kMPCrashExceptionKey];
    if (exception) {
        filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Exception-%.0f.ex", timestamp]];
        NSError *error = nil;
        success = [MPArchivist archiveDataWithRootObject:exception toFile:filePath error:&error];
        if (!success) {
            MPILogError(@"Application will crash, topmost context not archived. error=%@", error);
        }
    }

    // Stack Trace
    NSArray *callStack = [exception callStackSymbols];
    if (callStack) {
        archiveDictionary = @{kMPStackTrace:[callStack componentsJoinedByString:@"\n"]};
        filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"StackTrace-%.0f.st", timestamp]];
        NSError *error = nil;
        success = [MPArchivist archiveDataWithRootObject:archiveDictionary toFile:filePath error:&error];
        if (!success) {
            MPILogError(@"Application will crash, stack trace not archived. error=%@", error);
        }
    }
    
    // App Image Info
    archiveDictionary = [MPExceptionHandler appImageInfo];
    if (archiveDictionary) {
        filePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"AppImageInfo-%.0f.aii", timestamp]];
        NSError *error = nil;
        success = [MPArchivist archiveDataWithRootObject:archiveDictionary toFile:filePath error:&error];
        if (!success) {
            MPILogError(@"Application will crash, app image info not archived. error=%@", error);
        }
    }
}

- (void)handleConfigureExceptionHandling:(NSNotification *)notification {
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    if ([stateMachine.exceptionHandlingMode isEqualToString:kMPRemoteConfigExceptionHandlingModeIgnore] && handlingExceptions) {
        [self endUncaughtExceptionLogging];
    } else if ([stateMachine.exceptionHandlingMode isEqualToString:kMPRemoteConfigExceptionHandlingModeForce] && !handlingExceptions) {
        [self beginUncaughtExceptionLogging];
    }
}

#pragma mark Class methods
+ (NSDictionary *)appImageInfo {
    struct uuid_command uuid = {0};
    uintptr_t baseaddr = 0;
    uintptr_t cmdsize = 0;
    uintptr_t imageBaseAddress = 0;
    unsigned long long imageSize = 0;
    
    flagReadingImageList(&sharedImageList, true);
    
    BinaryImage *image = NULL;
    while ((image = nextImageList(&sharedImageList, image)) != NULL) {
        processBinaryImage(image->name, (const void *)(image->header), &uuid, &baseaddr, &cmdsize);
        
        if (imageBaseAddress == 0) {
            imageBaseAddress = baseaddr;
        }
        
        imageSize += cmdsize;
    }
    
    NSDictionary *appImageInfo = @{kMPAppImageBaseAddressKey:@(imageBaseAddress),
                                   kMPAppImageSizeKey:@(imageSize)};
    
    return appImageInfo;
}

+ (NSString *)callStack {
    void *callstack[512];
    int numberOfItems = backtrace(callstack, 512);
    char **strs = backtrace_symbols(callstack, numberOfItems);
    
    NSMutableArray *stackArray = [NSMutableArray arrayWithCapacity:numberOfItems];
    for (int i = 2; i < numberOfItems; ++i) {
        [stackArray addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    
    free(strs);
    
    NSString *callStackString = [stackArray componentsJoinedByString:@"\n"];
    
    return callStackString;
}

+ (BOOL)isHandlingExceptions {
    return handlingExceptions;
}

+ (NSData *)generateLiveExceptionReport {
    NSError *error = nil;
    NSData *liveExceptionReport = nil;
    
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    liveExceptionReport = [[MPExceptionHandler crashReporter] generateLiveReportAndReturnError:&error];
#endif
    
    if (error) {
        return nil;
    }
    
    return liveExceptionReport;
}

#pragma mark Public methods
- (void)beginUncaughtExceptionLogging {
    if (handlingExceptions || [[MParticle sharedInstance].stateMachine.exceptionHandlingMode isEqualToString:kMPRemoteConfigExceptionHandlingModeIgnore]) {
        return;
    }
    
    handlingExceptions = YES;
    
    if (debuggerRunning()) {
        return;
    }
    
    NSError *error = nil;
    BOOL crashReporterEnabled = NO;
    
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    crashReporterEnabled = [[MPExceptionHandler crashReporter] enableCrashReporterAndReturnError:&error];
#endif
    
    if (!crashReporterEnabled) {
        MPILogError(@"Could not enable crash reporter with error: %@", error);
    }
}

- (void)endUncaughtExceptionLogging {
    if ([[MParticle sharedInstance].stateMachine.exceptionHandlingMode isEqualToString:kMPRemoteConfigExceptionHandlingModeForce]) {
        return;
    }
    
    handlingExceptions = NO;
    
    if (debuggerRunning()) {
        return;
    }
    
    EndUncaughtExceptionLogging();
}

@end


#pragma mark C functions
void SignalHandler(int signal) {
	NSString *callStack = [MPExceptionHandler callStack];
	NSDictionary *userInfo = @{kMPCrashSignal:@(signal), kMPStackTrace:callStack};
	
    MPExceptionHandler *exceptionHandler = [[MPExceptionHandler alloc] initWithSession:[MParticle sharedInstance].stateMachine.currentSession];
    NSException *exceptionToLog = [NSException exceptionWithName:@"UncaughtExceptionSignal" reason:[NSString stringWithFormat:@"Signal %d raised.", signal] userInfo:userInfo];
    [exceptionHandler logException:exceptionToLog];
}

void EndUncaughtExceptionLogging() {
	NSSetUncaughtExceptionHandler(nil);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}

void handleException(NSException *exception) {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    if ([exception userInfo]) {
        [userInfo addEntriesFromDictionary:[exception userInfo]];
    }
    
    NSArray *callStack = [exception callStackSymbols];
    userInfo[kMPStackTrace] = [callStack componentsJoinedByString:@"\n"];
    
    MPExceptionHandler *exceptionHandler = [[MPExceptionHandler alloc] initWithSession:[MParticle sharedInstance].stateMachine.currentSession];
    NSException *exceptionToLog = [NSException exceptionWithName:exception.name reason:exception.reason userInfo:userInfo];
    [exceptionHandler logException:exceptionToLog];
}

static bool debuggerRunning() {
    int numberOfBytes = 4;
    int *name = malloc(numberOfBytes * sizeof(int));
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    struct kinfo_proc info;
    size_t infoSize = sizeof(info);
    info.kp_proc.p_flag = 0;
    
    sysctl(name, numberOfBytes, &info, &infoSize, NULL, 0);
    free(name);
    bool isDebuggerRunning = (info.kp_proc.p_flag & P_TRACED) != 0;
    
    return isDebuggerRunning;
}

/**
 @internal
 
 Maintains a linked list of binary images with support for async-safe iteration. Writing may occur concurrently with
 async-safe reading, but is not async-safe.
 
 Atomic compare and swap is used to ensure a consistent view of the list for readers. To simplify implementation, a
 write mutex is held for all updates; the implementation is not designed for efficiency in the face of contention
 between readers and writers, and it's assumed that no contention should realistically occur.
 */

/**
 Append a new binary image record to @a list.
 
 @param list The list to which the image record should be appended.
 @param header The image's header address.
 @param name The image's name.
 */
static void appendImageList(BinaryImageList *list, uintptr_t header, const char *name) {
    // Initialize the new entry.
    BinaryImage *new = calloc(1, sizeof(BinaryImage));
    new->header = header;
    new->name = strdup(name);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Update the image record and issue a memory barrier to ensure a consistent view.
    OSMemoryBarrier();
    
    /* Lock the list from other writers. */
    OSSpinLockLock(&list->write_lock); {
        /* If this is the first entry, initialize the list. */
        if (list->tailBinaryImage == NULL) {
            // Update the list tail. This need not be done atomically, as tail is never accessed by a lockless reader
            list->tailBinaryImage = new;
            
            // Atomically update the list head; this will be iterated upon by lockless readers
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->headBinaryImage))) {
                NSLog(@"An async image head was set with tail == NULL despite holding lock.");
            }
        } else {
            // Atomically slot the new record into place; this may be iterated on by a lockless reader
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->tailBinaryImage->next))) {
                NSLog(@"Failed to append to image list despite holding lock");
            }
            
            // Update the previous and tail pointers. This is never accessed without a lock, so no additional barrier is required here
            new->previous = list->tailBinaryImage;
            list->tailBinaryImage = new;
        }
    } OSSpinLockUnlock(&list->write_lock);
#pragma clang diagnostic pop
}

/**
 Retain or release the list for reading. This method is async-safe.
 
 This must be issued prior to attempting to iterate the list, and must called again once reads have completed.
 
 @param list The list to be be retained or released for reading.
 @param enable If true, the list will be retained. If false, released.
 */
static void flagReadingImageList(BinaryImageList *list, bool enable) {
    if (enable) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Increment and issue a barrier. Once issued, no items will be deallocated while a reference is held
        OSAtomicIncrement32Barrier(&list->referenceCount);
    } else {
        // Increment and issue a barrier. Once issued, items may again be deallocated
        OSAtomicDecrement32Barrier(&list->referenceCount);
    }
#pragma clang diagnostic pop
}

/**
 Returns the next image record. This method is async-safe. If no additional images are available, will return NULL;
 
 @param list The list to be iterated.
 @param current The current image record, or NULL to start iteration.
 */
static BinaryImage *nextImageList(BinaryImageList *list, BinaryImage *current) {
    if (current != NULL)
        return current->next;
    
    return list->headBinaryImage;
}

static void addImageListCallback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    
    // Look up the image info
    if (dladdr(mh, &info) == 0) {
        NSLog(@"%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
        return;
    }
    
    appendImageList(&sharedImageList, (uintptr_t) mh, info.dli_fname);
}

static void processBinaryImage(const char *name, const void *header, struct uuid_command *out_uuid, uintptr_t *out_baseaddr, uintptr_t *out_cmdsize) {
    uint32_t ncmds;
    const struct mach_header *header32 = (const struct mach_header *)header;
    const struct mach_header_64 *header64 = (const struct mach_header_64 *)header;
    
    struct load_command *cmd;
    uintptr_t cmd_size;
    
    // Check for headers and extract required values
    switch (header32->magic) {
        // 32-bit
        case MH_MAGIC:
        case MH_CIGAM:
            ncmds = header32->ncmds;
            cmd = (struct load_command *)(header32 + 1);
            cmd_size = header32->sizeofcmds;
            break;
            
        // 64-bit
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            ncmds = header64->ncmds;
            cmd = (struct load_command *)(header64 + 1);
            cmd_size = header64->sizeofcmds;
            break;
            
        default:
            NSLog(@"Invalid Mach-O header magic value: %x", header32->magic);
            return;
    }
    
    // Compute the image size and search for a UUID
    struct uuid_command *uuid = NULL;
    for (uint32_t i = 0; cmd != NULL && i < ncmds; ++i) {
        // DWARF dSYM UUID
        if (cmd->cmd == LC_UUID && cmd->cmdsize == sizeof(struct uuid_command)) {
            uuid = (struct uuid_command *)cmd;
        }
        
        cmd = (struct load_command *)((uint8_t *) cmd + cmd->cmdsize);
    }
    
    uintptr_t base_addr = (uintptr_t)header;
    *out_baseaddr = base_addr;
    *out_cmdsize = cmd_size;
    
    if (out_uuid && uuid) {
        memcpy(out_uuid, uuid, sizeof(struct uuid_command));
    }
}
