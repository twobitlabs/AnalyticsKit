#import "mParticle.h"
#import "MPAppNotificationHandler.h"
#import "MPBackendController.h"
#import "MPConsumerInfo.h"
#import "MPDevice.h"
#import "MPForwardQueueParameters.h"
#import "MPForwardRecord.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPIntegrationAttributes.h"
#import "MPKitActivity.h"
#import "MPKitContainer.h"
#import "MPKitFilter.h"
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
#import "MPIHasher.h"
#import "MPApplication.h"
#import "MParticleWebView.h"

#if TARGET_OS_IOS == 1
    #import "MPLocationManager.h"

    #if defined(MP_CRASH_REPORTER)
        #import "MPExceptionHandler.h"
    #endif
#endif

static dispatch_queue_t messageQueue = nil;
static void *messageQueueKey = "mparticle message queue key";
static void *messageQueueToken = "mparticle message queue token";
static NSArray *eventTypeStrings = nil;
static MParticle *_sharedInstance = nil;
static dispatch_once_t predicate;

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

@interface MParticle() <MPBackendControllerDelegate
#if TARGET_OS_IOS == 1
, WKScriptMessageHandler
#endif
> {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    MPExceptionHandler *exceptionHandler;
#endif
    BOOL isLoggingUncaughtExceptions;
    BOOL sdkInitialized;
}

@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;
@property (nonatomic, strong) MPAppNotificationHandler *appNotificationHandler;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
@property (nonatomic, strong, nullable) NSMutableDictionary *configSettings;
@property (nonatomic, strong, nullable) MPKitActivity *kitActivity;
@property (nonatomic, unsafe_unretained) BOOL initialized;
@property (nonatomic, strong, nonnull) NSMutableArray *kitsInitializedBlocks;
@property (nonatomic, readwrite) MPNetworkOptions *networkOptions;
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *deferredKitConfiguration;

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

@interface MParticleSession ()

@property (nonatomic, readwrite) NSNumber *sessionID;
@property (nonatomic, readwrite) NSString *UUID;

@end

@implementation MParticleSession
@end

@implementation MPNetworkOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pinningDisabledInDevelopment = NO;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPNetworkOptions {\n"];
    [description appendFormat:@"  configHost: %@\n", _configHost];
    [description appendFormat:@"  eventsHost: %@\n", _eventsHost];
    [description appendFormat:@"  identityHost: %@\n", _identityHost];
    [description appendFormat:@"  certificates: %@\n", _certificates];
    [description appendString:@"}"];
    return description;
}

@end

@interface MParticleOptions ()

@property (nonatomic, assign, readwrite) BOOL isProxyAppDelegateSet;
@property (nonatomic, assign, readwrite) BOOL isCollectUserAgentSet;
@property (nonatomic, assign, readwrite) BOOL isCollectSearchAdsAttributionSet;
@property (nonatomic, assign, readwrite) BOOL isTrackNotificationsSet;
@property (nonatomic, assign, readwrite) BOOL isAutomaticSessionTrackingSet;
@property (nonatomic, assign, readwrite) BOOL isStartKitsAsyncSet;
@property (nonatomic, assign, readwrite) BOOL isUploadIntervalSet;
@property (nonatomic, assign, readwrite) BOOL isSessionTimeoutSet;

@end

@implementation MParticleOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _proxyAppDelegate = YES;
        _collectUserAgent = YES;
        _collectSearchAdsAttribution = YES;
        _trackNotifications = YES;
        _automaticSessionTracking = YES;
        _startKitsAsync = NO;
        _logLevel = MPILogLevelNone;
        _uploadInterval = 0.0;
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
    }
    return self;
}

+ (id)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret {
    MParticleOptions *options = [[self alloc] init];
    options.apiKey = apiKey;
    options.apiSecret = secret;
    return options;
}

- (void)setProxyAppDelegate:(BOOL)proxyAppDelegate {
    _proxyAppDelegate = proxyAppDelegate;
    _isProxyAppDelegateSet = YES;
}

- (void)setCollectUserAgent:(BOOL)collectUserAgent {
    _collectUserAgent = collectUserAgent;
    _isCollectUserAgentSet = YES;
}

- (void)setCollectSearchAdsAttribution:(BOOL)collectSearchAdsAttribution {
    _collectSearchAdsAttribution = collectSearchAdsAttribution;
    _isCollectSearchAdsAttributionSet = YES;
}

- (void)setTrackNotifications:(BOOL)trackNotifications {
    _trackNotifications = trackNotifications;
    _isTrackNotificationsSet = YES;
}

- (void)setAutomaticSessionTracking:(BOOL)automaticSessionTracking {
    _automaticSessionTracking = automaticSessionTracking;
    _isAutomaticSessionTrackingSet = YES;
}

- (void)setStartKitsAsync:(BOOL)startKitsAsync {
    _startKitsAsync = startKitsAsync;
    _isStartKitsAsyncSet = YES;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    _uploadInterval = uploadInterval;
    _isUploadIntervalSet = YES;
}

- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    _sessionTimeout = sessionTimeout;
    _isSessionTimeoutSet = YES;
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
@synthesize persistenceController = _persistenceController;
@synthesize stateMachine = _stateMachine;
@synthesize kitContainer = _kitContainer;
@synthesize appNotificationHandler = _appNotificationHandler;

+ (void)initialize {
    eventTypeStrings = @[@"Reserved - Not Used", @"Navigation", @"Location", @"Search", @"Transaction", @"UserContent", @"UserPreference", @"Social", @"Other"];
}

+ (dispatch_queue_t)messageQueue {
    return messageQueue;
}

+ (BOOL)isMessageQueue {
    void *token = dispatch_get_specific(messageQueueKey);
    BOOL isMessage = token == messageQueueToken;
    return isMessage;
}

+ (void)executeOnMessage:(void(^)(void))block {
    if ([MParticle isMessageQueue]) {
        block();
    } else {
        dispatch_async([MParticle messageQueue], block);
    }
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    messageQueue = dispatch_queue_create("com.mparticle.messageQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(messageQueue, messageQueueKey, messageQueueToken, nil);
    sdkInitialized = NO;
    isLoggingUncaughtExceptions = NO;
    _initialized = NO;
    _kitActivity = [[MPKitActivity alloc] init];
    _kitsInitializedBlocks = [NSMutableArray array];
    _collectUserAgent = YES;
    _collectSearchAdsAttribution = YES;
    _trackNotifications = YES;
    _automaticSessionTracking = YES;
    _appNotificationHandler = [[MPAppNotificationHandler alloc] init];
    _stateMachine = [[MPStateMachine alloc] init];
    
    return self;
}

- (void)dealloc {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
#endif
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark Private accessors
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

#pragma mark MPBackendControllerDelegate methods
- (void)sessionDidBegin:(MPSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(beginSession)
                                                          event:nil
                                                     parameters:nil
                                                    messageType:MPMessageTypeSessionStart
                                                       userInfo:nil
         ];
    });
}

- (void)sessionDidEnd:(MPSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(endSession)
                                                          event:nil
                                                     parameters:nil
                                                    messageType:MPMessageTypeSessionEnd
                                                       userInfo:nil
         ];
    });
}

#pragma mark MPBackendControllerDelegate methods
- (void)forwardLogInstall {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer forwardSDKCall:_cmd
                                                          event:nil
                                                     parameters:nil
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

- (void)forwardLogUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer forwardSDKCall:_cmd
                                                          event:nil
                                                     parameters:nil
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
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

- (MPEnvironment)environment {
    return [MPStateMachine environment];
}

- (MPILogLevel)logLevel {
    return [MParticle sharedInstance].stateMachine.logLevel;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    self.stateMachine.logLevel = logLevel;
}

- (BOOL)optOut {
    return [MParticle sharedInstance].stateMachine.optOut;
}

- (void)setOptOut:(BOOL)optOut {
    if (self.stateMachine.optOut == optOut) {
        return;
    }
    
    _optOut = optOut;
    self.stateMachine.optOut = optOut;
    
    // Forwarding calls to kits
    [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(setOptOut:)
                                                      event:nil
                                                 parameters:nil
                                                messageType:MPMessageTypeOptOut
                                                   userInfo:@{kMPStateKey:@(optOut)}
     ];
    
    [self.backendController setOptOut:optOut
                    completionHandler:^(BOOL optOut, MPExecStatus execStatus) {
                        if (execStatus == MPExecStatusSuccess) {
                            MPILogDebug(@"Set Opt Out: %d", optOut);
                        } else {
                            MPILogDebug(@"Set Opt Out Failed: %lu", (unsigned long)execStatus);
                        }
                    }];
}

- (NSTimeInterval)sessionTimeout {
    return self.backendController.sessionTimeout;
}

- (NSString *)uniqueIdentifier {
    return [MParticle sharedInstance].stateMachine.consumerInfo.uniqueIdentifier;
}

- (NSTimeInterval)uploadInterval {
    return self.backendController.uploadInterval;
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
    dispatch_once(&predicate, ^{
        _sharedInstance = [[MParticle alloc] init];
    });
    
    return _sharedInstance;
}

+(void)setSharedInstance:(MParticle *)instance {
    predicate = 0; // resets the once_token so dispatch_once will run again
    _sharedInstance = instance;
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:instance];
}

- (void)startWithOptions:(MParticleOptions *)options {
    if (sdkInitialized) {
        return;
    }
    sdkInitialized = YES;
    
    [MParticleWebView setCustomUserAgent:options.customUserAgent];
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:options];
    
    _backendController = [[MPBackendController alloc] initWithDelegate:self];

#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
#endif
    
    if (options.networkOptions) {
        self.networkOptions = options.networkOptions;
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
    if (firstRun) {
        NSDate *firstSeen = [NSDate date];
        NSNumber *firstSeenMs = @([firstSeen timeIntervalSince1970] * 1000.0);
        [userDefaults setMPObject:firstSeenMs forKey:kMPFirstSeenUser userId:[MPPersistenceController mpId]];
    }
    
    _proxiedAppDelegate = proxyAppDelegate;
    _automaticSessionTracking = self.options.automaticSessionTracking;
    _customUserAgent = self.options.customUserAgent;
    _collectUserAgent = self.options.collectUserAgent;
    _collectSearchAdsAttribution = self.options.collectSearchAdsAttribution;
    _trackNotifications = self.options.trackNotifications;
    self.backendController.uploadInterval = options.uploadInterval;
    self.backendController.sessionTimeout = options.sessionTimeout;
    self.logLevel = options.logLevel;
    
    MPConsentState *consentState = self.options.consentState;
    
    [userDefaults setSharedGroupIdentifier:self.options.sharedGroupID];

    if (environment == MPEnvironmentDevelopment) {
        MPILogWarning(@"SDK has been initialized in Development mode.");
    } else if (environment == MPEnvironmentProduction) {
        MPILogWarning(@"SDK has been initialized in Production Mode.");
    }
    
    [MPStateMachine setEnvironment:environment];
    [MParticle sharedInstance].stateMachine.automaticSessionTracking = options.automaticSessionTracking;
    
    _kitContainer = [[MPKitContainer alloc] init];

    [self.backendController startWithKey:apiKey
                                  secret:secret
                                firstRun:firstRun
                        installationType:installationType
                        proxyAppDelegate:proxyAppDelegate
                          startKitsAsync:startKitsAsync
                            consentState:consentState
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
                               
                               NSArray<NSDictionary *> *deferredKitConfiguration = self.deferredKitConfiguration;
                               
                               if (deferredKitConfiguration != nil && [deferredKitConfiguration isKindOfClass:[NSArray class]]) {
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [[MParticle sharedInstance].kitContainer configureKits:deferredKitConfiguration];
                                       weakSelf.deferredKitConfiguration = nil;
                                   });
                                   
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
                           
                           strongSelf->_optOut = [MParticle sharedInstance].stateMachine.optOut;
                           
                           if (strongSelf.configSettings) {
                               if (strongSelf.configSettings[kMPConfigSessionTimeout] && !options.isSessionTimeoutSet) {
                                   strongSelf.backendController.sessionTimeout = [strongSelf.configSettings[kMPConfigSessionTimeout] doubleValue];
                               }
                               
                               if (strongSelf.configSettings[kMPConfigUploadInterval] && !options.isUploadIntervalSet) {
                                   strongSelf.backendController.uploadInterval = [strongSelf.configSettings[kMPConfigUploadInterval] doubleValue];
                               }
                               
                               if (strongSelf.configSettings[kMPConfigCustomUserAgent] && !options.customUserAgent) {
                                   self->_customUserAgent = strongSelf.configSettings[kMPConfigCustomUserAgent];
                               }
                               
                               if (strongSelf.configSettings[kMPConfigCollectUserAgent] && !options.isCollectUserAgentSet) {
                                   self->_collectUserAgent = [strongSelf.configSettings[kMPConfigCollectUserAgent] boolValue];
                               }
                               
                               if (strongSelf.configSettings[kMPConfigTrackNotifications] && !options.isTrackNotificationsSet) {
                                   self->_trackNotifications = [strongSelf.configSettings[kMPConfigTrackNotifications] boolValue];
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
                           strongSelf.configSettings = nil;
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [[NSNotificationCenter defaultCenter] postNotificationName:mParticleDidFinishInitializing
                                                                                   object:self
                                                                                 userInfo:nil];
                           });
                       }];
}

- (NSNumber *)sessionIDFromUUID:(NSString *)uuid {
    NSNumber *sessionID = nil;
    sessionID = @([MPIHasher hashStringUTF16:uuid].integerValue);
    return sessionID;
}

- (MParticleSession *)currentSession {
    MParticleSession *session = nil;
    
    MPSession *sessionInternal = MParticle.sharedInstance.stateMachine.currentSession;
    
    if (sessionInternal) {
        NSNumber *sessionID = [self sessionIDFromUUID:sessionInternal.uuid];
        NSString *uuid = sessionInternal.uuid;
        
        session = [[MParticleSession alloc] init];
        session.sessionID = sessionID;
        session.UUID = uuid;
    }
    
    return session;
}

#pragma mark Application notifications
#if TARGET_OS_IOS == 1
- (NSData *)pushNotificationToken {
    if (![MPStateMachine isAppExtension]) {
        return [MPNotificationController deviceToken];
    } else {
        return nil;
    }
}

- (void)setPushNotificationToken:(NSData *)pushNotificationToken {
    if (![MPStateMachine isAppExtension]) {
        [MPNotificationController setDeviceToken:pushNotificationToken];
    }
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        [[MParticle sharedInstance].appNotificationHandler didReceiveRemoteNotification:userInfo];
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        [[MParticle sharedInstance].appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        [[MParticle sharedInstance].appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        [[MParticle sharedInstance].appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
    }
}

- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo {
    if (self.proxiedAppDelegate) {
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        [[MParticle sharedInstance].appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo];
    }
}
#endif

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (_proxiedAppDelegate) {
        return;
    }
    
    [[MParticle sharedInstance].appNotificationHandler openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    if (_proxiedAppDelegate || [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        return;
    }
    
    [[MParticle sharedInstance].appNotificationHandler openURL:url options:options];
}

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    if (self.proxiedAppDelegate) {
        return NO;
    }

    return [[MParticle sharedInstance].appNotificationHandler continueUserActivity:userActivity restorationHandler:restorationHandler];
}



- (void)reset {
    dispatch_sync(messageQueue, ^{
        [[MPIUserDefaults standardUserDefaults] resetDefaults];
        [[MParticle sharedInstance].persistenceController resetDatabase];
        [MParticle setSharedInstance:nil];
    });
}

#pragma mark Basic tracking
- (nullable NSSet *)activeTimedEvents {
    return self.backendController.eventSet;
}

- (void)beginTimedEvent:(MPEvent *)event {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
    [self.backendController beginTimedEvent:event
                          completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                              
                              if (execStatus == MPExecStatusSuccess) {
                                  MPILogDebug(@"Began timed event: %@", event);
                                  
                                  // Forwarding calls to kits
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(beginTimedEvent:)
                                                                                        event:event
                                                                                   parameters:nil
                                                                                  messageType:MPMessageTypeEvent
                                                                                     userInfo:nil
                                       ];
                                  });
                              }
                          }];
}

- (void)endTimedEvent:(MPEvent *)event {
    [event endTiming];
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
        
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   // Forwarding calls to kits
                                   [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(endTimedEvent:)
                                                                                     event:event
                                                                                parameters:nil
                                                                               messageType:MPMessageTypeEvent
                                                                                  userInfo:nil
                                    ];
                                   
                                   [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logEvent:)
                                                                                     event:event
                                                                                parameters:nil
                                                                               messageType:MPMessageTypeEvent
                                                                                  userInfo:nil
                                    ];
                                });
                           }
                       }];
    });
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    return [self.backendController eventWithName:eventName];
}

- (void)logEvent:(MPBaseEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil event!");
    } else if ([event isKindOfClass:[MPEvent class]]) {
        [self logCustomEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        [self logCommerceEvent:(MPCommerceEvent *)event];
    } else {
        dispatch_async(messageQueue, ^{
            [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
            
            [self.backendController logBaseEvent:event
                               completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {
                               }];
        });
    }
}

- (void)logCustomEvent:(MPEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil event!");
        return;
    }
    
    [event endTiming];
    
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];

        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       }];
        // Forwarding calls to kits
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logEvent:)
                                                              event:event
                                                         parameters:nil
                                                        messageType:MPMessageTypeEvent
                                                           userInfo:nil
             ];
        });
    });
}

- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    MPEvent *event = [self.backendController eventWithName:eventName];
    if (event) {
        event.type = eventType;
    } else {
        event = [[MPEvent alloc] initWithName:eventName type:eventType];
    }
    
    event.customAttributes = eventInfo;
    [self logEvent:event];
}

- (void)logScreenEvent:(MPEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil screen event!");
        return;
    }
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];

        [self.backendController logScreen:event
                        completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                            if (execStatus == MPExecStatusSuccess) {
                                MPILogDebug(@"Logged screen event: %@", event);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    // Forwarding calls to kits
                                    [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logScreen:)
                                                                                      event:event
                                                                                 parameters:nil
                                                                                messageType:MPMessageTypeScreenView
                                                                                   userInfo:nil
                                     ];
                                });
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
    
    event.customAttributes = eventInfo;
    
    [self logScreenEvent:event];
}

#pragma mark Attribution
- (nullable NSDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo {
    return [[MParticle sharedInstance].kitContainer.attributionInfo copy];
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
    
    event.customAttributes = eventInfo;
    
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:breadcrumbName parameter2:eventInfo];

        [self.backendController leaveBreadcrumb:event
                              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                                  if (execStatus == MPExecStatusSuccess) {
                                      MPILogDebug(@"Left breadcrumb: %@", event);
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          // Forwarding calls to kits
                                          [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(leaveBreadcrumb:)
                                                                                            event:event
                                                                                       parameters:nil
                                                                                      messageType:MPMessageTypeBreadcrumb
                                                                                         userInfo:nil
                                           ];
                                      });
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
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:message];

        [self.backendController logError:message
                               exception:nil
                          topmostContext:nil
                               eventInfo:eventInfo
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged error with message: %@", message);
                               
                               // Forwarding calls to kits
                               MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                               [queueParameters addParameter:message];
                               [queueParameters addParameter:eventInfo];
                               
                               [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logError:eventInfo:) event:nil parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
                           }
                       }];
    });
}

- (void)logException:(NSException *)exception {
    [self logException:exception topmostContext:nil];
}

- (void)logException:(NSException *)exception topmostContext:(id)topmostContext {
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:exception];

        [self.backendController logError:nil
                               exception:exception
                          topmostContext:topmostContext
                               eventInfo:nil
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged exception name: %@, reason: %@, topmost context: %@", message, exception.reason, topmostContext);
                               
                               // Forwarding calls to kits
                               MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                               [queueParameters addParameter:exception];
                               
                               [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logException:) event:nil parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
                           }
                       }];
    });
}

#pragma mark eCommerce transactions
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (commerceEvent == nil) {
        MPILogError(@"Cannot log nil commerce event!");
        return;
    }
    if (!commerceEvent.timestamp) {
        commerceEvent.timestamp = [NSDate date];
    }
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:commerceEvent];

        [self.backendController logCommerceEvent:commerceEvent
                               completionHandler:^(MPCommerceEvent *commerceEvent, MPExecStatus execStatus) {
                                   if (execStatus == MPExecStatusSuccess) {
                                   } else {
                                       MPILogDebug(@"Failed to log commerce event: %@", commerceEvent);
                                   }
                               }];
        
        // Forwarding calls to kits        
        [[MParticle sharedInstance].kitContainer forwardCommerceEventCall:commerceEvent];
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
    event.customAttributes = eventDictionary;
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(increaseAmount) parameter2:eventName parameter3:eventInfo];
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       if (execStatus == MPExecStatusSuccess) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               // Forwarding calls to kits
                               [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logLTVIncrease:event:)
                                                                                 event:nil
                                                                            parameters:nil
                                                                           messageType:MPMessageTypeUnknown
                                                                              userInfo:nil
                                ];
                            });
                       }
                   }];
}

#pragma mark Extensions
+ (BOOL)registerExtension:(nonnull id<MPExtensionProtocol>)extension {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:extension];
    
    NSAssert(extension != nil, @"Required parameter. It cannot be nil.");
    BOOL registrationSuccessful = NO;
    
    if ([extension conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
        registrationSuccessful = [MPKitContainer registerKit:(id<MPExtensionKitProtocol>)extension];
    }
    
    return registrationSuccessful;
}

#pragma mark Integration attributes
- (nonnull MPKitExecStatus *)setIntegrationAttributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes forKit:(nonnull NSNumber *)integrationId {
    __block MPKitReturnCode returnCode = MPKitReturnCodeSuccess;

    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    
    if (integrationAttributes) {
        dispatch_async(messageQueue, ^{
            [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:attributes parameter2:integrationId];
            
            [[MParticle sharedInstance].persistenceController saveIntegrationAttributes:integrationAttributes];
        });
        
    } else {
        returnCode = MPKitReturnCodeRequirementsNotMet;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:integrationId returnCode:returnCode forwardCount:0];
}

- (nonnull MPKitExecStatus *)clearIntegrationAttributesForKit:(nonnull NSNumber *)integrationId {
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:integrationId];
        
        [[MParticle sharedInstance].persistenceController deleteIntegrationAttributesForIntegrationId:integrationId];
    });

    return [[MPKitExecStatus alloc] initWithSDKCode:integrationId returnCode:MPKitReturnCodeSuccess forwardCount:0];
}

- (nullable NSDictionary *)integrationAttributesForKit:(nonnull NSNumber *)integrationId {
    return [[MParticle sharedInstance].persistenceController fetchIntegrationAttributesForId:integrationId];
}

#pragma mark Kits

- (void)onKitsInitialized:(void(^)(void))block {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:block];
    
    BOOL kitsInitialized = [MParticle sharedInstance].kitContainer.kitsInitialized;
    if (kitsInitialized) {
        block();
    } else {
        [self.kitsInitializedBlocks addObject:[block copy]];
    }
}

- (void)executeKitsInitializedBlocks {
    [MPListenerController.sharedInstance onAPICalled:_cmd];
    
    [self.kitsInitializedBlocks enumerateObjectsUsingBlock:^(void (^block)(void), NSUInteger idx, BOOL * _Nonnull stop) {
        block();
    }];
    [self.kitsInitializedBlocks removeAllObjects];
}

- (BOOL)isKitActive:(nonnull NSNumber *)kitCode {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:kitCode];
    
    return [self.kitActivity isKitActive:kitCode];
}

- (nullable id const)kitInstance:(nonnull NSNumber *)kitCode {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:kitCode];

    return [self.kitActivity kitInstance:kitCode];
}

- (void)kitInstance:(NSNumber *)kitCode completionHandler:(void (^)(id _Nullable kitInstance))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:kitCode parameter2:completionHandler];

    BOOL isValidKitCode = [kitCode isKindOfClass:[NSNumber class]];
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
    [MPListenerController.sharedInstance onAPICalled:_cmd];
    
    return [MParticle sharedInstance].stateMachine.locationManager.backgroundLocationTracking;
}

- (void)setBackgroundLocationTracking:(BOOL)backgroundLocationTracking {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(backgroundLocationTracking)];
    
    [MParticle sharedInstance].stateMachine.locationManager.backgroundLocationTracking = backgroundLocationTracking;
}

- (CLLocation *)location {
    [MPListenerController.sharedInstance onAPICalled:_cmd];
    
    return [MParticle sharedInstance].stateMachine.location;
}

- (void)setLocation:(CLLocation *)location {
    if (![[MParticle sharedInstance].stateMachine.location isEqual:location]) {
        [MParticle sharedInstance].stateMachine.location = location;
        MPILogDebug(@"Set location %@", location);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:location];
            
            // Forwarding calls to kits
            MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
            [queueParameters addParameter:location];
            
            [[MParticle sharedInstance].kitContainer forwardSDKCall:_cmd
                                                              event:nil
                                                         parameters:queueParameters
                                                        messageType:MPMessageTypeEvent
                                                           userInfo:nil
             ];
        });
    }
}

- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter {
    [self beginLocationTracking:accuracy minDistance:distanceFilter authorizationRequest:MPLocationAuthorizationRequestAlways];
}

- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(accuracy) parameter2:@(distanceFilter)];
    
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
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
    [MPListenerController.sharedInstance onAPICalled:_cmd];
    
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
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:networkPerformance];
        
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
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:value];
        
        NSNumber *newValue = [self.backendController incrementSessionAttribute:[MParticle sharedInstance].stateMachine.currentSession key:key byValue:value];
        
        MPILogDebug(@"Session attribute %@ incremented by %@. New value: %@", key, value, newValue);
        
    });
    
    return @0;
}

- (void)setSessionAttribute:(NSString *)key value:(id)value {
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:value];

        MPExecStatus execStatus = [self.backendController setSessionAttribute:[MParticle sharedInstance].stateMachine.currentSession key:key value:value];
        if (execStatus == MPExecStatusSuccess) {
            MPILogDebug(@"Set session attribute - %@:%@", key, value);
        } else {
            MPILogError(@"Could not set session attribute - %@:%@\n Reason: %@", key, value, [self.backendController execStatusDescription:execStatus]);
        }
    });
}

- (void)beginSession {
    NSDate *date = [NSDate date];
    dispatch_async(messageQueue, ^{
        if (self.backendController.session != nil) {
            return;
        }
        [self.backendController beginSessionWithIsManual:YES date:date];
    });
}

- (void)endSession {
    dispatch_async(messageQueue, ^{
        if (self.backendController.session == nil) {
            return;
        }
        [self.backendController endSessionWithIsManual:YES];
    });
}

- (void)upload {
    __weak MParticle *weakSelf = self;
    
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd];
        
        __strong MParticle *strongSelf = weakSelf;
        
        MPExecStatus execStatus = [strongSelf.backendController waitForKitsAndUploadWithCompletionHandler:nil];
        
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(surveyURLWithUserAttributes:)
                                         userAttributes:userAttributes
                                             kitHandler:^(id<MPKitProtocol> kit, NSDictionary *forwardAttributes, MPKitConfiguration *kitConfig) {
                                                 FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:kitConfig];
                                                 surveyURL = [kit surveyURLWithUserAttributes:filteredUser.userAttributes];
                                             }];
    });
    
    return surveyURL;
}

#pragma mark User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification {
    if (!notification.request.content.userInfo) {
        return;
    }
    [[MParticle sharedInstance].appNotificationHandler userNotificationCenter:center willPresentNotification:notification];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response {
    if (!response.notification.request.content.userInfo) {
        return;
    }
    [[MParticle sharedInstance].appNotificationHandler userNotificationCenter:center didReceiveNotificationResponse:response];
}
#endif

#pragma mark Web Views
- (BOOL)isValidBridgeName:(NSString *)bridgeName {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:bridgeName];
    
    if (bridgeName == nil || ![bridgeName isKindOfClass:[NSString class]] || bridgeName.length == 0) {
        return NO;
    }
    
    NSCharacterSet *alphanumericSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
    NSString *result = [bridgeName stringByTrimmingCharactersInSet:alphanumericSet];
    if (![result isEqualToString:@""]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)webviewBridgeValueWithCustomerBridgeName:(NSString *)customerBridgeName {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:customerBridgeName];
    
    if ([self isValidBridgeName:customerBridgeName]) {
        return customerBridgeName;
    }
    
    NSString *kWorkspaceTokenKey = @"wst";
    NSString *serverProvidedValue = [[MPIUserDefaults standardUserDefaults] getConfiguration][kWorkspaceTokenKey];
    if ([self isValidBridgeName:serverProvidedValue]) {
        return serverProvidedValue;
    }
    
    return nil;
}

- (NSString *)bridgeVersion {
    NSString *kBridgeVersion = @"2";
    return kBridgeVersion;
}

#if TARGET_OS_IOS == 1
- (void)initializeWKWebView:(WKWebView *)webView bridgeName:(NSString *)bridgeName {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:webView parameter2:bridgeName];

    NSString *bridgeValue = [self webviewBridgeValueWithCustomerBridgeName:bridgeName];
    if (bridgeValue == nil) {
        MPILogError(@"Unable to initialize webview due to missing or invalid bridgeName");
        return;
    }
    NSString *bridgeVersion = [self bridgeVersion];
    NSString *handlerName = [NSString stringWithFormat:@"mParticle_%@_v%@", bridgeValue, bridgeVersion];
    WKUserContentController *contentController = webView.configuration.userContentController;
    [contentController addScriptMessageHandler:self name:handlerName];
}

// Updates isIOS flag in JS API to true via webview.
- (void)initializeWKWebView:(WKWebView *)webView {
    [self initializeWKWebView:webView bridgeName:nil];
}

// Process web log event that is raised in iOS hybrid apps that are using WKWebView
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:userContentController parameter2:message];
    
    NSString *body = message.body;
    if (body == nil || ![body isKindOfClass:[NSString class]]) {
        MPILogError(@"Unexpected non-string body received from webview bridge");
        return;
    }
    
    @try {
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        if (bodyData == nil) {
            MPILogError(@"Unable to create data from webview bridge body string");
            return;
        }
        
        NSError *error = nil;
        NSDictionary *bodyDictionary = [NSJSONSerialization JSONObjectWithData:bodyData options:kNilOptions error:&error];
        if (error != nil || bodyDictionary == nil || ![bodyDictionary isKindOfClass:[NSDictionary class]]) {
            MPILogError(@"Unable to create dictionary from webview data. error=%@", error);
            return;
        }
        
        NSString *kPathKey = @"path";
        NSString *path = bodyDictionary[kPathKey];
        if (path == nil || ![path isKindOfClass:[NSString class]]) {
            MPILogError(@"Unable to retrieve path from webview dictionary");
            return;
        }
        
        NSString *kValueKey = @"value";
        NSDictionary *value = bodyDictionary[kValueKey];
        if (value == nil || ![value isKindOfClass:[NSDictionary class]]) {
            MPILogError(@"Unable to retrieve value from webview dictionary");
            return;
        }
        
        [self handleWebviewCommand:path dictionary:value];
    } @catch (NSException *e) {
        MPILogError(@"Exception processing WKWebView event: %@", e.reason);
    }
}

// Handle web log event that is raised in iOS hybrid apps
- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:command parameter2:dictionary];
    
    if ([command hasPrefix:kMParticleWebViewPathLogEvent]) {
        MPJavascriptMessageType messageType = (MPJavascriptMessageType)[dictionary[@"EventDataType"] integerValue];
        switch (messageType) {
            case MPJavascriptMessageTypePageEvent: {
                MPEvent *event = [[MPEvent alloc] initWithName:dictionary[@"EventName"] type:(MPEventType)[dictionary[@"EventCategory"] integerValue]];
                event.customAttributes = dictionary[@"EventAttributes"];
                [self logEvent:event];
            }
                break;
                
            case MPJavascriptMessageTypePageView: {
                MPEvent *event = [[MPEvent alloc] initWithName:dictionary[@"EventName"] type:MPEventTypeNavigation];
                event.customAttributes = dictionary[@"EventAttributes"];
                [self logScreenEvent:event];
            }
                break;
                
            case MPJavascriptMessageTypeCommerce: {
                MPCommerceEvent *event = [MPConvertJS MPCommerceEvent:dictionary];
                [self logCommerceEvent:event];
            }
                break;
                
            case MPJavascriptMessageTypeOptOut:
                [self setOptOut:[dictionary[@"OptOut"] boolValue]];
                break;
                
            case MPJavascriptMessageTypeSessionStart:
            case MPJavascriptMessageTypeSessionEnd:
            default:
                break;
        }
    } else if ([command hasPrefix:kMParticleWebViewPathIdentify]) {
        MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:dictionary];
        
        if (!request) {
            MPILogError(@"Unable to create identify request from webview JS dictionary: %@", dictionary);
            return;
        }
        
        [[MParticle sharedInstance].identity identify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
        
        
    } else if ([command hasPrefix:kMParticleWebViewPathLogin]) {
        MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:dictionary];
        
        if (!request) {
            MPILogError(@"Unable to create login request from webview JS dictionary: %@", dictionary);
            return;
        }
        
        [[MParticle sharedInstance].identity login:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathLogout]) {
        MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:dictionary];
        
        if (!request) {
            MPILogError(@"Unable to create logout request from webview JS dictionary: %@", dictionary);
            return;
        }
        
        [[MParticle sharedInstance].identity logout:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathModify]) {
        MPIdentityApiRequest *request = [MPConvertJS MPIdentityApiRequest:dictionary];
        
        if (!request) {
            MPILogError(@"Unable to create modify request from webview JS dictionary: %@", dictionary);
            return;
        }
        
        [[MParticle sharedInstance].identity modify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathSetUserTag]) {
        [self.identity.currentUser setUserTag:dictionary[@"key"]];
    } else if ([command hasPrefix:kMParticleWebViewPathRemoveUserTag]) {
        [self.identity.currentUser removeUserAttribute:dictionary[@"key"]];
    } else if ([command hasPrefix:kMParticleWebViewPathSetUserAttribute]) {
        [self.identity.currentUser setUserAttribute:dictionary[@"key"] value:dictionary[@"value"]];
    } else if ([command hasPrefix:kMParticleWebViewPathRemoveUserAttribute]) {
        [self.identity.currentUser removeUserAttribute:dictionary[@"key"]];
    } else if ([command hasPrefix:kMParticleWebViewPathSetSessionAttribute]) {
        [self setSessionAttribute:dictionary[@"key"] value:dictionary[@"value"]];
    }
}

#pragma mark - Manual Notification logging
/**
 Logs a Notification event for a notification that has been reviewed but not acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationReceivedWithUserInfo:(nonnull NSDictionary *)userInfo {
    if (userInfo == nil) {
        return;
    }
    [self logNotificationWithUserInfo:userInfo behavior:MPUserNotificationBehaviorReceived];
}

/**
 Logs a Notification event for a notification that has been reviewed and acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationOpenedWithUserInfo:(nonnull NSDictionary *)userInfo {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:userInfo];
    
    if (userInfo == nil) {
        return;
    }
    [self logNotificationWithUserInfo:userInfo behavior:MPUserNotificationBehaviorRead | MPUserNotificationBehaviorDirectOpen];
}

/**
 Logs a Notification event. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only submit Notification events manually:
 */
- (void)logNotificationWithUserInfo:(nonnull NSDictionary *)userInfo behavior:(MPUserNotificationBehavior)behavior {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:userInfo parameter2:@(behavior)];
    
    UIApplicationState state = [MPApplication sharedUIApplication].applicationState;
    
    NSString *stateString = state == UIApplicationStateActive ? kMPPushNotificationStateForeground : kMPPushNotificationStateBackground;
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:userInfo
                                                                                       actionIdentifier:nil
                                                                                                  state:stateString
                                                                                               behavior:behavior
                                                                                                   mode:MPUserNotificationModeRemote];
    
    [self.backendController logUserNotification:userNotification];
}
#endif

@end
