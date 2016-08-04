//
//  mParticle.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "mParticle.h"
#import "MPKitContainer.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "MPBackendController.h"
#import "NSUserDefaults+mParticle.h"
#import "MPStateMachine.h"
#import "MPKitFilter.h"
#import "MPDevice.h"
#import "MPSegment.h"
#import "MPNetworkPerformance.h"
#import "MPUserSegments+Setters.h"
#import "NSURLSession+mParticle.h"
#import "MPNotificationController.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPCommerce.h"
#import "MPProduct+Dictionary.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPEvent+MessageType.h"
#import "MPKitExecStatus.h"
#import "MPAppNotificationHandler.h"
#import "MPEvent.h"

#import "MPMediaTrack.h"
#import "MPMediaMetadataDigitalAudio.h"
#import "MPMediaMetadataDPR.h"
#import "MPMediaMetadataOCR.h"
#import "MPMediaMetadataTVR.h"

#if TARGET_OS_IOS == 1
    #import "MPLocationManager.h"

    #if defined(MP_CRASH_REPORTER)
        #import "MPExceptionHandler.h"
    #endif
#endif

static NSArray *eventTypeStrings;

NSString *const kMPEventNameLogTransaction = @"Purchase";
NSString *const kMPEventNameLTVIncrease = @"Increase LTV";
NSString *const kMParticleFirstRun = @"firstrun";
NSString *const kMPMethodName = @"$MethodName";
NSString *const kMPStateKey = @"state";

@interface MParticle() <MPBackendControllerDelegate> {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
    MPExceptionHandler *exceptionHandler;
#endif
    NSNumber *privateOptOut;
    BOOL isLoggingUncaughtExceptions;
}

@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong, nullable) NSMutableDictionary *configSettings;

@end

#pragma mark - MParticle
@implementation MParticle

@synthesize commerce = _commerce;
@synthesize optOut = _optOut;

+ (void)initialize {
    eventTypeStrings = @[@"Reserved - Not Used", @"Navigation", @"Location", @"Search", @"Transaction", @"UserContent", @"UserPreference", @"Social", @"Other"];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _commerce = nil;
    privateOptOut = nil;
    isLoggingUncaughtExceptions = NO;
    
    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
    
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
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

#pragma mark Private accessors
- (MPBackendController *)backendController {
    if (_backendController) {
        return _backendController;
    }
    
    _backendController = [[MPBackendController alloc] initWithDelegate:self];
    
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
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"backendController.session"]) {
#if defined(MP_CRASH_REPORTER) && TARGET_OS_IOS == 1
        MPSession *session = change[NSKeyValueChangeNewKey];
        
        if (exceptionHandler) {
            exceptionHandler.session = session;
        } else {
            exceptionHandler = [[MPExceptionHandler alloc] initWithSession:session];
        }
        
        if (isLoggingUncaughtExceptions && ![MPExceptionHandler isHandlingExceptions]) {
            [exceptionHandler beginUncaughtExceptionLogging];
        }
#endif
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Notification handlers
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    NSDictionary *jailbrokenInfo = [MPDevice jailbrokenInfo];
    
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setKitAttribute:value:)
                                              event:nil
                                        messageType:MPMessageTypeUnknown
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit setKitAttribute:MPKitAttributeJailbrokenKey value:jailbrokenInfo];
                                         }];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
    self.configSettings = nil;
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [NSURLSession freeResources];
}

#pragma mark MPBackendControllerDelegate methods
- (void)sessionDidBegin:(MPSession *)session {
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(beginSession)
                                              event:nil
                                        messageType:MPMessageTypeSessionStart
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit beginSession];
                                         }];
}

- (void)sessionDidEnd:(MPSession *)session {
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(endSession)
                                              event:nil
                                        messageType:MPMessageTypeSessionEnd
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit endSession];
                                         }];
}

#pragma mark MPBackendControllerDelegate methods
- (void)forwardLogInstall {
    [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                              event:nil
                                        messageType:MPMessageTypeUnknown
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit logInstall];
                                         }];
}

- (void)forwardLogUpdate {
    [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                              event:nil
                                        messageType:MPMessageTypeUnknown
                                           userInfo:nil
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit logUpdate];
                                         }];
}

#pragma mark - Public accessors and methods
- (MPBags *)bags {
    return [MPStateMachine sharedInstance].bags;
}

- (MPCommerce *)commerce {
    if (_commerce) {
        return _commerce;
    }
    
    _commerce = [[MPCommerce alloc] init];
    return _commerce;
}

- (void)setDebugMode:(BOOL)debugMode {
    [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                              event:nil
                                        messageType:MPMessageTypeUnknown
                                           userInfo:@{kMPStateKey:@(debugMode)}
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit setDebugMode:debugMode];
                                         }];
}

- (BOOL)consoleLogging {
    return [MPStateMachine sharedInstance].consoleLogging == MPConsoleLoggingDisplay;
}

- (void)setConsoleLogging:(BOOL)consoleLogging {
    if ([MPStateMachine environment] == MPEnvironmentDevelopment) {
        [MPStateMachine sharedInstance].consoleLogging = consoleLogging ? MPConsoleLoggingDisplay : MPConsoleLoggingSuppress;
    }
    
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setDebugMode:)
                                              event:nil
                                        messageType:MPMessageTypeUnknown
                                           userInfo:@{kMPStateKey:@(consoleLogging)}
                                         kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                             *execStatus = [kit setDebugMode:consoleLogging];
                                         }];
}

- (MPEnvironment)environment {
    return [MPStateMachine environment];
}

- (MPILogLevel)logLevel {
    return [MPStateMachine sharedInstance].logLevel;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    if ([MPStateMachine environment] == MPEnvironmentDevelopment) {
        [MPStateMachine sharedInstance].logLevel = logLevel;
    }
}

- (BOOL)measuringNetworkPerformance {
    return [NSURLSession methodsSwizzled];
}

- (BOOL)optOut {
    if (!_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        return NO;
    }
    
    return [MPStateMachine sharedInstance].optOut;
}

- (void)setOptOut:(BOOL)optOut {
    if (privateOptOut && _optOut == optOut) {
        return;
    }
    
    _optOut = optOut;
    privateOptOut = @(optOut);
    __weak MParticle *weakSelf = self;
    
    [self.backendController setOptOut:optOut
                              attempt:0
                    completionHandler:^(BOOL optOut, MPExecStatus execStatus) {
                        __strong MParticle *strongSelf = weakSelf;
                        
                        if (execStatus == MPExecStatusSuccess) {
                            MPILogDebug(@"Set Opt Out: %d", optOut);
                            
                            // Forwarding calls to kits
                            [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setOptOut:)
                                                                      event:nil
                                                                messageType:MPMessageTypeOptOut
                                                                   userInfo:@{kMPStateKey:@(optOut)}
                                                                 kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                     *execStatus = [kit setOptOut:optOut];
                                                                 }];
                        } else if (execStatus == MPExecStatusDelayedExecution) {
                            MPILogWarning(@"Delayed Set Opt Out: %@\n Reason: %@", optOut ? @"YES" : @"NO", [strongSelf.backendController execStatusDescription:execStatus]);
                        } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                            MPILogError(@"Failed Setting Opt Out: %@\n Reason: %@", optOut ? @"YES" : @"NO", [strongSelf.backendController execStatusDescription:execStatus]);
                        }
                    }];
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

- (nullable NSDictionary <NSString *, id> *)userAttributes {
    NSDictionary *userAttributes = [self.backendController.userAttributes copy];
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
    NSString *appAPIKey;
    NSString *appSecret;
    
    if (self.configSettings) {
        appAPIKey = self.configSettings[kMPConfigApiKey];
        appSecret = self.configSettings[kMPConfigSecret];
    }
    
    [self startWithKey:appAPIKey secret:appSecret installationType:MPInstallationTypeAutodetect environment:MPEnvironmentAutoDetect proxyAppDelegate:YES];
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret {
    [self startWithKey:apiKey secret:secret installationType:MPInstallationTypeAutodetect environment:MPEnvironmentAutoDetect proxyAppDelegate:YES];
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment {
    [self startWithKey:apiKey secret:secret installationType:installationType environment:environment proxyAppDelegate:YES];
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment proxyAppDelegate:(BOOL)proxyAppDelegate {
    NSAssert(apiKey && secret, @"mParticle SDK must be started with an apiKey and secret.");
    NSAssert([apiKey isKindOfClass:[NSString class]] && [secret isKindOfClass:[NSString class]], @"mParticle SDK apiKey and secret must be of type string.");
    NSAssert(apiKey.length > 0 && secret.length > 0, @"mParticle SDK apiKey and secret cannot be an empty string.");
    NSAssert((NSNull *)apiKey != [NSNull null] && (NSNull *)secret != [NSNull null], @"mParticle SDK apiKey and secret cannot be null.");
    
    __weak MParticle *weakSelf = self;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL firstRun = userDefaults[kMParticleFirstRun] == nil;
    BOOL registerForSilentNotifications = YES;
    _proxiedAppDelegate = proxyAppDelegate;
    
    if (self.configSettings) {
        NSNumber *configRegisterForSilentNotifications = self.configSettings[kMPConfigRegisterForSilentNotifications];
        
        if (configRegisterForSilentNotifications) {
            registerForSilentNotifications = [configRegisterForSilentNotifications boolValue];
        }
    }
    
    [self.backendController startWithKey:apiKey
                                  secret:secret
                                firstRun:firstRun
                        installationType:installationType
                        proxyAppDelegate:proxyAppDelegate
          registerForSilentNotifications:registerForSilentNotifications
                       completionHandler:^{
                           __strong MParticle *strongSelf = weakSelf;
                           
                           if (!strongSelf) {
                               return;
                           }
                           
                           if (firstRun) {
                               userDefaults[kMParticleFirstRun] = @NO;
                               [userDefaults synchronize];
                           }
                           
                           [MPStateMachine setEnvironment:environment];
                           
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
                       }];
}

#pragma mark Application notifications
#if TARGET_OS_IOS == 1
- (NSData *)pushNotificationToken {
    return [MPNotificationController deviceToken];
}

- (void)setPushNotificationToken:(NSData *)pushNotificationToken {
    [MPNotificationController setDeviceToken:pushNotificationToken];
}

- (void)didReceiveLocalNotification:(UILocalNotification *)notification {
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

- (void)handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification {
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
    NSAssert(self.backendController.initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Cannot fetch timed events prior to starting the mParticle SDK.\n****\n");
    
    if (self.backendController.initializationStatus != MPInitializationStatusStarted || self.backendController.eventSet.count == 0) {
        return nil;
    } else {
        return self.backendController.eventSet;
    }
}

- (void)beginTimedEvent:(MPEvent *)event {
    __weak MParticle *weakSelf = self;
    
    [self.backendController beginTimedEvent:event
                                    attempt:0
                          completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                              __strong MParticle *strongSelf = weakSelf;
                              
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
                              } else if (execStatus == MPExecStatusDelayedExecution) {
                                  MPILogWarning(@"Delayed timed event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                              } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                  MPILogError(@"Could not begin timed event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                              }
                          }];
}

- (void)endTimedEvent:(MPEvent *)event {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       __strong MParticle *strongSelf = weakSelf;
                       
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
                       } else if (execStatus == MPExecStatusDelayedExecution) {
                           MPILogWarning(@"Delayed timed event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                           MPILogError(@"Could not end timed event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       }
                   }];
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    return [self.backendController eventWithName:eventName];
}

- (void)logEvent:(MPEvent *)event {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       __strong MParticle *strongSelf = weakSelf;
                       
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
                       } else if (execStatus == MPExecStatusDelayedExecution) {
                           MPILogWarning(@"Delayed event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                           MPILogError(@"Failed logging event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       }
                   }];
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
    __weak MParticle *weakSelf = self;
    
    [self.backendController logScreen:event
                              attempt:0
                    completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                        __strong MParticle *strongSelf = weakSelf;
                        
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
                        } else if (execStatus == MPExecStatusDelayedExecution) {
                            MPILogWarning(@"Delayed screen event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                        } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                            MPILogError(@"Failed logging screen event: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                        }
                    }];
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

#pragma mark Deep linking
- (void)checkForDeferredDeepLinkWithCompletionHandler:(void(^)(NSDictionary<NSString *, NSString *> * linkInfo, NSError *error))completionHandler {
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(checkForDeferredDeepLinkWithCompletionHandler:) kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitExecStatus * __autoreleasing  _Nonnull * _Nonnull execStatus) {
        [kit checkForDeferredDeepLinkWithCompletionHandler:completionHandler];
    }];
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
    
    __weak MParticle *weakSelf = self;
    
    [self.backendController leaveBreadcrumb:event
                                    attempt:0
                          completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                              __strong MParticle *strongSelf = weakSelf;
                              
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
                              } else if (execStatus == MPExecStatusDelayedExecution) {
                                  MPILogWarning(@"Delayed breadcrumb: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                              } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                  MPILogError(@"Could not leave breadcrumb: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                              }
                          }];
}

- (void)logError:(NSString *)message {
    [self logError:message eventInfo:nil];
}

- (void)logError:(NSString *)message eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!message) {
        MPILogError(@"'message' is required for %@", NSStringFromSelector(_cmd));
        return;
    }
    
    __weak MParticle *weakSelf = self;
    
    [self.backendController logError:message
                           exception:nil
                      topmostContext:nil
                           eventInfo:eventInfo
                             attempt:0
                   completionHandler:^(NSString *message, MPExecStatus execStatus) {
                       __strong MParticle *strongSelf = weakSelf;
                       
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
                       } else if (execStatus == MPExecStatusDelayedExecution) {
                           MPILogWarning(@"Delayed log error mesage: %@\n Reason: %@", message, [strongSelf.backendController execStatusDescription:execStatus]);
                       } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                           MPILogError(@"Could not log error: %@\n Reason: %@", message, [strongSelf.backendController execStatusDescription:execStatus]);
                       }
                   }];
}

- (void)logException:(NSException *)exception {
    [self logException:exception topmostContext:nil];
}

- (void)logException:(NSException *)exception topmostContext:(id)topmostContext {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logError:nil
                           exception:exception
                      topmostContext:topmostContext
                           eventInfo:nil
                             attempt:0
                   completionHandler:^(NSString *message, MPExecStatus execStatus) {
                       __strong MParticle *strongSelf = weakSelf;
                       
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
                       } else if (execStatus == MPExecStatusDelayedExecution) {
                           MPILogWarning(@"Delayed log exception name: %@\n Reason: %@", message, [strongSelf.backendController execStatusDescription:execStatus]);
                       } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                           MPILogError(@"Could not exception name: %@\n Reason: %@", message, [strongSelf.backendController execStatusDescription:execStatus]);
                       }
                   }];
}

#pragma mark eCommerce transactions
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logCommerceEvent:commerceEvent
                                     attempt:0
                           completionHandler:^(MPCommerceEvent *commerceEvent, MPExecStatus execStatus) {
                               __strong MParticle *strongSelf = weakSelf;
                               
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
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed commerce event: %@\n Reason: %@", commerceEvent, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Failed logging commerce event: %@\n Reason: %@", commerceEvent, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
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
    
    __weak MParticle *weakSelf = self;
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       __strong MParticle *strongSelf = weakSelf;
                       
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
                       } else if (execStatus == MPExecStatusDelayedExecution) {
                           MPILogWarning(@"Delayed LTV Increase: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                           MPILogError(@"Failed Increasing LTV: %@\n Reason: %@", event, [strongSelf.backendController execStatusDescription:execStatus]);
                       }
                   }];
}

#pragma mark Extensions
+ (BOOL)registerExtension:(nonnull id<MPExtensionProtocol>)extension {
    NSAssert(extension != nil, @"Required parameter. It cannot be nil.");
    BOOL registrationSuccessful = NO;
    
    if ([extension conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
        registrationSuccessful = [MPKitContainer registerKit:(id<MPExtensionKitProtocol>)extension];
        
        MPILogDebug(@"Registered kit extension: %@", extension);
    } else {
        MPILogError(@"Could not register extension: %@", extension);
    }
    
    return registrationSuccessful;
}

#pragma mark Kits
- (nullable id const)kitInstance:(nonnull NSNumber *)kitCode {
    if (self.backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot retrieve kit instance. mParticle SDK is not initialized yet.");
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol> kitRegister = [[[[MPKitContainer sharedInstance] activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    
    return [kitRegister.wrapperInstance respondsToSelector:@selector(providerKitInstance)] ? [kitRegister.wrapperInstance providerKitInstance] : nil;
}

- (BOOL)isKitActive:(nonnull NSNumber *)kitCode {
    if (self.backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot verify whether kit is active. mParticle SDK is not initialized yet.");
        return NO;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol> kitRegister = [[[[MPKitContainer sharedInstance] activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    
    return kitRegister != nil;
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
    return [MPStateMachine sharedInstance].locationManager.location;
}

- (void)setLocation:(CLLocation *)location {
    [MPStateMachine sharedInstance].locationManager.location = location;
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

#pragma mark Media Tracking
- (void)beginPlaying:(MPMediaTrack *)mediaTrack {
    __weak MParticle *weakSelf = self;
    
    [self.backendController beginPlaying:mediaTrack
                                 attempt:0
                       completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {
                           __strong MParticle *strongSelf = weakSelf;
                           
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Began playing media track: %@", mediaTrack.channel);
                               
                               // Forwarding calls to kits
                               [[MPKitContainer sharedInstance] forwardSDKCall:@selector(beginPlaying:)
                                                                         event:nil
                                                                   messageType:MPMessageTypeEvent
                                                                      userInfo:nil
                                                                    kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                        *execStatus = [kit beginPlaying:mediaTrack];
                                                                    }];
                           } else if (execStatus == MPExecStatusDelayedExecution) {
                               MPILogWarning(@"Delayed begin playing: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                           } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                               MPILogError(@"Could not begin playing media track: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                           }
                       }];
}

- (void)discardMediaTrack:(MPMediaTrack *)mediaTrack {
    MPExecStatus execStatus = [self.backendController discardMediaTrack:mediaTrack];
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Discarded media track: %@", mediaTrack.channel);
    } else {
        MPILogError(@"Could not discard media track: %@\n Reason: %@", mediaTrack, [self.backendController execStatusDescription:execStatus]);
    }
}

- (void)endPlaying:(MPMediaTrack *)mediaTrack {
    __weak MParticle *weakSelf = self;
    
    [self.backendController endPlaying:mediaTrack
                               attempt:0
                     completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {
                         __strong MParticle *strongSelf = weakSelf;
                         
                         if (execStatus == MPExecStatusSuccess) {
                             MPILogDebug(@"Ended playing media track: %@", mediaTrack.channel);
                             
                             // Forwarding calls to kits
                             [[MPKitContainer sharedInstance] forwardSDKCall:@selector(endPlaying:)
                                                                       event:nil
                                                                 messageType:MPMessageTypeEvent
                                                                    userInfo:nil
                                                                  kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                      *execStatus = [kit endPlaying:mediaTrack];
                                                                  }];
                         } else if (execStatus == MPExecStatusDelayedExecution) {
                             MPILogWarning(@"Delayed end playing: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                         } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                             MPILogError(@"Could not end playing media track: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                         }
                     }];
}

- (void)logMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logMetadataWithMediaTrack:mediaTrack
                                              attempt:0
                                    completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {
                                        __strong MParticle *strongSelf = weakSelf;
                                        
                                        if (execStatus == MPExecStatusSuccess) {
                                            MPILogDebug(@"Logged metadata with media track: %@", mediaTrack.channel);
                                            
                                            // Forwarding calls to kits
                                            [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logMetadataWithMediaTrack:)
                                                                                      event:nil
                                                                                messageType:MPMessageTypeEvent
                                                                                   userInfo:nil
                                                                                 kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                                     *execStatus = [kit logMetadataWithMediaTrack:mediaTrack];
                                                                                 }];
                                        } else if (execStatus == MPExecStatusDelayedExecution) {
                                            MPILogWarning(@"Delayed log metadata: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                        } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                            MPILogError(@"Could not log metadata: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                        }
                                    }];
}

- (void)logTimedMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack {
    __weak MParticle *weakSelf = self;
    
    [self.backendController logTimedMetadataWithMediaTrack:mediaTrack
                                                   attempt:0
                                         completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {
                                             __strong MParticle *strongSelf = weakSelf;
                                             
                                             if (execStatus == MPExecStatusSuccess) {
                                                 MPILogDebug(@"Logged timed metadata with media track: %@", mediaTrack.channel);
                                                 
                                                 // Forwarding calls to kits
                                                 [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logTimedMetadataWithMediaTrack:)
                                                                                           event:nil
                                                                                     messageType:MPMessageTypeEvent
                                                                                        userInfo:nil
                                                                                      kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                                          *execStatus = [kit logTimedMetadataWithMediaTrack:mediaTrack];
                                                                                      }];
                                             } else if (execStatus == MPExecStatusDelayedExecution) {
                                                 MPILogWarning(@"Delayed log timed metadata: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                             } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                                 MPILogError(@"Could not log timed metadata: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                             }
                                         }];
}

- (NSArray *)mediaTracks {
    return [self.backendController mediaTracks];
}

- (MPMediaTrack *)mediaTrackWithChannel:(NSString *)channel {
    return [self.backendController mediaTrackWithChannel:channel];
}

- (void)updatePlaybackPosition:(MPMediaTrack *)mediaTrack {
    __weak MParticle *weakSelf = self;
    
    [self.backendController updatePlaybackPosition:mediaTrack
                                           attempt:0
                                 completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {
                                     __strong MParticle *strongSelf = weakSelf;
                                     
                                     if (execStatus == MPExecStatusSuccess) {
                                         MPILogDebug(@"Updated media track with channel: %@, playback position %.1f seconds, playback rate: %.1f", mediaTrack.channel, mediaTrack.playbackPosition, mediaTrack.playbackRate);
                                         
                                         // Forwarding calls to kits
                                         [[MPKitContainer sharedInstance] forwardSDKCall:@selector(updatePlaybackPosition:)
                                                                                   event:nil
                                                                             messageType:MPMessageTypeEvent
                                                                                userInfo:nil
                                                                              kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                                  *execStatus = [kit updatePlaybackPosition:mediaTrack];
                                                                              }];
                                     } else if (execStatus == MPExecStatusDelayedExecution) {
                                         MPILogWarning(@"Delayed update playback position: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                     } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                         MPILogError(@"Could not update playback position: %@\n Reason: %@", mediaTrack, [strongSelf.backendController execStatusDescription:execStatus]);
                                     }
                                 }];
}

#pragma mark Network performance
- (void)beginMeasuringNetworkPerformance {
    if (self.backendController.initializationStatus == MPInitializationStatusStarted) {
        if ([[MPStateMachine sharedInstance].networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceFalse]) {
            return;
        }
        
        [NSURLSession swizzleMethods];
    } else if (self.backendController.initializationStatus == MPInitializationStatusStarting) {
        __weak MParticle *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MParticle *strongSelf = weakSelf;
            [strongSelf beginMeasuringNetworkPerformance];
        });
    }
}

- (void)endMeasuringNetworkPerformance {
    if (self.backendController.initializationStatus == MPInitializationStatusStarted) {
        if ([[MPStateMachine sharedInstance].networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceTrue]) {
            return;
        }
        
        [NSURLSession restoreMethods];
    } else if (self.backendController.initializationStatus == MPInitializationStatusStarting) {
        __weak MParticle *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MParticle *strongSelf = weakSelf;
            [strongSelf endMeasuringNetworkPerformance];
        });
    }
}

- (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url {
    [NSURLSession excludeURLFromNetworkPerformanceMeasuring:url];
}

- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:urlRequest networkMeasurementMode:MPNetworkMeasurementModePreserveQuery];
    networkPerformance.httpMethod = httpMethod;
    networkPerformance.startTime = startTime;
    networkPerformance.elapsedTime = duration;
    networkPerformance.bytesOut = bytesSent;
    networkPerformance.bytesIn = bytesReceived;
    
    __weak MParticle *weakSelf = self;
    
    [self.backendController logNetworkPerformanceMeasurement:networkPerformance
                                                     attempt:0
                                           completionHandler:^(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus) {
                                               __strong MParticle *strongSelf = weakSelf;
                                               
                                               if (execStatus == MPExecStatusSuccess) {
                                                   MPILogDebug(@"Logged network performance measurement");
                                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                                   MPILogWarning(@"Delayed network performance measurement\n Reason: %@", [strongSelf.backendController execStatusDescription:execStatus]);
                                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                                   MPILogError(@"Could not log network performance measurement\n Reason: %@", [strongSelf.backendController execStatusDescription:execStatus]);
                                               }
                                           }];
}

- (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString {
    [NSURLSession preserveQueryMeasuringNetworkPerformance:queryString];
}

- (void)resetNetworkPerformanceExclusionsAndFilters {
    [NSURLSession resetNetworkPerformanceExclusionsAndFilters];
}

#pragma mark Session management
- (NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value {
    if (!_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot increment session attribute. SDK is not initialized yet.");
        return nil;
    }
    
    NSNumber *newValue = [self.backendController incrementSessionAttribute:[MPStateMachine sharedInstance].currentSession key:key byValue:value];
    
    MPILogDebug(@"Session attribute %@ incremented by %@. New value: %@", key, value, newValue);
    
    return newValue;
}

- (void)setSessionAttribute:(NSString *)key value:(id)value {
    if (!_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot set session attribute. SDK is not initialized yet.");
        return;
    }
    
    MPExecStatus execStatus = [self.backendController setSessionAttribute:[MPStateMachine sharedInstance].currentSession key:key value:value];
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Set session attribute - %@:%@", key, value);
    } else {
        MPILogError(@"Could not set session attribute - %@:%@\n Reason: %@", key, value, [self.backendController execStatusDescription:execStatus]);
    }
}

- (void)upload {
    NSAssert(_backendController.initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Upload cannot be done prior to starting the mParticle SDK.\n****\n");
    
    __weak MParticle *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MParticle *strongSelf = weakSelf;
        
        MPExecStatus execStatus = [strongSelf.backendController upload];
        
        if (execStatus == MPExecStatusSuccess) {
            MPILogDebug(@"Forcing Upload");
        } else if (execStatus == MPExecStatusDelayedExecution) {
            MPILogWarning(@"Delayed upload: %@", [strongSelf.backendController execStatusDescription:execStatus]);
        } else {
            MPILogError(@"Could not upload data: %@", [strongSelf.backendController execStatusDescription:execStatus]);
        }
    });
}

#pragma mark Surveys
- (NSString *)surveyURL:(MPSurveyProvider)surveyProvider {
    if (surveyProvider != MPSurveyProviderForesee || !_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        return nil;
    }
    
    NSMutableDictionary *userAttributes = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
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
                                         kitHandler:^(id<MPKitProtocol> kit, NSDictionary *forwardAttributes) {
                                             surveyURL = [kit surveyURLWithUserAttributes:forwardAttributes];
                                         }];
    
    return surveyURL;
}

#pragma mark User Identity
- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    if (!_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot increment user attribute. SDK is not initialized yet.");
        return nil;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return nil;
    }
    
    NSNumber *newValue = [self.backendController incrementUserAttribute:key byValue:value];
    
    MPILogDebug(@"User attribute %@ incremented by %@. New value: %@", key, value, newValue);
    
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(incrementUserAttribute:byValue:)
                                   userAttributeKey:key
                                              value:value
                                         kitHandler:^(id<MPKitProtocol> kit) {
                                             [kit incrementUserAttribute:key byValue:value];
                                         }];
    
    return newValue;
}

- (void)logout {
    __weak MParticle *weakSelf = self;
    
    [self.backendController profileChange:MPProfileChangeLogout
                                  attempt:0
                        completionHandler:^(MPProfileChange profile, MPExecStatus execStatus) {
                            __strong MParticle *strongSelf = weakSelf;
                            
                            if (execStatus == MPExecStatusSuccess) {
                                MPILogDebug(@"Logged out");
                                
                                // Forwarding calls to kits
                                [[MPKitContainer sharedInstance] forwardSDKCall:@selector(logout)
                                                                          event:nil
                                                                    messageType:MPMessageTypeProfile
                                                                       userInfo:nil
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
                                                                         *execStatus = [kit logout];
                                                                     }];
                            } else if (execStatus == MPExecStatusDelayedExecution) {
                                MPILogWarning(@"Delayed logout\n Reason: %@", [strongSelf.backendController execStatusDescription:execStatus]);
                            } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                MPILogError(@"Failed logout\n Reason: %@", [strongSelf.backendController execStatusDescription:execStatus]);
                            }
                        }];
}

- (void)setUserAttribute:(NSString *)key value:(id)value {
    __weak MParticle *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                       value:value
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticle *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   if (value) {
                                       MPILogDebug(@"Set user attribute - %@:%@", key, value);
                                   } else {
                                       MPILogDebug(@"Reset user attribute - %@", key);
                                   }
                                   
                                   // Forwarding calls to kits
                                   if ((value == nil) || [value isKindOfClass:[NSString class]]) {
                                       if (((NSString *)value).length > 0) {
                                           [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                                                          userAttributeKey:key
                                                                                     value:value
                                                                                kitHandler:^(id<MPKitProtocol> kit) {
                                                                                    [kit setUserAttribute:key value:value];
                                                                                }];
                                       } else {
                                           [[MPKitContainer sharedInstance] forwardSDKCall:@selector(removeUserAttribute:)
                                                                          userAttributeKey:key
                                                                                     value:value
                                                                                kitHandler:^(id<MPKitProtocol> kit) {
                                                                                    [kit removeUserAttribute:key];
                                                                                }];
                                       }
                                   } else {
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                                                      userAttributeKey:key
                                                                                 value:value
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                [kit setUserAttribute:key value:value];
                                                                            }];
                                   }
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user attribute: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user attribute - %@:%@\n Reason: %@", key, value, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values {
    __weak MParticle *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                      values:values
                                     attempt:0
                           completionHandler:^(NSString *key, NSArray *values, MPExecStatus execStatus) {
                               __strong MParticle *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   if (values) {
                                       MPILogDebug(@"Set user attribute values - %@:%@", key, values);
                                   } else {
                                       MPILogDebug(@"Reset user attribute - %@", key);
                                   }
                                   
                                   // Forwarding calls to kits
                                   if (values) {
                                       SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
                                       SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);

                                       [[MPKitContainer sharedInstance] forwardSDKCall:setUserAttributeListSelector
                                                                      userAttributeKey:key
                                                                                 value:values
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                if ([kit respondsToSelector:setUserAttributeListSelector]) {
                                                                                    [kit setUserAttribute:key values:values];
                                                                                } else if ([kit respondsToSelector:setUserAttributeSelector]) {
                                                                                    NSString *csvValues = [values componentsJoinedByString:@","];
                                                                                    [kit setUserAttribute:key value:csvValues];
                                                                                }
                                                                            }];
                                   } else {
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(removeUserAttribute:)
                                                                      userAttributeKey:key
                                                                                 value:values
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                [kit removeUserAttribute:key];
                                                                            }];
                                   }
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user attribute values: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user attribute values - %@:%@\n Reason: %@", key, values, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    __weak MParticle *weakSelf = self;
    
    [self.backendController setUserIdentity:identityString
                               identityType:identityType
                                    attempt:0
                          completionHandler:^(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                              __strong MParticle *strongSelf = weakSelf;
                              
                              if (execStatus == MPExecStatusSuccess) {
                                  MPILogDebug(@"Set user identity: %@", identityString);
                                  
                                  // Forwarding calls to kits
                                  [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserIdentity:identityType:)
                                                                     userIdentity:identityString
                                                                     identityType:identityType
                                                                       kitHandler:^(id<MPKitProtocol> kit) {
                                                                           [kit setUserIdentity:identityString identityType:identityType];
                                                                       }];
                              } else if (execStatus == MPExecStatusDelayedExecution) {
                                  MPILogWarning(@"Delayed set user identity: %@\n Reason: %@", identityString, [strongSelf.backendController execStatusDescription:execStatus]);
                              } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                  MPILogError(@"Could not set user identity: %@\n Reason: %@", identityString, [strongSelf.backendController execStatusDescription:execStatus]);
                              }
                          }];
}

- (void)setUserTag:(NSString *)tag {
    __weak MParticle *weakSelf = self;
    
    [self.backendController setUserAttribute:tag
                                       value:nil
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticle *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   MPILogDebug(@"Set user tag - %@", tag);
                                   
                                   // Forwarding calls to kits
                                   [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserTag:)
                                                                  userAttributeKey:tag
                                                                             value:nil
                                                                        kitHandler:^(id<MPKitProtocol> kit) {
                                                                            [kit setUserTag:tag];
                                                                        }];
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user tag: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user tag - %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)removeUserAttribute:(NSString *)key {
    __weak MParticle *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                       value:@""
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticle *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   MPILogDebug(@"Removed user attribute - %@", key);
                                   
                                   // Forwarding calls to kits
                                   [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                                  userAttributeKey:key
                                                                             value:nil
                                                                        kitHandler:^(id<MPKitProtocol> kit) {
                                                                            [kit removeUserAttribute:key];
                                                                        }];
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed removing user attribute: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not remove user attribute - %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

#pragma mark User Segments
- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler {
    MPExecStatus execStatus = [self.backendController fetchSegments:timeout
                                                         endpointId:endpointId
                                                  completionHandler:^(NSArray *segments, NSTimeInterval elapsedTime, NSError *error) {
                                                      if (!segments) {
                                                          completionHandler(nil, error);
                                                          return;
                                                      }
                                                      
                                                      MPUserSegments *userSegments = [[MPUserSegments alloc] initWithSegments:segments];
                                                      completionHandler(userSegments, error);
                                                  }];
    
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Fetching user segments");
    } else {
        MPILogError(@"Could not fetch user segments: %@", [self.backendController execStatusDescription:execStatus]);
    }
}

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
        NSString *paramStr = [[[requestUrl pathComponents] objectAtIndex:1] stringByRemovingPercentEncoding];
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
                    
                case MPJavascriptMessageTypeOptOut:
                    [self setOptOut:[eventDictionary[@"OptOut"] boolValue]];
                    break;
                    
                case MPJavascriptMessageTypeSessionStart:
                case MPJavascriptMessageTypeSessionEnd:
                default:
                    break;
            }
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetUserIdentity]) {
            [self setUserIdentity:eventDictionary[@"Identity"] identityType:(MPUserIdentity)[eventDictionary[@"Type"] integerValue]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetUserTag]) {
            [self setUserTag:eventDictionary[@"key"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathRemoveUserTag]) {
            //TODO: implement removeUserTag
            //[self removeUserTag:eventDictionary[@"key"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetUserAttribute]) {
            [self setUserAttribute:eventDictionary[@"key"] value:eventDictionary[@"value"]];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathRemoveUserAttribute]) {
            [self setUserAttribute:eventDictionary[@"key"] value:nil];
        } else if ([hostPath hasPrefix:kMParticleWebViewPathSetSessionAttribute]) {
            [self setSessionAttribute:eventDictionary[@"key"] value:eventDictionary[@"value"]];
        }
    } @catch (NSException *e) {
        MPILogError(@"Exception processing UIWebView event: %@", e.reason)
    }
}
#endif

@end
