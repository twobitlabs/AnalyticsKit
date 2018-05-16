#import "MPAppNotificationHandler.h"
#import "MPStateMachine.h"
#import "MPLaunchInfo.h"
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPKitExecStatus.h"
#import <UIKit/UIKit.h>
#import "MPKitContainer.h"
#include "MPHasher.h"
#import "MPForwardQueueParameters.h"
#import "MPKitAPI.h"

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    #import <UserNotifications/UserNotifications.h>
    #import <UserNotifications/UNUserNotificationCenter.h>
#endif

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@end

@interface MPKitAPI ()
- (id)initWithKitCode:(NSNumber *)kitCode;
@end

@implementation MPAppNotificationHandler

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
#if TARGET_OS_IOS == 1
    _runningMode = MPUserNotificationRunningModeForeground;
#endif
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];

    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

+ (instancetype)sharedInstance {
    static MPAppNotificationHandler *sharedInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [[MPAppNotificationHandler alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
#if TARGET_OS_IOS == 1
    _runningMode = MPUserNotificationRunningModeBackground;
#endif
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
#if TARGET_OS_IOS == 1
    _runningMode = MPUserNotificationRunningModeForeground;
#endif
}

#pragma mark Public methods
#if TARGET_OS_IOS == 1
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
#if !defined(MPARTICLE_APP_EXTENSIONS)
    [MPNotificationController setDeviceToken:nil];
#endif
    
    SEL failedRegistrationSelector = @selector(failedToRegisterForUserNotifications:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:error];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:failedRegistrationSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit failedToRegisterForUserNotifications:forwardParameters[0]];
                                             }];
    });
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
#if !defined(MPARTICLE_APP_EXTENSIONS)
    [MPNotificationController setDeviceToken:deviceToken];
#endif
    SEL deviceTokenSelector = @selector(setDeviceToken:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:deviceToken];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:deviceTokenSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit setDeviceToken:forwardParameters[0]];
                                             }];
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
#pragma clang diagnostic pop
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    SEL didRegisterUserNotificationSettingsSelector = @selector(didRegisterUserNotificationSettings:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:notificationSettings];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:didRegisterUserNotificationSettingsSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit didRegisterUserNotificationSettings:forwardParameters[0]];
                                             }];
    });
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [self receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeRemote];
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:identifier];
    [queueParameters addParameter:userInfo];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:handleActionWithIdentifierSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit handleActionWithIdentifier:forwardParameters[0] forRemoteNotification:forwardParameters[1]];
                                             }];
    });
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [self receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeRemote];
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:withResponseInfo:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:identifier];
    [queueParameters addParameter:userInfo];
    [queueParameters addParameter:responseInfo];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:handleActionWithIdentifierSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit handleActionWithIdentifier:forwardParameters[0] forRemoteNotification:forwardParameters[1] withResponseInfo:forwardParameters[2]];
                                             }];
    });
}

- (void)receivedUserNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)actionIdentifier userNotificationMode:(MPUserNotificationMode)userNotificationMode {
    if ([MPStateMachine sharedInstance].optOut || !userInfo) {
        return;
    }
    
    
    NSMutableDictionary *userNotificationDictionary = [@{kMPUserNotificationDictionaryKey:userInfo,
                                                         kMPUserNotificationRunningModeKey:@(self.runningMode)}
                                                       mutableCopy];
    if (actionIdentifier) {
        userNotificationDictionary[kMPUserNotificationActionKey] = actionIdentifier;
    }
    
    NSString *notificationName = userNotificationMode == MPUserNotificationModeRemote ? kMPRemoteNotificationReceivedNotification : kMPLocalNotificationReceivedNotification;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:self
                                                      userInfo:userNotificationDictionary];
    
    
    if (!actionIdentifier) {
        SEL receivedNotificationSelector = @selector(receivedUserNotification:);
        
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:userInfo];
        
        dispatch_async([MParticle messageQueue], ^{
            [[MPKitContainer sharedInstance] forwardSDKCall:receivedNotificationSelector
                                                 parameters:queueParameters
                                                messageType:MPMessageTypePushNotification
                                                 kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                     *execStatus = [kit receivedUserNotification:forwardParameters[0]];
                                                 }];
        });
    }
}

- (void)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    SEL didUpdateUserActivitySelector = @selector(didUpdateUserActivity:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:userActivity];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:didUpdateUserActivitySelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit didUpdateUserActivity:forwardParameters[0]];
                                             }];
    });
}
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    NSDictionary *userNotificationDictionary = @{kMPUserNotificationDictionaryKey:notification.request.content.userInfo,
                                                 kMPUserNotificationRunningModeKey:@(self.runningMode)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:userNotificationDictionary];
    
    SEL userNotificationCenterWillPresentNotification = @selector(userNotificationCenter:willPresentNotification:);
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:userNotificationCenterWillPresentNotification]) {
            [kitRegister.wrapperInstance userNotificationCenter:center willPresentNotification:notification];
        }
    }
}

- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    NSMutableDictionary *userNotificationDictionary = [@{kMPUserNotificationDictionaryKey:response.notification.request.content.userInfo,
                                                         kMPUserNotificationRunningModeKey:@(self.runningMode)}
                                                       mutableCopy];
    if (response.actionIdentifier) {
        userNotificationDictionary[kMPUserNotificationActionKey] = response.actionIdentifier;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:userNotificationDictionary];
    
    SEL userNotificationCenterDidReceiveNotificationResponse = @selector(userNotificationCenter:didReceiveNotificationResponse:);
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    NSNumber *lastKit = nil;
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:userNotificationCenterDidReceiveNotificationResponse]) {
            MPKitExecStatus *execStatus = [kitRegister.wrapperInstance userNotificationCenter:center didReceiveNotificationResponse:response];
            
            if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                lastKit = execStatus.kitCode;
                
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushNotification
                                                                                   execStatus:execStatus];
                
                dispatch_async([MParticle messageQueue], ^{
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                });
                
                MPILogDebug(@"Forwarded user notifications call to kit: %@", kitRegister.name);
            }
        }
    }
}
#endif

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return NO;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
    
    SEL continueUserActivitySelector = @selector(continueUserActivity:restorationHandler:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:userActivity];
    [queueParameters addParameter:restorationHandler];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:continueUserActivitySelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit continueUserActivity:forwardParameters[0] restorationHandler:forwardParameters[1]];
                                             }];
    });
    
    NSSet<id<MPExtensionKitProtocol>> *registeredKitsRegistry = [MPKitContainer registeredKits];
    BOOL handlingActivity = NO;
    for (id<MPExtensionKitProtocol> kitRegister in registeredKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:continueUserActivitySelector]) {
            handlingActivity = YES;
            break;
        }
    }
    
    return handlingActivity;
}

- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url options:options];
    
    SEL openURLOptionsSelector = @selector(openURL:options:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:url];
    [queueParameters addParameter:options];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:openURLOptionsSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit openURL:forwardParameters[0] options:forwardParameters[1]];
                                             }];
    });
}

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    SEL openURLSourceAppAnnotationSelector = @selector(openURL:sourceApplication:annotation:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:url];
    [queueParameters addParameter:sourceApplication];
    [queueParameters addParameter:annotation];
    
    dispatch_async([MParticle messageQueue], ^{
        [[MPKitContainer sharedInstance] forwardSDKCall:openURLSourceAppAnnotationSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 *execStatus = [kit openURL:forwardParameters[0] sourceApplication:forwardParameters[1] annotation:forwardParameters[2]];
                                             }];
    });
}

@end
