//
//  MPAppNotificationHandler.mm
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

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    #import <UserNotifications/UserNotifications.h>
    #import <UserNotifications/UNUserNotificationCenter.h>
#endif

@interface MPAppNotificationHandler() {
    dispatch_queue_t processUserNotificationQueue;
}
@end


@implementation MPAppNotificationHandler

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    processUserNotificationQueue = dispatch_queue_create("com.mParticle.ProcessUserNotificationQueue", DISPATCH_QUEUE_SERIAL);
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
    
    [MPNotificationController setDeviceToken:nil];
    
    SEL failedRegistrationSelector = @selector(failedToRegisterForUserNotifications:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:error];
    
    [[MPKitContainer sharedInstance] forwardSDKCall:failedRegistrationSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit failedToRegisterForUserNotifications:forwardParameters[0]];
                                         }];
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [MPNotificationController setDeviceToken:deviceToken];
    
    SEL deviceTokenSelector = @selector(setDeviceToken:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:deviceToken];
    
    [[MPKitContainer sharedInstance] forwardSDKCall:deviceTokenSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit setDeviceToken:forwardParameters[0]];
                                         }];
}

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    SEL didRegisterUserNotificationSettingsSelector = @selector(didRegisterUserNotificationSettings:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:notificationSettings];
    
    [[MPKitContainer sharedInstance] forwardSDKCall:didRegisterUserNotificationSettingsSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit didRegisterUserNotificationSettings:forwardParameters[0]];
                                         }];
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:handleActionWithIdentifierSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit handleActionWithIdentifier:forwardParameters[0] forRemoteNotification:forwardParameters[1]];
                                         }];
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:handleActionWithIdentifierSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit handleActionWithIdentifier:forwardParameters[0] forRemoteNotification:forwardParameters[1] withResponseInfo:forwardParameters[2]];
                                         }];
}

- (void)receivedUserNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)actionIdentifier userNotificationMode:(MPUserNotificationMode)userNotificationMode {
    if ([MPStateMachine sharedInstance].optOut || !userInfo) {
        return;
    }
    
    __weak MPAppNotificationHandler *weakSelf = self;
    dispatch_async(processUserNotificationQueue, ^{
        __strong MPAppNotificationHandler *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        NSMutableDictionary *userNotificationDictionary = [@{kMPUserNotificationDictionaryKey:userInfo,
                                                             kMPUserNotificationRunningModeKey:@(strongSelf.runningMode)}
                                                           mutableCopy];
        if (actionIdentifier) {
            userNotificationDictionary[kMPUserNotificationActionKey] = actionIdentifier;
        }
        
        NSString *notificationName;
        if (userNotificationMode == MPUserNotificationModeAutoDetect) {
            MPUserNotificationCommand command = static_cast<MPUserNotificationCommand>([userInfo[kMPUserNotificationCommandKey] integerValue]);
            
            notificationName = command != MPUserNotificationCommandAlertUserLocalTime ? kMPRemoteNotificationReceivedNotification : kMPLocalNotificationReceivedNotification;
        } else {
            notificationName = userNotificationMode == MPUserNotificationModeRemote ? kMPRemoteNotificationReceivedNotification : kMPLocalNotificationReceivedNotification;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:strongSelf
                                                          userInfo:userNotificationDictionary];
    });
    
    if (!actionIdentifier) {
        if ([MPNotificationController launchNotificationHash] != 0) {
            NSError *error = nil;
            NSData *remoteNotificationData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
            
            if (!error && remoteNotificationData.length > 0) {
                int64_t launchNotificationHash = mParticle::Hasher::hashFNV1a(static_cast<const char *>([remoteNotificationData bytes]), static_cast<int>([remoteNotificationData length]));
                BOOL shouldForward = launchNotificationHash != [MPNotificationController launchNotificationHash];
                
                if (!shouldForward) {
                    return;
                }
            }
        }
        
        SEL receivedNotificationSelector = @selector(receivedUserNotification:);
        
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:userInfo];
        
        [[MPKitContainer sharedInstance] forwardSDKCall:receivedNotificationSelector
                                             parameters:queueParameters
                                            messageType:MPMessageTypePushNotification
                                             kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                                 if (static_cast<MPKitInstance>([[[kit class] kitCode] integerValue]) == MPKitInstanceKahuna) {
                                                     return;
                                                 }
                                                 
                                                 *execStatus = [kit receivedUserNotification:forwardParameters[0]];
                                             }];
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:didUpdateUserActivitySelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit didUpdateUserActivity:forwardParameters[0]];
                                         }];
}
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    __weak MPAppNotificationHandler *weakSelf = self;
    dispatch_async(processUserNotificationQueue, ^{
        __strong MPAppNotificationHandler *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        NSDictionary *userNotificationDictionary = @{kMPUserNotificationDictionaryKey:notification.request.content.userInfo,
                                                     kMPUserNotificationRunningModeKey:@(strongSelf.runningMode)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                            object:strongSelf
                                                          userInfo:userNotificationDictionary];
    });
    
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
    
    __weak MPAppNotificationHandler *weakSelf = self;
    dispatch_async(processUserNotificationQueue, ^{
        __strong MPAppNotificationHandler *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        NSMutableDictionary *userNotificationDictionary = [@{kMPUserNotificationDictionaryKey:response.notification.request.content.userInfo,
                                                             kMPUserNotificationRunningModeKey:@(strongSelf.runningMode)}
                                                           mutableCopy];
        if (response.actionIdentifier) {
            userNotificationDictionary[kMPUserNotificationActionKey] = response.actionIdentifier;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                            object:strongSelf
                                                          userInfo:userNotificationDictionary];
    });
    
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
                
                [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:continueUserActivitySelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit continueUserActivity:forwardParameters[0] restorationHandler:forwardParameters[1]];
                                         }];
    
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:openURLOptionsSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit openURL:forwardParameters[0] options:forwardParameters[1]];
                                         }];
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
    
    [[MPKitContainer sharedInstance] forwardSDKCall:openURLSourceAppAnnotationSelector
                                         parameters:queueParameters
                                        messageType:MPMessageTypeUnknown
                                         kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                             *execStatus = [kit openURL:forwardParameters[0] sourceApplication:forwardParameters[1] annotation:forwardParameters[2]];
                                         }];
}

@end
