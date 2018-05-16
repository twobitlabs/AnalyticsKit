#import "MPBackendController.h"
#import "MPAppDelegateProxy.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPNetworkPerformance.h"
#import "MPIUserDefaults.h"
#import "MPBreadcrumb.h"
#import "MPExceptionHandler.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPMessageBuilder.h"
#import "MPEvent.h"
#import "MPEvent+Internal.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPHasher.h"
#import "MPUploadBuilder.h"
#import "MPILogger.h"
#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPResponseConfig.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCart.h"
#import "MPCart+Dictionary.h"
#import "MPEvent+MessageType.h"
#include "MessageTypeName.h"
#import "MPKitContainer.h"
#import "MPUserAttributeChange.h"
#import "MPUserIdentityChange.h"
#import "MPSearchAdsAttribution.h"
#import "MPURLRequestBuilder.h"

#if TARGET_OS_IOS == 1
#import "MPLocationManager.h"
#endif

const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold = 1000;
const NSInteger kInvalidValue = 101;
const NSInteger kEmptyValueAttribute = 102;
const NSInteger kExceededNumberOfAttributesLimit = 103;
const NSInteger kExceededAttributeMaximumLength = 104;
const NSInteger kExceededKeyMaximumLength = 105;
const NSInteger kInvalidDataType = 106;
const NSTimeInterval kMPMaximumKitWaitTimeSeconds = 5;

static NSArray *execStatusDescriptions;
static BOOL appBackgrounded = NO;

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@end

@interface MPBackendController() {
    MPAppDelegateProxy *appDelegateProxy;
    NSMutableSet<NSString *> *deletedUserAttributes;
    __weak MPSession *sessionBeingUploaded;
    NSNotification *didFinishLaunchingNotification;
    NSTimeInterval nextCleanUpTime;
    NSTimeInterval timeAppWentToBackground;
    NSTimeInterval backgroundStartTime;
    dispatch_source_t backgroundSource;
    dispatch_source_t uploadSource;
    UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
    dispatch_semaphore_t backendSemaphore;
    dispatch_queue_t messageQueue;
    BOOL longSession;
    BOOL originalAppDelegateProxied;
    BOOL resignedActive;
    BOOL retrievingSegments;
}

@end


@implementation MPBackendController
@synthesize session = _session;
@synthesize uploadInterval = _uploadInterval;

#if TARGET_OS_IOS == 1
@synthesize notificationController = _notificationController;
#endif

+ (void)initialize {
    execStatusDescriptions = @[@"Success", @"Fail", @"Missing Parameter", @"Feature Disabled Remotely", @"Feature Enabled Remotely", @"User Opted Out of Tracking", @"Data Already Being Fetched",
                               @"Invalid Data Type", @"Data is Being Uploaded", @"Server is Busy", @"Item Not Found", @"Feature is Disabled in Settings", @"There is no network connectivity"];
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        messageQueue = [MParticle messageQueue];
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        nextCleanUpTime = [[NSDate date] timeIntervalSince1970];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        retrievingSegments = NO;
        _delegate = delegate;
        backgroundStartTime = 0;
        longSession = NO;
        resignedActive = NO;
        sessionBeingUploaded = nil;
        backgroundSource = nil;
        uploadSource = nil;
        originalAppDelegateProxied = NO;
        backendSemaphore = dispatch_semaphore_create(1);
        timeAppWentToBackground = 0;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillTerminate:)
                                   name:UIApplicationWillTerminateNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleNetworkPerformanceNotification:)
                                   name:kMPNetworkPerformanceMeasurementNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleMemoryWarningNotification:)
                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        
#if TARGET_OS_IOS == 1
        [notificationCenter addObserver:self
                               selector:@selector(handleDeviceTokenNotification:)
                                   name:kMPRemoteNotificationDeviceTokenNotification
                                 object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter removeObserver:self name:kMPNetworkPerformanceMeasurementNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
#if TARGET_OS_IOS == 1
    [notificationCenter removeObserver:self name:kMPRemoteNotificationDeviceTokenNotification object:nil];
#endif
    
    [self endUploadTimer];
}

#pragma mark Accessors
- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (MPNetworkCommunication *)networkCommunication {
    if (_networkCommunication) {
        return _networkCommunication;
    }
    
    [self willChangeValueForKey:@"networkCommunication"];
    _networkCommunication = [[MPNetworkCommunication alloc] init];
    [self didChangeValueForKey:@"networkCommunication"];
    
    return _networkCommunication;
}

- (MPSession *)session {
    if (!MParticle.sharedInstance.automaticSessionTracking) {
        return nil;
    }
    
    bool isNewSession = NO;
    if (!_session) {
        dispatch_semaphore_wait(backendSemaphore, DISPATCH_TIME_FOREVER);
        [self willChangeValueForKey:@"session"];
        
        [self beginSession:nil];
        isNewSession = YES;
        dispatch_semaphore_signal(backendSemaphore);
    }

    if (isNewSession) {
        [self didChangeValueForKey:@"session"];
    }
    
    return _session;
}

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSMutableDictionary *userAttributes = [[userDefaults mpObjectForKey:kMPUserAttributeKey userId:userId] mutableCopy];
    if (userAttributes) {
        Class NSStringClass = [NSString class];
        for (NSString *key in [userAttributes allKeys]) {
            if ([userAttributes[key] isKindOfClass:NSStringClass]) {
                userAttributes[key] = ![userAttributes[key] isEqualToString:kMPNullUserAttributeString] ? userAttributes[key] : [NSNull null];
            } else {
                userAttributes[key] = userAttributes[key];
            }

        }
        return userAttributes;
    } else {
        return [NSMutableDictionary dictionary];
    }
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId {
    
    NSMutableArray *userIdentities = [[NSMutableArray alloc] initWithCapacity:10];
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSArray *userIdentityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:userId];
    if (userIdentityArray) {
        [userIdentities addObjectsFromArray:userIdentityArray];
    }
    
    return userIdentities;
}

#pragma mark Private methods
- (void)beginBackgroundTask NS_EXTENSION_UNAVAILABLE_IOS(""){
    __weak MPBackendController *weakSelf = self;
    
    if (backendBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        backendBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            MPILogDebug(@"SDK has ended background activity together with the app.");

            [MPStateMachine setRunningInBackground:NO];
            [[MPPersistenceController sharedInstance] purgeMemory];
            
            __strong MPBackendController *strongSelf = weakSelf;
            
            if (strongSelf) {
                [strongSelf endBackgroundTimer];
                
                strongSelf->_networkCommunication = nil;
                
                if (strongSelf->_session) {
                    [strongSelf broadcastSessionDidEnd:strongSelf->_session];
                    strongSelf->_session = nil;
                    
                    if (strongSelf.eventSet.count == 0) {
                        strongSelf->_eventSet = nil;
                    }
                }
                
                [strongSelf endBackgroundTask];
            }
        }];
    }
}

- (void)endBackgroundTask NS_EXTENSION_UNAVAILABLE_IOS(""){
    if (backendBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backendBackgroundTaskIdentifier];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)broadcastSessionDidBegin:(MPSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate sessionDidBegin:session];
    });
    
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf) {
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidBeginNotification
                                                                object:strongSelf.delegate
                                                              userInfo:@{mParticleSessionId:@(session.sessionId)}];
        }
    });
}

- (void)broadcastSessionDidEnd:(MPSession *)session {
    [self.delegate sessionDidEnd:session];
    
    __weak MPBackendController *weakSelf = self;
    NSNumber *sessionId = @(session.sessionId);
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf && sessionId) {
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidEndNotification
                                                                object:strongSelf.delegate
                                                              userInfo:@{mParticleSessionId:sessionId}];
        }
    });
}

- (void)cleanUp {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (nextCleanUpTime < currentTime) {
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence deleteRecordsOlderThan:(currentTime - NINETY_DAYS)];
        nextCleanUpTime = currentTime + TWENTY_FOUR_HOURS;
    }
}
                   
- (void)logUserAttributeChange:(MPUserAttributeChange *)userAttributeChange {
    if (!userAttributeChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:static_cast<MPMessageType>(mParticle::MessageType::UserAttributeChange)
                                                                           session:self.session
                                                               userAttributeChange:userAttributeChange];
    if (userAttributeChange.timestamp) {
        [messageBuilder withTimestamp:[userAttributeChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
}

- (void)logUserIdentityChange:(MPUserIdentityChange *)userIdentityChange {
    if (!userIdentityChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:static_cast<MPMessageType>(mParticle::MessageType::UserIdentityChange)
                                                                           session:self.session
                                                                userIdentityChange:userIdentityChange];
    if (userIdentityChange.timestamp) {
        [messageBuilder withTimestamp:[userIdentityChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
}

- (NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSNumber *previousSessionSuccessfullyClosed = nil;
    if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        NSDictionary *previousSessionStateDictionary = [NSDictionary dictionaryWithContentsOfFile:previousSessionStateFile];
        previousSessionSuccessfullyClosed = previousSessionStateDictionary[kMPASTPreviousSessionSuccessfullyClosedKey];
    }
    
    if (previousSessionSuccessfullyClosed == nil) {
        previousSessionSuccessfullyClosed = @YES;
    }
    
    return previousSessionSuccessfullyClosed;
}

- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSDictionary *previousSessionStateDictionary = @{kMPASTPreviousSessionSuccessfullyClosedKey:previousSessionSuccessfullyClosed};
    
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        [fileManager removeItemAtPath:previousSessionStateFile error:nil];
    }
    
    [previousSessionStateDictionary writeToFile:previousSessionStateFile atomically:YES];
}

- (void)processDidFinishLaunching:(NSNotification *)notification {
    NSString *astType = kMPASTInitKey;
    NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (stateMachine.installationType == MPInstallationTypeKnownInstall) {
        messageInfo[kMPASTIsFirstRunKey] = @YES;
        [self.delegate forwardLogInstall];
    } else if (stateMachine.installationType == MPInstallationTypeKnownUpgrade) {
        messageInfo[kMPASTIsUpgradeKey] = @YES;
        [self.delegate forwardLogUpdate];
    }
    
    messageInfo[kMPASTPreviousSessionSuccessfullyClosedKey] = [self previousSessionSuccessfullyClosed];
    
    NSDictionary *userInfo = [notification userInfo];
    BOOL sessionFinalized = YES;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        NSUserActivity *userActivity = userInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey][@"UIApplicationLaunchOptionsUserActivityKey"];
        
        if (userActivity) {
            stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
        }
    }
    
#if TARGET_OS_IOS == 1
#if !defined(MPARTICLE_APP_EXTENSIONS)
    MParticleUserNotification *userNotification = nil;
    NSDictionary *pushNotificationDictionary = userInfo[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (pushNotificationDictionary) {
        NSError *error = nil;
        NSData *remoteNotificationData = [NSJSONSerialization dataWithJSONObject:pushNotificationDictionary options:0 error:&error];
        
        int64_t launchNotificationHash = 0;
        if (!error && remoteNotificationData.length > 0) {
            launchNotificationHash = mParticle::Hasher::hashFNV1a(static_cast<const char *>([remoteNotificationData bytes]), static_cast<int>([remoteNotificationData length]));
        }
        
        if (launchNotificationHash != 0 && [MPNotificationController launchNotificationHash] != 0 && launchNotificationHash != [MPNotificationController launchNotificationHash]) {
            astType = kMPASTForegroundKey;
            userNotification = [self.notificationController newUserNotificationWithDictionary:pushNotificationDictionary
                                                                             actionIdentifier:nil
                                                                                        state:kMPPushNotificationStateNotRunning];
            
            if (userNotification.redactedUserNotificationString) {
                messageInfo[kMPPushMessagePayloadKey] = userNotification.redactedUserNotificationString;
            }
            
            if (_session) {
                NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval backgroundedTime = (currentTime - _session.endTime) > 0 ? (currentTime - _session.endTime) : 0;
                sessionFinalized = backgroundedTime > self.sessionTimeout;
            }
        }
    }
    
    if (userNotification) {
        [self receivedUserNotification:userNotification];
    }
#endif
#endif
    
    messageInfo[kMPAppStateTransitionType] = astType;
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    messageBuilder = [messageBuilder withStateTransition:sessionFinalized previousSession:nil];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    [MPApplication updateStoredVersionAndBuildNumbers];

    didFinishLaunchingNotification = nil;
    
    MPILogVerbose(@"Application Did Finish Launching");
}

- (void)processOpenSessionsEndingCurrent:(BOOL)endCurrentSession completionHandler:(void (^)(BOOL success))completionHandler {
    [self endUploadTimer];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    NSMutableArray<MPSession *> *sessions = [persistence fetchSessions];
    if (endCurrentSession) {
        [persistence updateSession:self.session];
        self->_session = nil;
        if (self.eventSet.count == 0) {
            self.eventSet = nil;
        }
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %ld", self.session.sessionId];
        MPSession *currentSession = [[sessions filteredArrayUsingPredicate:predicate] lastObject];
        [sessions removeObject:currentSession];
    }
    
    for (MPSession *openSession in sessions) {
        [self broadcastSessionDidEnd:openSession];
    }
    
    [self uploadOpenSessions:sessions completionHandler:completionHandler];
}

- (void)processPendingArchivedMessages {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *crashLogsDirectoryPath = CRASH_LOGS_DIRECTORY_PATH;
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    NSArray *directoryPaths = @[crashLogsDirectoryPath, archivedMessagesDirectoryPath];
    NSArray *fileExtensions = @[@".log", @".arcmsg"];
    
    [directoryPaths enumerateObjectsUsingBlock:^(NSString *directoryPath, NSUInteger idx, BOOL *stop) {
        if (![fileManager fileExistsAtPath:directoryPath]) {
            return;
        }
        
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'", fileExtensions[idx]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        for (NSString *fileName in directoryContents) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            MPMessage *message = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            
            if (message) {
                [self saveMessage:message updateSession:NO];
            }
            
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }];
}

- (void)processPendingUploads {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    __weak MPBackendController *weakSelf = self;
    
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    if (!uploads) {
        return;
    }
    
    if ([MPStateMachine sharedInstance].dataRamped) {
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        return;
    }
    
    __strong MPBackendController *strongSelf = weakSelf;
    [strongSelf.networkCommunication upload:uploads
                                      index:0
                          completionHandler:^(BOOL success, MPUpload *upload, NSDictionary *responseDictionary, BOOL finished) {
                              if (!success) {
                                  return;
                              }
                              
                              [persistence deleteUpload:upload];
                              
                          }];
}

- (void)proxyOriginalAppDelegate NS_EXTENSION_UNAVAILABLE_IOS("")
 {
    if (originalAppDelegateProxied) {
        return;
    }
    
    originalAppDelegateProxied = YES;
    
    UIApplication *application = [UIApplication sharedApplication];
    appDelegateProxy = [[MPAppDelegateProxy alloc] initWithOriginalAppDelegate:application.delegate];
    application.delegate = appDelegateProxy;
}

- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler {
    if (self.networkCommunication.inUse) {
        return;
    }
        
    [self.networkCommunication requestConfig:^(BOOL success, NSDictionary * _Nullable configurationDictionary, NSString * _Nullable eTag) {
        if (success) {
            if (eTag && configurationDictionary) {
                MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configurationDictionary];
                [MPResponseConfig save:responseConfig eTag: eTag];
            }
            
            if ([[MPStateMachine sharedInstance].minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
                MPILogDebug(@"Throttling batches");
                
                if (completionHandler) {
                    completionHandler(NO);
                }
            } else if (completionHandler) {
                completionHandler(YES);
            }
        } else {
            if (completionHandler) {
                completionHandler(NO);
            }
        }
    }];
}

- (void)setUserAttributeChange:(MPUserAttributeChange *)userAttributeChange completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    
    if ([MPStateMachine sharedInstance].optOut) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusOptOut);
        }
        
        return;
    }
    
    if (userAttributeChange.value && ![userAttributeChange.value isKindOfClass:[NSString class]] && ![userAttributeChange.value isKindOfClass:[NSNumber class]] && ![userAttributeChange.value isKindOfClass:[NSArray class]]) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceController mpId]];
    id<NSObject> userAttributeValue = nil;
    NSString *localKey = [userAttributes caseInsensitiveKey:userAttributeChange.key];
    
    if (!userAttributeChange.value && !userAttributes[localKey]) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSuccess);
        }
        
        return;
    }
    
    NSError *error = nil;
    NSUInteger maxValueLength = userAttributeChange.isArray ? MAX_USER_ATTR_LIST_ENTRY_LENGTH : LIMIT_USER_ATTR_LENGTH;
    BOOL validAttributes = [self checkAttribute:userAttributeChange.userAttributes key:localKey value:userAttributeChange.value maxValueLength:maxValueLength error:&error];
    
    if (userAttributeChange.isArray) {
        userAttributeValue = userAttributeChange.value;
        userAttributeChange.deleted = error.code == kInvalidValue && userAttributes[localKey];
    } else {
        if (!validAttributes && error.code == kInvalidValue) {
            userAttributeValue = [NSNull null];
            validAttributes = YES;
            error = nil;
        } else {
            userAttributeValue = userAttributeChange.value;
        }
        
        userAttributeChange.deleted = error.code == kEmptyValueAttribute && userAttributes[localKey];
    }
    
    if (validAttributes) {
        userAttributes[localKey] = userAttributeValue;
    } else if (userAttributeChange.deleted) {
        [userAttributes removeObjectForKey:localKey];
        
        if (!deletedUserAttributes) {
            deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
        }
        [deletedUserAttributes addObject:userAttributeChange.key];
    } else {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    NSMutableDictionary *userAttributesCopy = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
    NSString *aKey;
    
    while ((aKey = [attributeEnumerator nextObject])) {
        if ((NSNull *)userAttributes[aKey] == [NSNull null]) {
            userAttributesCopy[aKey] = kMPNullUserAttributeString;
        } else {
            userAttributesCopy[aKey] = userAttributes[aKey];
        }
    }
    
    if (userAttributeChange.changed) {
        userAttributeChange.valueToLog = userAttributeValue;
        [self logUserAttributeChange:userAttributeChange];
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
    
    if (completionHandler) {
        completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSuccess);
    }
}

- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler {
    const void (^completionHandlerCopy)(BOOL) = [completionHandler copy];
    __weak MPBackendController *weakSelf = self;
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    //Fetch all stored messages (1)
    NSDictionary *mpidMessages = [persistence fetchMessagesForUploading];
    if (!mpidMessages || mpidMessages.count == 0) {
        completionHandlerCopy(YES);
        return;
    }
    [mpidMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull mpid, NSMutableDictionary *  _Nonnull sessionMessages, BOOL * _Nonnull stop) {
        [sessionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull sessionId, NSArray *  _Nonnull messages, BOOL * _Nonnull stop) {
            //In batches broken up by mpid and then sessionID create the Uploads (2)
            __strong MPBackendController *strongSelf = weakSelf;
            NSNumber *nullableSessionID = (sessionId.integerValue == -1) ? nil : sessionId;
            MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid: mpid sessionId:nullableSessionID messages:messages sessionTimeout:strongSelf.sessionTimeout uploadInterval:strongSelf.uploadInterval];
            
            if (!uploadBuilder || !strongSelf) {
                self->sessionBeingUploaded = nil;
                completionHandlerCopy(YES);
                return;
            }
            
            [uploadBuilder withUserAttributes:[strongSelf userAttributesForUserId:mpid] deletedUserAttributes:self->deletedUserAttributes];
            [uploadBuilder withUserIdentities:[strongSelf userIdentitiesForUserId:mpid]];
            [uploadBuilder build:^(MPUpload *upload) {
                //Save the Upload to the Database (3)
                [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
                
                //Delete all messages associated with this batch (4)
                [persistence deleteMessages:messages];
                
            }];
            
            self->deletedUserAttributes = nil;
        }];
    }];
    
    //Fetch all sessions and delete them if inactive (5)
    [persistence deleteAllSessionsExcept:[MPStateMachine sharedInstance].currentSession];
    
    // Fetch all Uploads (6)
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    if (!uploads) {
        sessionBeingUploaded = nil;
        completionHandlerCopy(YES);
        return;
    }
    
    if ([MPStateMachine sharedInstance].dataRamped) {
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        [persistence deleteNetworkPerformanceMessages];
        return;
    }
    
    //Send all Uploads to the backend (7)
    __strong MPBackendController *strongSelf = weakSelf;
    [strongSelf.networkCommunication upload:uploads index:0 completionHandler:^(BOOL success, MPUpload *upload, NSDictionary *responseDictionary, BOOL finished) {
        if (!success) {
            completionHandlerCopy(success);
            return;
        }
        
        [MPResponseEvents parseConfiguration:responseDictionary];
        
        //Delete the Upload from the local database on success (8)
        [persistence deleteUpload:upload];
        
        if (!finished) {
            return;
        }
        
        self->sessionBeingUploaded = nil;
        completionHandlerCopy(success);
    }];
}

- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(BOOL success))completionHandler {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    void (^invokeCompletionHandler)(BOOL) = ^(BOOL success) {
        if ([NSThread isMainThread]) {
            completionHandler(success);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success);
            });
        }
    };
    
    if (!openSessions || openSessions.count == 0) {
        invokeCompletionHandler(YES);
        return;
    }
    
    __block MPSession *session = [openSessions[0] copy];
    [openSessions removeObjectAtIndex:0];
    NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(session.foregroundTime),
                                          kMPSessionTotalLengthKey:MPMilliseconds(session.length)}
                                        mutableCopy];
    
    NSDictionary *sessionAttributesDictionary = [session.attributesDictionary transformValuesToString];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:session.endTime] build];
        
        [self saveMessage:message updateSession:NO];
        MPILogVerbose(@"Session Ended: %@", session.uuid);
    }
    
    __weak MPBackendController *weakSelf = self;
    
    [self requestConfig:^(BOOL uploadBatch) {
        if (!uploadBatch) {
            invokeCompletionHandler(NO);
            return;
        }
        
        __strong MPBackendController *strongSelf = weakSelf;
        
        [strongSelf uploadBatchesWithCompletionHandler:^(BOOL success) {
            session = nil;

            invokeCompletionHandler(success);
        }];
   
    }];
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (appBackgrounded || [MPStateMachine runningInBackground]) {
        return;
    }
    
    MPILogVerbose(@"Application Did Enter Background");
    
    appBackgrounded = YES;
    [MPStateMachine setRunningInBackground:YES];
    
    timeAppWentToBackground = [[NSDate date] timeIntervalSince1970];
    
#if !defined(MPARTICLE_APP_EXTENSIONS)
    [self beginBackgroundTask];
    
    if (MParticle.sharedInstance.automaticSessionTracking) {
        [self beginBackgroundTimer];
    }
#endif
    
    [self endUploadTimer];
    
    dispatch_async(messageQueue, ^{
        
        [self setPreviousSessionSuccessfullyClosed:@YES];
        [self cleanUp];
        
        NSMutableDictionary *messageInfo = [@{kMPAppStateTransitionType:kMPASTBackgroundKey} mutableCopy];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        if ([MPLocationManager trackingLocation] && ![MPStateMachine sharedInstance].locationManager.backgroundLocationTracking) {
            [[MPStateMachine sharedInstance].locationManager.locationManager stopUpdatingLocation];
        }
        
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        MPMessage *message = (MPMessage *)[messageBuilder build];
        
        [self.session suspendSession];
        [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
        
#if !defined(MPARTICLE_APP_EXTENSIONS)
        [self uploadDatabaseWithCompletionHandler:^{
            if (!MParticle.sharedInstance.automaticSessionTracking) {
                [self endBackgroundTask];
            }
        }];
#else
        [self endSession];
#endif
    });
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    backgroundStartTime = 0;
    
    [self endBackgroundTimer];
    
    appBackgrounded = NO;
    [MPStateMachine setRunningInBackground:NO];
    resignedActive = NO;
    
#if !defined(MPARTICLE_APP_EXTENSIONS)
    [self endBackgroundTask];
#endif
    
#if TARGET_OS_IOS == 1
    if ([MPLocationManager trackingLocation] && ![MPStateMachine sharedInstance].locationManager.backgroundLocationTracking) {
        [[MPStateMachine sharedInstance].locationManager.locationManager startUpdatingLocation];
    }
#endif
    
    dispatch_async(messageQueue, ^{
        [self requestConfig:nil];
    });
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    didFinishLaunchingNotification = [notification copy];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    dispatch_async(messageQueue, ^{
        
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        if (self->_session) {
            MPSession *sessionCopy = [self->_session copy];
            
            // App exit message
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:sessionCopy messageInfo:@{kMPAppStateTransitionType:kMPASTExitKey}];
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [persistence saveMessage:message];
            
            // Session end message
            sessionCopy.endTime = [[NSDate date] timeIntervalSince1970];
            
            NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(sessionCopy.foregroundTime),
                                                  kMPSessionTotalLengthKey:MPMilliseconds(sessionCopy.length),
                                                  kMPEventCounterKey:@(sessionCopy.eventCounter)}
                                                mutableCopy];
            
            NSDictionary *sessionAttributesDictionary = [sessionCopy.attributesDictionary transformValuesToString];
            if (sessionAttributesDictionary) {
                messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
            }
            
            messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:sessionCopy messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            message = (MPMessage *)[[messageBuilder withTimestamp:sessionCopy.endTime] build];
            [persistence saveMessage:message];
            
            // Generate the upload batch
            NSDictionary *mpidMessages = [persistence fetchMessagesForUploading];
            if (mpidMessages) {
                [mpidMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull mpid, NSMutableDictionary *  _Nonnull sessionMessages, BOOL * _Nonnull stop) {
                    [sessionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull sessionId, NSArray *  _Nonnull messages, BOOL * _Nonnull stop) {
                        
                        NSNumber *nullableSessionID = (sessionId.integerValue == -1) ? nil : sessionId;
                        
                        MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:mpid
                                                                                      sessionId:nullableSessionID
                                                                                       messages:messages
                                                                                 sessionTimeout:self.sessionTimeout
                                                                                 uploadInterval:self.uploadInterval];
                        
                        [uploadBuilder withUserAttributes:[self userAttributesForUserId:mpid] deletedUserAttributes:self->deletedUserAttributes];
                        [uploadBuilder withUserIdentities:[self userIdentitiesForUserId:mpid]];
                        [uploadBuilder build: ^(MPUpload * _Nullable upload) {
                            [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
                        }];
                    }];
                }];
            }
            
            // Archive session
            MPSession *archivedSession = [persistence archiveSession:sessionCopy];
            if (archivedSession) {
                [persistence deleteSession:archivedSession];
            }
        }
        
        // Close the database
        if (persistence.databaseOpen) {
            [persistence closeDatabase];
        }
        
#if !defined(MPARTICLE_APP_EXTENSIONS)
        [self endBackgroundTask];
#endif
        
    });
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
    
}

- (void)handleNetworkPerformanceNotification:(NSNotification *)notification {
    if (!_session) {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    MPNetworkPerformance *networkPerformance = userInfo[kMPNetworkPerformanceKey];
    
    [self logNetworkPerformanceMeasurement:networkPerformance completionHandler:nil];
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    if (resignedActive) {
        resignedActive = NO;
        return;
    }
    
    dispatch_async(messageQueue, ^{
        BOOL sessionExpired = self->_session == nil;
        if (!sessionExpired) {
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            if (self->timeAppWentToBackground > 0) {
                self->_session.backgroundTime += currentTime - self->timeAppWentToBackground;
            }
            self->timeAppWentToBackground = 0.0;
            self->_session.endTime = currentTime;
            [[MPPersistenceController sharedInstance] updateSession:self->_session];
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:@{kMPAppStateTransitionType:kMPASTForegroundKey}];
        messageBuilder = [messageBuilder withStateTransition:sessionExpired previousSession:nil];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        MPMessage *message = (MPMessage *)[messageBuilder build];
        [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
        
        [self beginUploadTimer];
        MPILogVerbose(@"Application Did Become Active");
    });
}

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    resignedActive = YES;
}

#pragma mark Timers
- (void)beginBackgroundTimer NS_EXTENSION_UNAVAILABLE_IOS(""){
    __weak MPBackendController *weakSelf = self;
    
    backgroundSource = [self createSourceTimer:(MINIMUM_SESSION_TIMEOUT + 0.1)
                                  eventHandler:^{
                                      
                                      __block NSTimeInterval backgroundTimeRemaining;
                                      dispatch_sync(dispatch_get_main_queue(), ^{
                                          backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
                                      });
                                      
                                      __strong MPBackendController *strongSelf = weakSelf;
                                      if (!strongSelf) {
                                          return;
                                      }
                                      
                                      strongSelf->longSession = backgroundTimeRemaining > kMPRemainingBackgroundTimeMinimumThreshold;
                                      
                                      if (!strongSelf->longSession) {
                                          NSTimeInterval timeInBackground =  [[NSDate date] timeIntervalSince1970] - self->timeAppWentToBackground;
                                          if (timeInBackground >= strongSelf.sessionTimeout) {
                                              [strongSelf endBackgroundTimer];
                                              [[MPPersistenceController sharedInstance] updateSession:strongSelf.session];
                                              
                                              [strongSelf processOpenSessionsEndingCurrent:YES
                                                                         completionHandler:^(BOOL success) {
                                                                             [MPStateMachine setRunningInBackground:NO];
                                                                             
                                                                             MPILogDebug(@"SDK has ended background activity.");
                                                                             [strongSelf endBackgroundTask];
                                                                         }];
                                              
                                          }
                                      } else {
                                          self->backgroundStartTime = 0;
                                          
                                          if (!strongSelf->uploadSource) {
                                              [strongSelf beginUploadTimer];
                                          }
                                      }
                                  } cancelHandler:^{
                                      __strong MPBackendController *strongSelf = weakSelf;
                                      if (strongSelf) {
                                          strongSelf->backgroundSource = nil;
                                      }
                                  }];
}

- (void)beginUploadTimer {
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (strongSelf->uploadSource) {
            dispatch_source_cancel(strongSelf->uploadSource);
            strongSelf->uploadSource = nil;
        }
        
        strongSelf->uploadSource = [strongSelf createSourceTimer:strongSelf.uploadInterval
                                                    eventHandler:^{
                                                        [strongSelf uploadDatabaseWithCompletionHandler:nil];
                                                    } cancelHandler:^{
                                                        strongSelf->uploadSource = nil;
                                                    }];
    });
}

- (dispatch_source_t)createSourceTimer:(uint64_t)interval eventHandler:(dispatch_block_t)eventHandler cancelHandler:(dispatch_block_t)cancelHandler {
    dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, messageQueue);
    
    if (sourceTimer) {
        dispatch_source_set_timer(sourceTimer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(sourceTimer, eventHandler);
        dispatch_source_set_cancel_handler(sourceTimer, cancelHandler);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), messageQueue, ^{
            dispatch_resume(sourceTimer);
        });
    }
    
    return sourceTimer;
}

- (void)endBackgroundTimer {
    if (backgroundSource) {
        dispatch_source_cancel(backgroundSource);
    }
}

- (void)endUploadTimer {
    if (uploadSource) {
        dispatch_source_cancel(uploadSource);
    }
}

#pragma mark Public accessors
- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    if (sessionTimeout == _sessionTimeout) {
        return;
    }
    
    _sessionTimeout = MIN(MAX(sessionTimeout, MINIMUM_SESSION_TIMEOUT), MAXIMUM_SESSION_TIMEOUT);
}

- (NSTimeInterval)uploadInterval {
    if (_uploadInterval == 0.0) {
        _uploadInterval = [MPStateMachine environment] == MPEnvironmentDevelopment ? DEFAULT_DEBUG_UPLOAD_INTERVAL : DEFAULT_UPLOAD_INTERVAL;
    }
    
    // If running in an extension our processor time is extremely limited
    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]) {
        _uploadInterval = 1.0;
    }
    return _uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    if (uploadInterval == _uploadInterval) {
        return;
    }
    
    _uploadInterval = MAX(uploadInterval, 1.0);
    
#if TARGET_OS_TV == 1
    _uploadInterval = MIN(_uploadInterval, DEFAULT_UPLOAD_INTERVAL);
#endif
    
    if (uploadSource) {
        [self beginUploadTimer];
    }
}

#pragma mark Public methods
- (void)beginSession:(void (^)(MPSession *session, MPSession *previousSession, MPExecStatus execStatus))completionHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        if (completionHandler) {
            completionHandler(nil, nil, MPExecStatusOptOut);
        }
        
        return;
    }
    
    if (_session) {
        [self endSession];
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    self.session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    [persistence saveSession:_session];
    
    MPSession *previousSession = [persistence fetchPreviousSession];
    NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSInteger previousSessionLength = 0;
    if (previousSession) {
        previousSessionLength = trunc(previousSession.length);
        messageInfo[kMPPreviousSessionIdKey] = previousSession.uuid;
        messageInfo[kMPPreviousSessionStartKey] = MPMilliseconds(previousSession.startTime);
    }
    
    messageInfo[kMPPreviousSessionLengthKey] = @(previousSessionLength);
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionStart session:_session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:stateMachine.location];
#endif
    MPMessage *message = (MPMessage *)[[messageBuilder withTimestamp:_session.startTime] build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    if (completionHandler) {
        completionHandler(self->_session, previousSession, MPExecStatusSuccess);
    }
    
    stateMachine.currentSession = _session;
    
    [self broadcastSessionDidBegin:self->_session];
    
    MPILogVerbose(@"New Session Has Begun: %@", _session.uuid);
}

- (void)endSession {
    if (_session == nil || [MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    _session.endTime = [[NSDate date] timeIntervalSince1970];
    
    MPSession *sessionToEnd = [_session copy];
    NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(sessionToEnd.foregroundTime),
                                          kMPSessionTotalLengthKey:MPMilliseconds(sessionToEnd.length),
                                          kMPEventCounterKey:@(sessionToEnd.eventCounter)}
                                        mutableCopy];
    
    NSDictionary *sessionAttributesDictionary = [sessionToEnd.attributesDictionary transformValuesToString];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    MPMessage *message = [persistence fetchSessionEndMessageInSession:sessionToEnd];
    
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:sessionToEnd messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:sessionToEnd.endTime] build];
        
        [self saveMessage:message updateSession:NO];
    }
    
    [persistence archiveSession:sessionToEnd];
    [self broadcastSessionDidEnd:sessionToEnd];
    _session = nil;
    
    MPILogVerbose(@"Session Ended: %@", sessionToEnd.uuid);
}

- (void)beginTimedEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [event beginTiming];
    [self.eventSet addObject:event];
    completionHandler(event, MPExecStatusSuccess);
}

- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error {
    return [self checkAttribute:attributesDictionary key:key value:value maxValueLength:LIMIT_ATTR_LENGTH error:error];
}

- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error {
    static NSString *attributeValidationErrorDomain = @"Attribute Validation";
    NSString *errorMessage = nil;
    Class NSStringClass = [NSString class];
    
    if (!value) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'value' parameter is invalid.";
    }
    
    if ([value isKindOfClass:NSStringClass]) {
        if ([value isEqualToString:@""]) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kEmptyValueAttribute userInfo:nil];
            }
            
            errorMessage = @"The 'value' parameter is an empty string.";
        }
        
        if (((NSString *)value).length > maxValueLength) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = [NSString stringWithFormat:@"The parameter: %@ is longer than the maximum allowed.", value];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *values = (NSArray *)value;
        if (values.count > MAX_USER_ATTR_LIST_SIZE) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = @"The 'values' parameter contains more entries than the maximum allowed.";
        }

        if (!errorMessage) {
            for (id entryValue in values) {
                if (![entryValue isKindOfClass:NSStringClass]) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidDataType userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"All user attribute entries in the array must be of type string. Error entry: %@", entryValue];
                    
                    break;
                } else if (((NSString *)entryValue).length > maxValueLength) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"The values entry: %@ is longer than the maximum allowed.", entryValue];
                    
                    break;
                }
            }
        }
    }
    
    if (attributesDictionary.count >= LIMIT_ATTR_COUNT) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededNumberOfAttributesLimit userInfo:nil];
        }
        
        errorMessage = @"There are more attributes than the maximum number allowed.";
    }

    if (MPIsNull(key)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter cannot be nil.";
    } else if (key.length > LIMIT_NAME) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededKeyMaximumLength userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter is longer than the maximum allowed length.";
    }

    if (errorMessage == nil) {
        return YES;
    } else {
        MPILogError(@"%@", errorMessage);
        return NO;
    }
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (MPExecStatus)fetchSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(void (^)(NSArray *segments, NSTimeInterval elapsedTime, NSError *error))completionHandler {

    if (self.networkCommunication.retrievingSegments) {
        return MPExecStatusDataBeingFetched;
    }
    
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    
    NSArray *(^validSegments)(NSArray *segments) = ^(NSArray *segments) {
        NSMutableArray *validSegments = [[NSMutableArray alloc] initWithCapacity:segments.count];
        
        for (MPSegment *segment in segments) {
            if (!segment.expired && (endpointId == nil || [segment.endpointIds containsObject:endpointId])) {
                [validSegments addObject:segment];
            }
        }
        
        if (validSegments.count == 0) {
            validSegments = nil;
        }
        
        return [validSegments copy];
    };
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.networkCommunication requestSegmentsWithTimeout:timeout
                                        completionHandler:^(BOOL success, NSArray *segments, NSTimeInterval elapsedTime, NSError *error) {
                                            if (!error) {
                                                if (success && segments.count > 0) {
                                                    [persistence deleteSegments];
                                                }
                                                
                                                for (MPSegment *segment in segments) {
                                                    [persistence saveSegment:segment];
                                                }
                                                
                                                completionHandler(validSegments(segments), elapsedTime, error);
                                            } else {
                                                MPNetworkError networkError = (MPNetworkError)error.code;
                                                
                                                switch (networkError) {
                                                    case MPNetworkErrorTimeout: {
                                                        NSArray *persistedSegments = [persistence fetchSegments];
                                                        completionHandler(validSegments(persistedSegments), timeout, nil);
                                                    }
                                                        break;
                                                        
                                                    case MPNetworkErrorDelayedSegments:
                                                        if (success && segments.count > 0) {
                                                            [persistence deleteSegments];
                                                        }
                                                        
                                                        for (MPSegment *segment in segments) {
                                                            [persistence saveSegment:segment];
                                                        }
                                                        break;
                                                }
                                            }
                                        }];
    
    return MPExecStatusSuccess;
}

- (NSString *)execStatusDescription:(MPExecStatus)execStatus {
    if (execStatus >= execStatusDescriptions.count) {
        return nil;
    }
    
    NSString *description = execStatusDescriptions[execStatus];
    return description;
}

- (NSNumber *)incrementSessionAttribute:(MPSession *)session key:(NSString *)key byValue:(NSNumber *)value {
    if (!session) {
        return nil;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    id currentValue = session.attributesDictionary[localKey];
    if (!currentValue && [value isKindOfClass:[NSNumber class]]) {
        [self setSessionAttribute:session key:localKey value:value];
        return value;
    }

    if (![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    session.attributesDictionary[localKey] = newValue;
    
    dispatch_async(messageQueue, ^{
        [[MPPersistenceController sharedInstance] updateSession:session];
    });
    
    return (NSNumber *)newValue;
}

- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSNumber class]], @"'value' must be a number.");
    
    NSDate *timestamp = [NSDate date];
    NSString *localKey = [[self userAttributesForUserId:[MPPersistenceController mpId]] caseInsensitiveKey:key];
    if (!localKey) {
        [self setUserAttribute:key value:value timestamp:timestamp completionHandler:nil];
        return value;
    }
    
    id currentValue = [self userAttributesForUserId:[MPPersistenceController mpId]][localKey];
    if (currentValue && ![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    } else if (MPIsNull(currentValue)) {
        currentValue = @0;
    }
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceController mpId]];
    userAttributes[localKey] = newValue;
    
    NSMutableDictionary *userAttributesCopy = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
    NSString *aKey;
    
    while ((aKey = [attributeEnumerator nextObject])) {
        if ((NSNull *)userAttributes[aKey] == [NSNull null]) {
            userAttributesCopy[aKey] = kMPNullUserAttributeString;
        } else {
            userAttributesCopy[aKey] = userAttributes[aKey];
        }
    }
    

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
 
    return (NSNumber *)newValue;
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    
    event.messageType = MPMessageTypeBreadcrumb;
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [event breadcrumbDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;

    completionHandler(event, execStatus);
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {

    MPExecStatus execStatus = MPExecStatusFail;
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCommerceEvent session:self.session commerceEvent:commerceEvent];
    if (commerceEvent.timestamp) {
        [messageBuilder withTimestamp:[commerceEvent.timestamp timeIntervalSince1970]];
    }
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    [self.session incrementCounter];
    
    // Update cart
    NSArray *products = nil;
    if (commerceEvent.action == MPCommerceEventActionAddToCart) {
        products = [commerceEvent addedProducts];
        
        if (products) {
            [[MParticle sharedInstance].identity.currentUser.cart addProducts:products logEvent:NO updateProductList:YES];
            [commerceEvent resetLatestProducts];
        } else {
            MPILogWarning(@"Commerce event products were not added to the cart.");
        }
    } else if (commerceEvent.action == MPCommerceEventActionRemoveFromCart) {
        products = [commerceEvent removedProducts];
        
        if (products) {
            [[MParticle sharedInstance].identity.currentUser.cart removeProducts:products logEvent:NO updateProductList:YES];
            [commerceEvent resetLatestProducts];
        } else {
            MPILogWarning(@"Commerce event products were not removed from the cart.");
        }
    }
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(commerceEvent, execStatus);
}

- (void)logError:(NSString *)message exception:(NSException *)exception topmostContext:(id)topmostContext eventInfo:(NSDictionary *)eventInfo completionHandler:(void (^)(NSString *message, MPExecStatus execStatus))completionHandler {
    
    
    NSString *execMessage = exception ? exception.name : message;
    
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSMutableDictionary *messageInfo = [@{kMPCrashWasHandled:@"true",
                                          kMPCrashingSeverity:@"error"}
                                        mutableCopy];
    
    if (exception) {
        NSData *liveExceptionReportData = [MPExceptionHandler generateLiveExceptionReport];
        if (liveExceptionReportData) {
            messageInfo[kMPPLCrashReport] = [liveExceptionReportData base64EncodedStringWithOptions:0];
        }
        
        messageInfo[kMPErrorMessage] = exception.reason;
        messageInfo[kMPCrashingClass] = exception.name;
        
        NSArray *callStack = [exception callStackSymbols];
        if (callStack) {
            messageInfo[kMPStackTrace] = [callStack componentsJoinedByString:@"\n"];
        }
        
        NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [[MPPersistenceController sharedInstance] fetchBreadcrumbs];
        if (fetchedbreadcrumbs) {
            NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
            for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
                [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
            }
            
            NSString *messageTypeBreadcrumbKey = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding];
            messageInfo[messageTypeBreadcrumbKey] = breadcrumbs;
        }
    } else {
        messageInfo[kMPErrorMessage] = message;
    }
    
    if (topmostContext) {
        messageInfo[kMPTopmostContext] = [[topmostContext class] description];
    }
    
    if (eventInfo.count > 0) {
        messageInfo[kMPAttributesKey] = eventInfo;
    }
    
    NSDictionary *appImageInfo = [MPExceptionHandler appImageInfo];
    if (appImageInfo) {
        [messageInfo addEntriesFromDictionary:appImageInfo];
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *errorMessage = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:errorMessage updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    execStatus = MPExecStatusSuccess;
    
    
    completionHandler(execMessage, execStatus);
}

- (void)logEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    
    event.messageType = MPMessageTypeEvent;
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary<NSString *, id> *messageInfo = [event dictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(event, execStatus);
}

- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler {
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [networkPerformance dictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeNetworkPerformance session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    execStatus = MPExecStatusSuccess;
    
    if (completionHandler) {
        completionHandler(networkPerformance, execStatus);
    }
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    
    event.messageType = MPMessageTypeScreenView;

    MPExecStatus execStatus = MPExecStatusFail;

    [event endTiming];
    
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }
    
    NSDictionary *messageInfo = [event screenDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(event, execStatus);
}

- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^)(BOOL optOut, MPExecStatus execStatus))completionHandler {
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    
    [MPStateMachine sharedInstance].optOut = optOutStatus;
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeOptOut session:self.session messageInfo:@{kMPOptOutStatus:(optOutStatus ? @"true" : @"false")}];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
    
    if (optOutStatus) {
        [self endSession];
    }
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(optOutStatus, execStatus);
}

- (MPExecStatus)setSessionAttribute:(MPSession *)session key:(NSString *)key value:(id)value {
    NSAssert(session != nil, @"session cannot be nil.");
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]], @"'value' must be a string or number.");
    
    if (!session) {
        return MPExecStatusMissingParam;
    } else if (![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSNumber class]]) {
        return MPExecStatusInvalidDataType;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    NSError *error = nil;
    BOOL validAttributes = [self checkAttribute:session.attributesDictionary key:localKey value:value error:&error];
    if (!validAttributes || [session.attributesDictionary[localKey] isEqual:value]) {
        return MPExecStatusInvalidDataType;
    }
    
    session.attributesDictionary[localKey] = value;
    
    [[MPPersistenceController sharedInstance] updateSession:session];
    
    return MPExecStatusSuccess;
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate startKitsAsync:(BOOL)startKitsAsync completionHandler:(dispatch_block_t)completionHandler {
#if !defined(MPARTICLE_APP_EXTENSIONS)
    if (proxyAppDelegate) {
        [self proxyOriginalAppDelegate];
    }
#endif
    if (startKitsAsync) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MPKitContainer sharedInstance];
        });
    } else {
        [MPKitContainer sharedInstance];
    }
    
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = apiKey;
    stateMachine.secret = secret;
    stateMachine.installationType = installationType;
    [MPStateMachine setRunningInBackground:NO];
    
    __weak MPBackendController *weakSelf = self;
    dispatch_async(messageQueue, ^{
        [MPURLRequestBuilder tryToCaptureUserAgent];
        [MPPersistenceController sharedInstance];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeFirstRun session:self.session messageInfo:nil];
        
        __strong MPBackendController *strongSelf = weakSelf;
        
        [strongSelf processPendingUploads];
        [strongSelf processOpenSessionsEndingCurrent:NO completionHandler:^(BOOL success) {}];
        
        [strongSelf beginUploadTimer];
        
        if (firstRun) {
            MPMessage *message = (MPMessage *)[messageBuilder build];
            message.uploadStatus = MPUploadStatusBatch;
            
            [strongSelf saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
            
            MPILogDebug(@"Application First Run");
        }
        
        [stateMachine.searchAttribution requestAttributionDetailsWithBlock:^{
            [strongSelf processDidFinishLaunching:strongSelf->didFinishLaunchingNotification];
            [strongSelf uploadDatabaseWithCompletionHandler:nil];
        }];
        
        [strongSelf processPendingArchivedMessages];
        
        [MPResponseConfig restore];
        [self requestConfig:nil];
        MPILogDebug(@"SDK %@ has started", kMParticleSDKVersion);
        
        completionHandler();
    });
}

- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession {
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    MPMessageType messageTypeCode = (MPMessageType)mParticle::MessageTypeName::messageTypeForName(string([message.messageType UTF8String]));
    if (messageTypeCode == MPMessageTypeBreadcrumb) {
        [persistence saveBreadcrumb:message session:self.session];
    } else {
        [persistence saveMessage:message];
    }
    
    MPILogVerbose(@"Source Event Id: %@", message.uuid);
    
    if (updateSession) {
        if (messageTypeCode != MPMessageTypeSessionEnd && self.session.persisted) {
            self.session.endTime = [[NSDate date] timeIntervalSince1970];
            [persistence updateSession:self.session];
        } else {
            [persistence saveSession:self.session];
        }
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    BOOL shouldUpload = [stateMachine.triggerMessageTypes containsObject:message.messageType];
    
    if (!shouldUpload && stateMachine.triggerEventTypes) {
        NSError *error = nil;
        NSDictionary *messageDictionary = [message dictionaryRepresentation];
        NSString *eventName = messageDictionary[kMPEventNameKey];
        NSString *eventType = messageDictionary[kMPEventTypeKey];
        
        if (!error && eventName && eventType) {
            NSString *hashedEvent = [NSString stringWithCString:mParticle::Hasher::hashEvent([eventName cStringUsingEncoding:NSUTF8StringEncoding], [eventType cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                       encoding:NSUTF8StringEncoding];
            
            shouldUpload = [stateMachine.triggerEventTypes containsObject:hashedEvent];
        }
    }
    
    if (shouldUpload) {
        [self uploadDatabaseWithCompletionHandler:nil];
    }
}

- (MPExecStatus)uploadDatabaseWithCompletionHandler:(void (^ _Nullable)())completionHandler {
    __weak MPBackendController *weakSelf = self;

    [self requestConfig:^(BOOL uploadBatch) {
        __strong MPBackendController *strongSelf = weakSelf;

        BOOL shouldDelayUpload = [[MPKitContainer sharedInstance] shouldDelayUpload:kMPMaximumKitWaitTimeSeconds];
        if (!uploadBatch || shouldDelayUpload) {
            if (completionHandler) {
                completionHandler();
            }
        
            return;
        }

        [strongSelf uploadBatchesWithCompletionHandler:^(BOOL success) {
            if (completionHandler) {
                completionHandler();
            }
        }];
        
    }];
    
    return MPExecStatusSuccess;
}


- (void)setUserAttribute:(NSString *)key value:(id)value timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (!(([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) || [value isKindOfClass:[NSNumber class]])) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:value];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (!([values isKindOfClass:[NSArray class]] && values.count > 0)) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:values];
    userAttributeChange.isArray = YES;
    
    
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)removeUserAttribute:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, @"", MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:@""];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    
    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:identityType
                                                                                     value:identityString];
    
    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew
                                                                                      userIdentities:[self userIdentitiesForUserId:[MPPersistenceController mpId]]];
    
    userIdentityChange.timestamp = timestamp;
    
    NSNumber *identityTypeNumber = @(userIdentityChange.userIdentityNew.type);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", kMPUserIdentityTypeKey, identityTypeNumber];
    NSDictionary *userIdentity = [[[self userIdentitiesForUserId:[MPPersistenceController mpId]] filteredArrayUsingPredicate:predicate] lastObject];
    
    if (userIdentity &&
        [userIdentity[kMPUserIdentityIdKey] caseInsensitiveCompare:userIdentityChange.userIdentityNew.value] == NSOrderedSame &&
        ![userIdentity[kMPUserIdentityIdKey] isEqualToString:userIdentityChange.userIdentityNew.value])
    {
        return;
    }
    
    BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
        BOOL foundMatch = [currentIdentityType isEqualToNumber:identityTypeNumber];
        
        if (foundMatch) {
            *stop = YES;
        }
        
        return foundMatch;
    };
    
    NSMutableDictionary<NSString *, id> *identityDictionary;
    NSUInteger existingEntryIndex;
    BOOL persistUserIdentities = NO;
    
    NSMutableArray *userIdentities = [self userIdentitiesForUserId:[MPPersistenceController mpId]];
    
    if (userIdentityChange.userIdentityNew.value == nil || (NSNull *)userIdentityChange.userIdentityNew.value == [NSNull null] || [userIdentityChange.userIdentityNew.value isEqualToString:@""]) {
        existingEntryIndex = [userIdentities indexOfObjectPassingTest:objectTester];
        
        if (existingEntryIndex != NSNotFound) {
            identityDictionary = [userIdentities[existingEntryIndex] mutableCopy];
            userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:identityDictionary];
            userIdentityChange.userIdentityNew = nil;
            
            [userIdentities removeObjectAtIndex:existingEntryIndex];
            persistUserIdentities = YES;
        }
    } else {
        identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
        
        NSError *error = nil;
        if ([self checkAttribute:identityDictionary key:kMPUserIdentityIdKey value:userIdentityChange.userIdentityNew.value error:&error] &&
            [self checkAttribute:identityDictionary key:kMPUserIdentityTypeKey value:[identityTypeNumber stringValue] error:&error]) {
            
            existingEntryIndex = [userIdentities indexOfObjectPassingTest:objectTester];
            
            if (existingEntryIndex == NSNotFound) {
                userIdentityChange.userIdentityNew.dateFirstSet = [NSDate date];
                userIdentityChange.userIdentityNew.isFirstTimeSet = YES;
                
                identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
                
                [userIdentities addObject:identityDictionary];
            } else {
                userIdentity = userIdentities[existingEntryIndex];
                userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:userIdentity];
                
                NSNumber *timeIntervalMilliseconds = userIdentity[kMPDateUserIdentityWasFirstSet];
                userIdentityChange.userIdentityNew.dateFirstSet = timeIntervalMilliseconds != nil ? [NSDate dateWithTimeIntervalSince1970:([timeIntervalMilliseconds doubleValue] / 1000.0)] : [NSDate date];
                userIdentityChange.userIdentityNew.isFirstTimeSet = NO;
                
                identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
                
                [userIdentities replaceObjectAtIndex:existingEntryIndex withObject:identityDictionary];
            }
            
            persistUserIdentities = YES;
        }
    }
    
    if (persistUserIdentities) {
        if (userIdentityChange.changed) {
            [self logUserIdentityChange:userIdentityChange];
            
            MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
            [userDefaults setObject:userIdentities forKeyedSubscript:kMPUserIdentityArrayKey];
            [userDefaults synchronize];
        }
    }
    
    completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, MPExecStatusSuccess);
}

- (void)clearUserAttributes {
    [[MPIUserDefaults standardUserDefaults] removeMPObjectForKey:@"ua"];
    [[MPIUserDefaults standardUserDefaults] synchronize];
}

#if TARGET_OS_IOS == 1
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    
    if ([[MPStateMachine sharedInstance].locationTrackingMode isEqualToString:kMPRemoteConfigForceFalse]) {
        return MPExecStatusDisabledRemotely;
    }
    
    MPLocationManager *locationManager = [[MPLocationManager alloc] initWithAccuracy:accuracy distanceFilter:distance authorizationRequest:authorizationRequest];
    [MPStateMachine sharedInstance].locationManager = locationManager ? : nil;
    
    return MPExecStatusSuccess;
}

- (MPExecStatus)endLocationTracking {
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if ([stateMachine.locationTrackingMode isEqualToString:kMPRemoteConfigForceTrue]) {
        return MPExecStatusEnabledRemotely;
    }
    
    [stateMachine.locationManager endLocationTracking];
    stateMachine.locationManager = nil;
    
    return MPExecStatusSuccess;
}

- (MPNotificationController *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    [self willChangeValueForKey:@"notificationController"];
    _notificationController = [[MPNotificationController alloc] initWithDelegate:self];
    [self didChangeValueForKey:@"notificationController"];
    
    return _notificationController;
}

- (void)setNotificationController:(MPNotificationController *)notificationController {
    _notificationController = notificationController;
}

- (void)handleDeviceTokenNotification:(NSNotification *)notification {
    dispatch_async(messageQueue, ^{
        NSDictionary *userInfo = [notification userInfo];
        NSData *deviceToken = userInfo[kMPRemoteNotificationDeviceTokenKey];
        NSData *oldDeviceToken = userInfo[kMPRemoteNotificationOldDeviceTokenKey];
        
        if ((!deviceToken && !oldDeviceToken) || [deviceToken isEqualToData:oldDeviceToken]) {
            return;
        }
        
        NSData *logDeviceToken;
        NSString *status;
        BOOL pushNotificationsEnabled = deviceToken != nil;
        if (pushNotificationsEnabled) {
            logDeviceToken = deviceToken;
            status = @"true";
        } else if (!pushNotificationsEnabled && oldDeviceToken) {
            logDeviceToken = oldDeviceToken;
            status = @"false";
        }
        
        NSMutableDictionary *messageInfo = [@{kMPDeviceTokenKey:[NSString stringWithFormat:@"%@", logDeviceToken],
                                              kMPPushStatusKey:status}
                                            mutableCopy];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#if !defined(MPARTICLE_APP_EXTENSIONS)
        UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        NSUInteger notificationTypes = userNotificationSettings.types;
#pragma clang diagnostic pop
        messageInfo[kMPDeviceSupportedPushNotificationTypesKey] = @(notificationTypes);
#endif
        
        if ([MPStateMachine sharedInstance].deviceTokenType.length > 0) {
            messageInfo[kMPDeviceTokenTypeKey] = [MPStateMachine sharedInstance].deviceTokenType;
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushRegistration session:self.session messageInfo:messageInfo];
        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:MParticle.sharedInstance.automaticSessionTracking];
        
        if (deviceToken) {
            MPILogDebug(@"Set Device Token: %@", deviceToken);
        } else {
            MPILogDebug(@"Reset Device Token: %@", oldDeviceToken);
        }
    });
}

#pragma mark MPNotificationControllerDelegate
- (void)receivedUserNotification:(MParticleUserNotification *)userNotification {
    NSMutableDictionary *messageInfo = [@{kMPDeviceTokenKey:[NSString stringWithFormat:@"%@", [MPNotificationController deviceToken]],
                                          kMPPushNotificationStateKey:userNotification.state,
                                          kMPPushMessageProviderKey:kMPPushMessageProviderValue,
                                          kMPPushMessageTypeKey:userNotification.type}
                                        mutableCopy];
    
    if (userNotification.redactedUserNotificationString) {
        messageInfo[kMPPushMessagePayloadKey] = userNotification.redactedUserNotificationString;
    }
    
    if (userNotification.actionIdentifier) {
        messageInfo[kMPPushNotificationActionIdentifierKey] = userNotification.actionIdentifier;
        messageInfo[kMPPushNotificationCategoryIdentifierKey] = userNotification.categoryIdentifier;
    }
    
    if (userNotification.actionTitle) {
        messageInfo[kMPPushNotificationActionTileKey] = userNotification.actionTitle;
    }
    
    if (userNotification.behavior > 0) {
        messageInfo[kMPPushNotificationBehaviorKey] = @(userNotification.behavior);
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:_session messageInfo:messageInfo];
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:(_session != nil)];
}
#endif

@end
