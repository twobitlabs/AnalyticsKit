#import "mParticle.h"
#import "MPAppNotificationHandler.h"
#import "MPBackendController.h"
#import "MPConsumerInfo.h"
#import "MPDevice.h"
#import "MPEvent+MessageType.h"
#import "MPForwardQueueParameters.h"
#import "MPForwardRecord.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPIntegrationAttributes.h"
#import "MPKitActivity.h"
#import "MPKitContainer.h"
#import "MPKitFilter.h"
#import "MPKitInstanceValidator.h"
#import "MPNetworkPerformance.h"
#import "MPNotificationController.h"
#import "MPPersistenceController.h"
#import "MPSegment.h"
#import "MPSession.h"
#import "MPStateMachine.h"
#import "MPUserSegments+Setters.h"
#import "MPIUserDefaults.h"
#import "MPConvertJS.h"
#import "MPIdentityApi.h"
#import "MPEvent+Internal.h"

#if TARGET_OS_IOS == 1
    #import "MPLocationManager.h"

    #if defined(MP_CRASH_REPORTER)
        #import "MPExceptionHandler.h"
    #endif
#endif

static dispatch_queue_t messageQueue = nil;
static NSArray *eventTypeStrings = nil;

NSString *const kMPEventNameLogTransaction = @"Purchase";
NSString *const kMPEventNameLTVIncrease = @"Increase LTV";
NSString *const kMParticleFirstRun = @"firstrun";
NSString *const kMPMethodName = @"$MethodName";
NSString *const kMPStateKey = @"state";

@interface MPIdentityApi ()
- (void)identifyNoDispatch:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion;
@end

@interface MPKitContainer ()
- (BOOL)kitsInitialized;
@end

@interface MParticle() <MPBackendControllerDelegate> {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    MPExceptionHandler *exceptionHandler;
#endif
    NSNumber *privateOptOut;
    BOOL isLoggingUncaughtExceptions;
    BOOL sdkInitialized;
}

@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
@property (nonatomic, strong, nullable) NSMutableDictionary *configSettings;
@property (nonatomic, strong, nullable) MPKitActivity *kitActivity;
@property (nonatomic, unsafe_unretained) BOOL initialized;
@property (nonatomic, strong, nonnull) NSMutableArray *kitsInitializedBlocks;


@end

@interface MPAttributionResult ()

@property (nonatomic, readwrite) NSNumber *kitCode;
@property (nonatomic, readwrite) NSString *kitName;

@end

@implementation MPAttributionResult

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPAttributionResult {\n"];
    [description appendFormat:@"  kitCode: %@\n", _kitCode];
    [description appendFormat:@"  kitName: %@\n", _kitName];
    [description appendFormat:@"  linkInfo: %@\n", _linkInfo];
    [description appendString:@"}"];
    return description;
}

@end

@interface MParticleOptions () {
    MPILogLevel _logLevel;
    NSTimeInterval _uploadInterval;
}
@property (nonatomic, assign, readwrite) BOOL isLogLevelSet;
@property (nonatomic, assign, readwrite) BOOL isUploadIntervalSet;
@end

@implementation MParticleOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _proxyAppDelegate = YES;
        _collectUserAgent = YES;
        _automaticSessionTracking = YES;
        _startKitsAsync = NO;
        _logLevel = MPILogLevelNone;
        _isLogLevelSet = NO;
        _isUploadIntervalSet = NO;
    }
    return self;
}

+ (id)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret {
    MParticleOptions *options = [[self alloc] init];
    options.apiKey = apiKey;
    options.apiSecret = secret;
    return options;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    _logLevel = logLevel;
    _isLogLevelSet = YES;
}

- (MPILogLevel)logLevel {
    return _logLevel;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    _uploadInterval = uploadInterval;
    _isUploadIntervalSet = YES;
}

- (NSTimeInterval)uploadInterval {
    return _uploadInterval;
}

@end

@interface MPBackendController ()

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId;

@end

#pragma mark - MParticle
@implementation MParticle

@synthesize commerce = _commerce;
@synthesize identity = _identity;
@synthesize optOut = _optOut;

+ (void)initialize {
    eventTypeStrings = @[@"Reserved - Not Used", @"Navigation", @"Location", @"Search", @"Transaction", @"UserContent", @"UserPreference", @"Social", @"Other"];
}

+ (dispatch_queue_t)messageQueue {
    return messageQueue;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    messageQueue = dispatch_queue_create("com.mparticle.messageQueue", DISPATCH_QUEUE_SERIAL);
    sdkInitialized = NO;
    privateOptOut = nil;
    isLoggingUncaughtExceptions = NO;
    _initialized = NO;
    _kitActivity = [[MPKitActivity alloc] init];
    _kitsInitializedBlocks = [NSMutableArray array];
    _automaticSessionTracking = YES;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // OS Notifications
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleMemoryWarningNotification:)
                               name:UIApplicationDidReceiveMemoryWarningNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
#endif
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

#pragma mark Private accessors
- (MPBackendController *)backendController {
    return _backendController;
}

- (NSMutableDictionary *)configSettings {
    if (_configSettings) {
        return _configSettings;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:kMPConfigPlist ofType:@"plist"];
    if (path) {
        _configSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    
    return _configSettings;
}

#pragma mark KVOs
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"backendController.session"]) {

        MPSession *session = change[NSKeyValueChangeNewKey];
        
        if (exceptionHandler) {
            exceptionHandler.session = session;
        } else {
            exceptionHandler = [[MPExceptionHandler alloc] initWithSession:session];
        }
        
        if (isLoggingUncaughtExceptions && ![MPExceptionHandler isHandlingExceptions]) {
            [exceptionHandler beginUncaughtExceptionLogging];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#endif

#pragma mark Notification handlers
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    dispatch_async([MParticle messageQueue], ^{
        NSDictionary *jailbrokenInfo = [MPDevice jailbrokenInfo];
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setKitAttribute:value:)
                                                  event:nil
                                            messageType:MPMessageTypeUnknown
                                               userInfo:nil
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit setKitAttribute:MPKitAttributeJailbrokenKey value:jailbrokenInfo];
                                             }];
    });
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
    self.configSettings = nil;
}

#pragma mark MPBackendControllerDelegate methods
- (void)sessionDidBegin:(MPSession *)session {
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(beginSession)
                                                  event:nil
                                            messageType:MPMessageTypeSessionStart
                                               userInfo:nil
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit beginSession];
                                             }];
    });
}

- (void)sessionDidEnd:(MPSession *)session {
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(endSession)
                                                  event:nil
                                            messageType:MPMessageTypeSessionEnd
                                               userInfo:nil
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit endSession];
                                             }];
    });
}

#pragma mark MPBackendControllerDelegate methods
- (void)forwardLogInstall {
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                  event:nil
                                            messageType:MPMessageTypeUnknown
                                               userInfo:nil
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit logInstall];
                                             }];
    });
}

- (void)forwardLogUpdate {
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                  event:nil
                                            messageType:MPMessageTypeUnknown
                                               userInfo:nil
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit logUpdate];
                                             }];
    });
}

#pragma mark - Public accessors and methods
- (MPIdentityApi *)identity {
    if (_identity) {
        return _identity;
    }
    
    _identity = [[MPIdentityApi alloc] init];
    return _identity;
}

- (MPCommerce *)commerce {
    if (_commerce) {
        return _commerce;
    }
    
    _commerce = [[MPCommerce alloc] init];
    return _commerce;
}

- (void)setDebugMode:(BOOL)debugMode {
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                  event:nil
                                            messageType:MPMessageTypeUnknown
                                               userInfo:@{kMPStateKey:@(debugMode)}
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit setDebugMode:debugMode];
                                             }];
    });
}

- (BOOL)consoleLogging {
    return [MPStateMachine sharedInstance].consoleLogging == MPConsoleLoggingDisplay;
}

- (void)setConsoleLogging:(BOOL)consoleLogging {
    if ([MPStateMachine environment] == MPEnvironmentDevelopment) {
        [MPStateMachine sharedInstance].consoleLogging = consoleLogging ? MPConsoleLoggingDisplay : MPConsoleLoggingSuppress;
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setDebugMode:)
                                                  event:nil
                                            messageType:MPMessageTypeUnknown
                                               userInfo:@{kMPStateKey:@(consoleLogging)}
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit setDebugMode:consoleLogging];
                                             }];
    });
}

- (MPEnvironment)environment {
    return [MPStateMachine environment];
}

- (MPILogLevel)logLevel {
    return [MPStateMachine sharedInstance].logLevel;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    dispatch_async(messageQueue, ^{
        [MPStateMachine sharedInstance].logLevel = logLevel;
    });
}

- (BOOL)optOut {
    return [MPStateMachine sharedInstance].optOut;
}

- (void)setOptOut:(BOOL)optOut {
    if (privateOptOut && _optOut == optOut) {
        return;
    }
    
    _optOut = optOut;
    privateOptOut = @(optOut);
    
    dispatch_async([MParticle messageQueue], ^{
        // Forwarding calls to kits
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setOptOut:)
                                                  event:nil
                                            messageType:MPMessageTypeOptOut
                                               userInfo:@{kMPStateKey:@(optOut)}
                                             kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                 *execStatus = [kit setOptOut:optOut];
                                             }];
        
        [self.backendController setOptOut:optOut
                        completionHandler:^(BOOL optOut, MPExecStatus execStatus) {

                            if (execStatus == MPExecStatusSuccess) {
                                MPILogDebug(@"Set Opt Out: %d", optOut);
                            }
                        }];
    });
}

- (NSTimeInterval)sessionTimeout {
    return self.backendController.sessionTimeout;
}

- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    self.backendController.sessionTimeout = sessionTimeout;
    MPILogDebug(@"Set Session Timeout: %.0f", sessionTimeout);
}

- (NSString *)uniqueIdentifier {
    return [MPStateMachine sharedInstance].consumerInfo.uniqueIdentifier;
}

- (NSTimeInterval)uploadInterval {
    return self.backendController.uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    self.backendController.uploadInterval = uploadInterval;
    
#if TARGET_OS_IOS == 1
    MPILogDebug(@"Set Upload Interval: %0.0f", uploadInterval);
#endif
}

- (NSDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    NSDictionary *userAttributes = [[self.backendController userAttributesForUserId:userId] copy];
    return userAttributes;
}

- (NSString *)version {
    return [kMParticleSDKVersion copy];
}

#pragma mark Initialization
+ (instancetype)sharedInstance {
    static MParticle *sharedInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [[MParticle alloc] init];
    });
    
    return sharedInstance;
}

- (void)start {
    NSString *apiKey = nil;
    NSString *secret = nil;

    if (!self.configSettings) {
        NSAssert(NO, @"mParticle SDK requires a valid MParticleConfig.plist with an apiKey and secret in order to use the no-args start method.");
        return;
    }

    apiKey = self.configSettings[kMPConfigApiKey];
    secret = self.configSettings[kMPConfigSecret];

    if (!apiKey || !secret) {
        NSAssert(NO, @"mParticle SDK requires a valid MParticleConfig.plist with an apiKey and secret in order to use the no-args start method.");
        return;
    }

    MParticleOptions *options = [[MParticleOptions alloc] init];
    options.apiKey = apiKey;
    options.apiSecret = secret;
    options.automaticSessionTracking = [self.configSettings[kMPConfigSharedGroupID] boolValue];
    options.customUserAgent = self.configSettings[kMPConfigCustomUserAgent];
    options.collectUserAgent = [self.configSettings[kMPConfigCollectUserAgent] boolValue];
    options.installType = MPInstallationTypeAutodetect;
    options.environment = MPEnvironmentAutoDetect;
    options.proxyAppDelegate = YES;
    [self startWithOptions:options];
}

- (void)startWithOptions:(MParticleOptions *)options {
    if (sdkInitialized) {
        return;
    }
    sdkInitialized=YES;
    
    _backendController = [[MPBackendController alloc] initWithDelegate:self];

#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
#endif

    if (options.isLogLevelSet) {
        self.logLevel = options.logLevel;
    }
    
    if (options.isUploadIntervalSet) {
        self.uploadInterval = options.uploadInterval;
    }
    
    NSString *apiKey = options.apiKey;
    NSString *secret = options.apiSecret;

    NSAssert(apiKey && secret, @"mParticle SDK must be started with an apiKey and secret.");
    NSAssert([apiKey isKindOfClass:[NSString class]] && [secret isKindOfClass:[NSString class]], @"mParticle SDK apiKey and secret must be of type string.");
    NSAssert(apiKey.length > 0 && secret.length > 0, @"mParticle SDK apiKey and secret cannot be an empty string.");
    NSAssert((NSNull *)apiKey != [NSNull null] && (NSNull *)secret != [NSNull null], @"mParticle SDK apiKey and secret cannot be null.");
    
    self.options = options;
    
    MPInstallationType installationType = options.installType;
    MPEnvironment environment = options.environment;
    BOOL proxyAppDelegate = options.proxyAppDelegate;
    BOOL startKitsAsync = options.startKitsAsync;
    
    __weak MParticle *weakSelf = self;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    BOOL firstRun = [userDefaults mpObjectForKey:kMParticleFirstRun userId:[MPPersistenceController mpId]] == nil;
    _proxiedAppDelegate = proxyAppDelegate;
    _automaticSessionTracking = self.options.automaticSessionTracking;
    _customUserAgent = self.options.customUserAgent;
    _collectUserAgent = self.options.collectUserAgent;
    
    id currentIdentifier = userDefaults[kMPUserIdentitySharedGroupIdentifier];
    if (options.sharedGroupID == currentIdentifier) {
        // Do nothing, we only want to update NSUserDefaults on a change
    } else if (options.sharedGroupID && ![options.sharedGroupID isEqualToString:@""]) {
        [userDefaults migrateToSharedGroupIdentifier:options.sharedGroupID];
    } else {
        [userDefaults migrateFromSharedGroupIdentifier];
    }

    if (environment == MPEnvironmentDevelopment) {
        MPILogWarning(@"SDK has been initialized in Development mode.");
    } else if (environment == MPEnvironmentProduction) {
        MPILogWarning(@"SDK has been initialized in Production Mode.");
    }
    
    [MPStateMachine setEnvironment:environment];
    [MPStateMachine sharedInstance].automaticSessionTracking = options.automaticSessionTracking;

    [self.backendController startWithKey:apiKey
                                  secret:secret
                                firstRun:firstRun
                        installationType:installationType
                        proxyAppDelegate:proxyAppDelegate
                          startKitsAsync:startKitsAsync
                       completionHandler:^{
                           __strong MParticle *strongSelf = weakSelf;
                           
                           if (!strongSelf) {
                               return;
                           }
                           
                           MPIdentityApiRequest *identifyRequest = nil;
                           if (options.identifyRequest) {
                               identifyRequest = options.identifyRequest;
                           }
                           else {
                               MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
                               identifyRequest = [MPIdentityApiRequest requestWithUser:user];
                           }
                           
                           [strongSelf.identity identifyNoDispatch:identifyRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
                               if (error) {
                                   MPILogError(@"Identify request failed with error: %@", error);
                               }
                               if (options.onIdentifyComplete) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       options.onIdentifyComplete(apiResult, error);
                                   });
                               }
                           }];
                           
                           if (firstRun) {
                               [userDefaults setMPObject:@NO forKey:kMParticleFirstRun userId:[MPPersistenceController mpId]];
                               [userDefaults synchronize];
                           }

                           strongSelf->_optOut = [MPStateMachine sharedInstance].optOut;
                           strongSelf->privateOptOut = @(strongSelf->_optOut);
                           
                           if (strongSelf.configSettings) {
                               
                               if (strongSelf.configSettings[kMPConfigSessionTimeout]) {
                                   strongSelf.sessionTimeout = [strongSelf.configSettings[kMPConfigSessionTimeout] doubleValue];
                               }
                               
                               if (strongSelf.configSettings[kMPConfigUploadInterval]) {
                                   strongSelf.uploadInterval = [strongSelf.configSettings[kMPConfigUploadInterval] doubleValue];
                               }

#if TARGET_OS_IOS == 1
    #if defined(MP_CRASH_REPORTER)
                               if ([strongSelf.configSettings[kMPConfigEnableCrashReporting] boolValue]) {
                                   [strongSelf beginUncaughtExceptionLogging];
                               }
    #endif
                               
                               if ([strongSelf.configSettings[kMPConfigLocationTracking] boolValue]) {
                                   CLLocationAccuracy accuracy = [strongSelf.configSettings[kMPConfigLocationAccuracy] doubleValue];
                                   CLLocationDistance distanceFilter = [strongSelf.configSettings[kMPConfigLocationDistanceFilter] doubleValue];
                                   [strongSelf beginLocationTracking:accuracy minDistance:distanceFilter];
                               }
#endif
                           }
                           
                           strongSelf.initialized = YES;
                           
                           [[NSNotificationCenter defaultCenter] postNotificationName:mParticleDidFinishInitializing
                                                                               object:self
                                                                             userInfo:nil];
                       }];
}

#pragma mark Application notifications
#if TARGET_OS_IOS == 1
#if !defined(MPARTICLE_APP_EXTENSIONS)
- (NSData *)pushNotificationToken {
    return [MPNotificationController deviceToken];
}

- (void)setPushNotificationToken:(NSData *)pushNotificationToken {
    [MPNotificationController setDeviceToken:pushNotificationToken];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)didReceiveLocalNotification:(UILocalNotification *)notification {
#pragma clang diagnostic pop
    NSDictionary *userInfo = [MPNotificationController dictionaryFromLocalNotification:notification];
    if (userInfo && !self.proxiedAppDelegate) {
        [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:nil userNotificationMode:MPUserNotificationModeLocal];
    }
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:nil userNotificationMode:MPUserNotificationModeRemote];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification {
#pragma clang diagnostic pop
    NSDictionary *userInfo = [MPNotificationController dictionaryFromLocalNotification:notification];
    if (userInfo && !self.proxiedAppDelegate) {
        [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeLocal];
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
}
#endif
#endif

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (_proxiedAppDelegate) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    if (_proxiedAppDelegate || [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        return;
    }
    
    [[MPAppNotificationHandler sharedInstance] openURL:url options:options];
}

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {
    if (self.proxiedAppDelegate) {
        return NO;
    }

    return [[MPAppNotificationHandler sharedInstance] continueUserActivity:userActivity restorationHandler:restorationHandler];
}

#pragma mark Basic tracking
- (nullable NSSet *)activeTimedEvents {
    return self.backendController.eventSet;
}

- (void)beginTimedEvent:(MPEvent *)event {
    [self.backendController beginTimedEvent:event
                          completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                              dispatch_async([MParticle messageQueue], ^{
                                  if (execStatus == MPExecStatusSuccess) {
                                      MPILogDebug(@"Began timed event: %@", event);
                                      
                                      // Forwarding calls to kits
                                      [[MPKitContainer sharedInstance] forwardSDKCall:@selector(beginTimedEvent:)
                                                                                event:event
                                                                          messageType:MPMessageTypeEvent
                                                                             userInfo:nil
                                                                           kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                               *execStatus = [kit beginTimedEvent:forwardEvent];
                                                                           }];
                                  }
                              });
                          }];
}

- (void)endTimedEvent:(MPEvent *)event {
    [event endTiming];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Ended and logged timed event: %@", event);
                               
                               // Forwarding calls to kits
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(endTimedEvent:)
                                                                         event:event
                                                                   messageType:MPMessageTypeEvent
                                                                      userInfo:nil
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                        *execStatus = [kit endTimedEvent:forwardEvent];
                                                                    }];
                               
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logEvent:)
                                                                         event:event
                                                                   messageType:MPMessageTypeEvent
                                                                      userInfo:nil
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                        if (![kit respondsToSelector:@selector(endTimedEvent:)]) {
                                                                            *execStatus = [kit logEvent:forwardEvent];
                                                                        }
                                                                    }];
                               
                           }
                       }];
    });
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    return [self.backendController eventWithName:eventName];
}

- (void)logEvent:(MPEvent *)event {
    [event endTiming];
    dispatch_async(messageQueue, ^{
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged event: %@", event);
                               
                               // Forwarding calls to kits
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logEvent:)
                                                                         event:event
                                                                   messageType:MPMessageTypeEvent
                                                                      userInfo:nil
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus *__autoreleasing *execStatus) {
                                                                        *execStatus = [kit logEvent:forwardEvent];
                                                                    }];
                           }
                       }];
    });
}

- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    MPEvent *event = [self.backendController eventWithName:eventName];
    if (event) {
        event.type = eventType;
    } else {
        event = [[MPEvent alloc] initWithName:eventName type:eventType];
    }
    
    event.info = eventInfo;
    [self logEvent:event];
}

- (void)logScreenEvent:(MPEvent *)event {
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    dispatch_async(messageQueue, ^{
        [self.backendController logScreen:event
                        completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                            if (execStatus == MPExecStatusSuccess) {
                                MPILogDebug(@"Logged screen event: %@", event);
                                
                                // Forwarding calls to kits
                                [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logScreen:)
                                                                          event:event
                                                                    messageType:MPMessageTypeScreenView
                                                                       userInfo:nil
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                         *execStatus = [kit logScreen:forwardEvent];
                                                                     }];
                            }
                        }];
    });
}

- (void)logScreen:(NSString *)screenName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!screenName) {
        MPILogError(@"Screen name is required.");
        return;
    }
    
    MPEvent *event = [self.backendController eventWithName:screenName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:screenName type:MPEventTypeNavigation];
    }
    
    event.info = eventInfo;
    
    [self logScreenEvent:event];
}

#pragma mark Attribution
- (nullable NSDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo {
    return [[MPKitContainer sharedInstance].attributionInfo copy];
}

#pragma mark Error, Exception, and Crash Handling
- (void)beginUncaughtExceptionLogging {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    if (self.backendController.initializationStatus == MPInitializationStatusStarted) {
        [exceptionHandler beginUncaughtExceptionLogging];
        isLoggingUncaughtExceptions = YES;
        MPILogDebug(@"Begin uncaught exception logging.");
    } else if (self.backendController.initializationStatus == MPInitializationStatusStarting) {
        __weak MParticle *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MParticle *strongSelf = weakSelf;
            [strongSelf beginUncaughtExceptionLogging];
        });
    }
#endif
}

- (void)endUncaughtExceptionLogging {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    if (self.backendController.initializationStatus == MPInitializationStatusStarted) {
        [exceptionHandler endUncaughtExceptionLogging];
        isLoggingUncaughtExceptions = NO;
        MPILogDebug(@"End uncaught exception logging.");
    } else if (self.backendController.initializationStatus == MPInitializationStatusStarting) {
        __weak MParticle *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MParticle *strongSelf = weakSelf;
            [strongSelf endUncaughtExceptionLogging];
        });
    }
#endif
}

- (void)leaveBreadcrumb:(NSString *)breadcrumbName {
    [self leaveBreadcrumb:breadcrumbName eventInfo:nil];
}

- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!breadcrumbName) {
        MPILogError(@"Breadcrumb name is required.");
        return;
    }
    
    MPEvent *event = [self.backendController eventWithName:breadcrumbName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:breadcrumbName type:MPEventTypeOther];
    }
    
    event.info = eventInfo;
    
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController leaveBreadcrumb:event
                              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                                  if (execStatus == MPExecStatusSuccess) {
                                      MPILogDebug(@"Left breadcrumb: %@", event);
                                      
                                      // Forwarding calls to kits
                                      [[MPKitContainer sharedInstance] forwardSDKCall:@selector(leaveBreadcrumb:)
                                                                                event:event
                                                                          messageType:MPMessageTypeBreadcrumb
                                                                             userInfo:nil
                                                                           kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus *__autoreleasing *execStatus) {
                                                                               *execStatus = [kit leaveBreadcrumb:forwardEvent];
                                                                           }];
                                  }
                              }];
    });
}

- (void)logError:(NSString *)message {
    [self logError:message eventInfo:nil];
}

- (void)logError:(NSString *)message eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!message) {
        MPILogError(@"'message' is required for %@", NSStringFromSelector(_cmd));
        return;
    }
    
    dispatch_async(messageQueue, ^{
        [self.backendController logError:message
                               exception:nil
                          topmostContext:nil
                               eventInfo:eventInfo
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged error with message: %@", message);
                               
                               // Forwarding calls to kits
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logError:eventInfo:)
                                                                  errorMessage:message
                                                                     exception:nil
                                                                     eventInfo:eventInfo
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPKitExecStatus *__autoreleasing *execStatus) {
                                                                        *execStatus = [kit logError:message eventInfo:eventInfo];
                                                                    }];
                           }
                       }];
    });
}

- (void)logException:(NSException *)exception {
    [self logException:exception topmostContext:nil];
}

- (void)logException:(NSException *)exception topmostContext:(id)topmostContext {
    dispatch_async(messageQueue, ^{
        [self.backendController logError:nil
                               exception:exception
                          topmostContext:topmostContext
                               eventInfo:nil
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged exception name: %@, reason: %@, topmost context: %@", message, exception.reason, topmostContext);
                               
                               // Forwarding calls to kits
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logError:eventInfo:)
                                                                  errorMessage:nil
                                                                     exception:exception
                                                                     eventInfo:nil
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPKitExecStatus *__autoreleasing *execStatus) {
                                                                        *execStatus = [kit logException:exception];
                                                                    }];
                           }
                       }];
    });
}

#pragma mark eCommerce transactions
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!commerceEvent.timestamp) {
        commerceEvent.timestamp = [NSDate date];
    }
    dispatch_async(messageQueue, ^{
        [self.backendController logCommerceEvent:commerceEvent
                               completionHandler:^(MPCommerceEvent *commerceEvent, MPExecStatus execStatus) {
                                   if (execStatus == MPExecStatusSuccess) {
                                       MPILogDebug(@"Logged commerce event: %@", commerceEvent);
                                       
                                       // Forwarding calls to kits
                                       SEL logCommerceEventSelector = @selector(logCommerceEvent:);
                                       SEL logEventSelector = @selector(logEvent:);
                                       
                                       [[MPKitContainer sharedInstance] forwardCommerceEventCall:commerceEvent
                                                                                      kitHandler:^(id<MPKitProtocol> kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
                                                                                          if (kitFilter.forwardCommerceEvent) {
                                                                                              if ([kit respondsToSelector:logCommerceEventSelector]) {
                                                                                                  *execStatus = [kit logCommerceEvent:kitFilter.forwardCommerceEvent];
                                                                                              } else if ([kit respondsToSelector:logEventSelector]) {
                                                                                                  NSArray *expandedInstructions = [kitFilter.forwardCommerceEvent expandedInstructions];
                                                                                                  
                                                                                                  for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
                                                                                                      [kit logEvent:commerceEventInstruction.event];
                                                                                                  }
                                                                                                  
                                                                                                  *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[kit class] kitCode] returnCode:MPKitReturnCodeSuccess];
                                                                                              }
                                                                                          }
                                                                                          
                                                                                          if (kitFilter.forwardEvent && [kit respondsToSelector:logEventSelector]) {
                                                                                              *execStatus = [kit logEvent:kitFilter.forwardEvent];
                                                                                          }
                                                                                      }];
                                   }
                               }];
    });
}

- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName {
    [self logLTVIncrease:increaseAmount eventName:eventName eventInfo:nil];
}

- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    NSMutableDictionary *eventDictionary = [@{@"$Amount":@(increaseAmount),
                                              kMPMethodName:@"LogLTVIncrease"}
                                            mutableCopy];
    
    if (eventInfo) {
        [eventDictionary addEntriesFromDictionary:eventInfo];
    }
    
    if (!eventName) {
        eventName = @"Increase LTV";
    }
    
    MPEvent *event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
    event.info = eventDictionary;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       if (execStatus == MPExecStatusSuccess) {
                           MPILogDebug(@"Logged LTV Increase: %@", event);
                           
                           // Forwarding calls to kits
                           [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logLTVIncrease:event:)
                                                                     event:nil
                                                               messageType:MPMessageTypeUnknown
                                                                  userInfo:nil
                                                                kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                    *execStatus = [kit logLTVIncrease:increaseAmount event:forwardEvent];
                                                                }];
                       }
                   }];
}

#pragma mark Extensions
+ (BOOL)registerExtension:(nonnull id<MPExtensionProtocol>)extension {
    NSAssert(extension != nil, @"Required parameter. It cannot be nil.");
    BOOL registrationSuccessful = NO;
    
    if ([extension conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
        registrationSuccessful = [MPKitContainer registerKit:(id<MPExtensionKitProtocol>)extension];
    }
    
    return registrationSuccessful;
}

#pragma mark Integration attributes
- (nonnull MPKitExecStatus *)setIntegrationAttributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes forKit:(nonnull NSNumber *)kitCode {
    __block MPKitReturnCode returnCode = MPKitReturnCodeSuccess;

    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    
    if (integrationAttributes) {
        dispatch_async(messageQueue, ^{
            [[MPPersistenceController sharedInstance] saveIntegrationAttributes:integrationAttributes];
        });
        
    } else {
        returnCode = MPKitReturnCodeRequirementsNotMet;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:kitCode returnCode:returnCode forwardCount:0];
}

- (nonnull MPKitExecStatus *)clearIntegrationAttributesForKit:(nonnull NSNumber *)kitCode {
    MPKitReturnCode returnCode = MPKitReturnCodeSuccess;
    BOOL validKitCode = [MPKitInstanceValidator isValidKitCode:kitCode];

    if (validKitCode) {
        dispatch_async(messageQueue, ^{
            [[MPPersistenceController sharedInstance] deleteIntegrationAttributesForKitCode:kitCode];
        });
    } else {
        returnCode = MPKitReturnCodeRequirementsNotMet;
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:kitCode returnCode:returnCode forwardCount:0];
}

#pragma mark Kits

- (void)onKitsInitialized:(void(^)(void))block {
    BOOL kitsInitialized = [MPKitContainer sharedInstance].kitsInitialized;
    if (kitsInitialized) {
        block();
    } else {
        [self.kitsInitializedBlocks addObject:[block copy]];
    }
}

- (void)executeKitsInitializedBlocks {
    [self.kitsInitializedBlocks enumerateObjectsUsingBlock:^(void (^block)(void), NSUInteger idx, BOOL * _Nonnull stop) {
        block();
    }];
    [self.kitsInitializedBlocks removeAllObjects];
}

- (BOOL)isKitActive:(nonnull NSNumber *)kitCode {
    BOOL isValidKitCode = [kitCode isKindOfClass:[NSNumber class]] && [MPKitInstanceValidator isValidKitCode:kitCode];
    NSAssert(isValidKitCode, @"The value in kitCode is not valid. See MPKitInstance.");
    
    if (!isValidKitCode) {
        return NO;
    }

    return [self.kitActivity isKitActive:kitCode];
}

- (nullable id const)kitInstance:(nonnull NSNumber *)kitCode {
    BOOL isValidKitCode = [kitCode isKindOfClass:[NSNumber class]] && [MPKitInstanceValidator isValidKitCode:kitCode];
    NSAssert(isValidKitCode, @"The value in kitCode is not valid. See MPKitInstance.");

    if (!isValidKitCode) {
        return nil;
    }
    
    return [self.kitActivity kitInstance:kitCode];
}

- (void)kitInstance:(NSNumber *)kitCode completionHandler:(void (^)(id _Nullable kitInstance))completionHandler {
    BOOL isValidKitCode = [kitCode isKindOfClass:[NSNumber class]] && [MPKitInstanceValidator isValidKitCode:kitCode];
    BOOL isValidCompletionHandler = completionHandler != nil;
    NSAssert(isValidKitCode, @"The value in kitCode is not valid. See MPKitInstance.");
    NSAssert(isValidCompletionHandler, @"The parameter completionHandler is required.");
    
    if (!isValidKitCode || !isValidCompletionHandler) {
        return;
    }
    
    [self.kitActivity kitInstance:kitCode withHandler:completionHandler];
}

#pragma mark Location
#if TARGET_OS_IOS == 1
- (BOOL)backgroundLocationTracking {
    return [MPStateMachine sharedInstance].locationManager.backgroundLocationTracking;
}

- (void)setBackgroundLocationTracking:(BOOL)backgroundLocationTracking {
    [MPStateMachine sharedInstance].locationManager.backgroundLocationTracking = backgroundLocationTracking;
}

- (CLLocation *)location {
    return [MPStateMachine sharedInstance].location;
}

- (void)setLocation:(CLLocation *)location {
    [MPStateMachine sharedInstance].location = location;
    MPILogDebug(@"Set location %@", location);
    
    // Forwarding calls to kits
    [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                              event:nil
                                        messageType:MPMessageTypeEvent
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit setLocation:location];
                                         }];
}

- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter {
    [self beginLocationTracking:accuracy minDistance:distanceFilter authorizationRequest:MPLocationAuthorizationRequestAlways];
}

- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    MPExecStatus execStatus = [_backendController beginLocationTrackingWithAccuracy:accuracy distanceFilter:distanceFilter authorizationRequest:authorizationRequest];
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Began location tracking with accuracy: %0.0f and distance filter %0.0f", accuracy, distanceFilter);
    } else {
        MPILogError(@"Could not begin location tracking: %@", [_backendController execStatusDescription:execStatus]);
    }
}

- (void)endLocationTracking {
    MPExecStatus execStatus = [_backendController endLocationTracking];
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Ended location tracking");
    } else {
        MPILogError(@"Could not end location tracking: %@", [_backendController execStatusDescription:execStatus]);
    }
}
#endif

- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:urlRequest networkMeasurementMode:MPNetworkMeasurementModePreserveQuery];
    networkPerformance.httpMethod = httpMethod;
    networkPerformance.startTime = startTime;
    networkPerformance.elapsedTime = duration;
    networkPerformance.bytesOut = bytesSent;
    networkPerformance.bytesIn = bytesReceived;
    
    
    dispatch_async(messageQueue, ^{
        
        [self.backendController logNetworkPerformanceMeasurement:networkPerformance
                                               completionHandler:^(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus) {
                                                   
                                                   if (execStatus == MPExecStatusSuccess) {
                                                       MPILogDebug(@"Logged network performance measurement");
                                                   }
                                               }];
        
    });
}

#pragma mark Session management
- (NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value {
    dispatch_async(messageQueue, ^{
        
        NSNumber *newValue = [self.backendController incrementSessionAttribute:[MPStateMachine sharedInstance].currentSession key:key byValue:value];
        
        MPILogDebug(@"Session attribute %@ incremented by %@. New value: %@", key, value, newValue);
        
    });
    
    return @0;
}

- (void)setSessionAttribute:(NSString *)key value:(id)value {
    dispatch_async(messageQueue, ^{
        
        MPExecStatus execStatus = [self.backendController setSessionAttribute:[MPStateMachine sharedInstance].currentSession key:key value:value];
        if (execStatus == MPExecStatusSuccess) {
            MPILogDebug(@"Set session attribute - %@:%@", key, value);
        } else {
            MPILogError(@"Could not set session attribute - %@:%@\n Reason: %@", key, value, [self.backendController execStatusDescription:execStatus]);
        }
    });
}

- (void)upload {
    __weak MParticle *weakSelf = self;
    
    dispatch_async(messageQueue, ^{
        __strong MParticle *strongSelf = weakSelf;
        
        MPExecStatus execStatus = [strongSelf.backendController uploadDatabaseWithCompletionHandler:nil];
        
        if (execStatus == MPExecStatusSuccess) {
            MPILogDebug(@"Forcing Upload");
        } else {
            MPILogError(@"Could not upload data: %@", [strongSelf.backendController execStatusDescription:execStatus]);
        }
    });
}

#pragma mark Surveys
- (NSString *)surveyURL:(MPSurveyProvider)surveyProvider {
    NSMutableDictionary *userAttributes = nil;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSDictionary *savedUserAttributes = userDefaults[kMPUserAttributeKey];
    if (savedUserAttributes) {
        userAttributes = [[NSMutableDictionary alloc] initWithCapacity:savedUserAttributes.count];
        NSEnumerator *attributeEnumerator = [savedUserAttributes keyEnumerator];
        NSString *key;
        id value;
        Class NSStringClass = [NSString class];
        
        while ((key = [attributeEnumerator nextObject])) {
            value = savedUserAttributes[key];
            
            if ([value isKindOfClass:NSStringClass]) {
                if (![savedUserAttributes[key] isEqualToString:kMPNullUserAttributeString]) {
                    userAttributes[key] = value;
                }
            } else {
                userAttributes[key] = value;
            }
        }
    }
    
    __block NSString *surveyURL = nil;
    
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(surveyURLWithUserAttributes:)
                                     userAttributes:userAttributes
                                         kitHandler:^(id<MPKitProtocol> kit, NSDictionary *forwardAttributes, MPKitConfiguration *kitConfig) {
                                             FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:kitConfig];
                                             surveyURL = [kit surveyURLWithUserAttributes:filteredUser.userAttributes];
                                         }];
    
    return surveyURL;
}

#pragma mark User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification {
    [[MPAppNotificationHandler sharedInstance] userNotificationCenter:center willPresentNotification:notification];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response {
    [[MPAppNotificationHandler sharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response];
}
#endif

#pragma mark Web Views
#if TARGET_OS_IOS == 1
// Updates isIOS flag in JS API to true via webview.
- (void)initializeWebView:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:@"mParticle.isIOS = true;"];
}

// A url is mParticle sdk url when it has prefix mp-sdk://
- (BOOL)isMParticleWebViewSdkUrl:(NSURL *)requestUrl {
    return [[requestUrl scheme] isEqualToString:kMParticleWebViewSdkScheme];
}

// Process web log event that is raised in iOS hybrid apps that are using UIWebView
- (void)processWebViewLogEvent:(NSURL *)requestUrl {
    if (![self isMParticleWebViewSdkUrl:requestUrl]) {
        return;
    }
    
    @try {
        NSError *error = nil;
        NSString *hostPath = [requestUrl host];
        NSString *paramStr = [[requestUrl pathComponents] objectAtIndex:1];
        NSData *eventDataStr = [paramStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *eventDictionary = [NSJSONSerialization JSONObjectWithData:eventDataStr options:kNilOptions error:&error];
        
        if ([hostPath hasPrefix:kMParticleWebViewPathLogEvent]) {
            MPJavascriptMessageType messageType = (MPJavascriptMessageType)[eventDictionary[@"EventDataType"] integerValue];
            switch (messageType) {
                case MPJavascriptMessageTypePageEvent: {
                    MPEvent *event = [[MPEvent alloc] initWithName:eventDictionary[@"EventName"] type:(MPEventType)[eventDictionary[@"EventCategory"] integerValue]];
                    event.info = eventDictionary[@"EventAttributes"];
                    [self logEvent:event];
                }
                    break;
                    
                case MPJavascriptMessageTypePageView: {
                    MPEvent *event = [[MPEvent alloc] initWithName:eventDictionary[@"EventName"] type:MPEventTypeNavigation];
                    event.info = eventDictionary[@"EventAttributes"];
                    [self logScreenEvent:event];
                }
                    break;

                case MPJavascriptMessageTypeCommerce: {
                    MPCommerceEvent *event = [MPConvertJS MPCommerceEvent:eventDictionary];
                    [self logCommerceEvent:event];
                }
                    break;

                case MPJavascriptMessageTypeOptOut:
                    [self setOptOut:[eventDictionary[@"OptOut"] boolValue]];
                    break;
                    
                case MPJavascriptMessageTypeSessionStart:
                case MPJavascriptMessageTypeSessionEnd:
                default:
                    break;
            }
        } else if ([hostPath hasPrefix:kMParticleWebViewPathIdentify]) {
            MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:eventDictionary];
            
            if (!request) {
                MPILogError(@"Unable to create identify request from webview JS dictionary: %@", eventDictionary);
                return;
            }
            
            [[MParticle sharedInstance].identity identify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
                
            }];
            
            
        } else if ([hostPath hasPrefix:kMParticleWebViewPathLogin]) {
            MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:eventDictionary];
            
            if (!request) {
                MPILogError(@"Unable to create login request from webview JS dictionary: %@", eventDictionary);
                return;
            }
            
            [[MParticle sharedInstance].identity login:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
                
            }];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathLogout]) {
            MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:eventDictionary];
            
            if (!request) {
                MPILogError(@"Unable to create logout request from webview JS dictionary: %@", eventDictionary);
                return;
            }
            
            [[MParticle sharedInstance].identity logout:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
                
            }];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathModify]) {
            MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:eventDictionary];
            
            if (!request) {
                MPILogError(@"Unable to create modify request from webview JS dictionary: %@", eventDictionary);
                return;
            }
            
            [[MParticle sharedInstance].identity modify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
                
            }];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetUserTag]) {
            [self.identity.currentUser setUserTag:eventDictionary[@"key"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathRemoveUserTag]) {
            [self.identity.currentUser removeUserAttribute:eventDictionary[@"key"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetUserAttribute]) {
            [self.identity.currentUser setUserAttribute:eventDictionary[@"key"] value:eventDictionary[@"value"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathRemoveUserAttribute]) {
            [self.identity.currentUser removeUserAttribute:eventDictionary[@"key"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetSessionAttribute]) {
            [self setSessionAttribute:eventDictionary[@"key"] value:eventDictionary[@"value"]];
        }
    } @catch (NSException *e) {
        MPILogError(@"Exception processing UIWebView event: %@", e.reason)
    }
}
#endif

@end
