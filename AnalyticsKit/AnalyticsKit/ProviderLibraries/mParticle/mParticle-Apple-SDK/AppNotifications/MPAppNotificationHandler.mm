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

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
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
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    NSNumber *lastKit = nil;
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:failedRegistrationSelector]) {
            MPKitExecStatus *execStatus = [kitRegister.wrapperInstance failedToRegisterForUserNotifications:error];
            
            if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                lastKit = execStatus.kitCode;
                
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                                   execStatus:execStatus
                                                                                    stateFlag:NO];
                
                [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                
                MPILogDebug(@"Forwarded fail to register for remote notification call to kit: %@", kitRegister.name);
            }
        }
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [MPNotificationController setDeviceToken:deviceToken];
    
    SEL deviceTokenSelector = @selector(setDeviceToken:);
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    NSNumber *lastKit = nil;
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:deviceTokenSelector]) {
            MPKitExecStatus *execStatus = [kitRegister.wrapperInstance setDeviceToken:deviceToken];
            
            if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                lastKit = execStatus.kitCode;
                
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                                   execStatus:execStatus
                                                                                    stateFlag:(deviceToken != nil)];
                
                [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                
                MPILogDebug(@"Forwarded remote notification registration call to kit: %@", kitRegister.name);
            }
        }
    }
}

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    SEL didRegisterUserNotificationSettingsSelector = @selector(didRegisterUserNotificationSettings:);
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:didRegisterUserNotificationSettingsSelector]) {
            [kitRegister.wrapperInstance didRegisterUserNotificationSettings:notificationSettings];
        }
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [self receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeRemote];
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:);
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:handleActionWithIdentifierSelector]) {
            [kitRegister.wrapperInstance handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
        }
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [self receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeRemote];
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:withResponseInfo:);
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:handleActionWithIdentifierSelector]) {
            [kitRegister.wrapperInstance handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo];
        }
    }
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
        SEL receivedNotificationSelector = @selector(receivedUserNotification:);
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
        NSNumber *lastKit = nil;
        BOOL shouldForward = YES;
        
        if ([MPNotificationController launchNotificationHash] != 0) {
            NSError *error = nil;
            NSData *remoteNotificationData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
            
            if (!error && remoteNotificationData.length > 0) {
                int64_t launchNotificationHash = mParticle::Hasher::hashFNV1a(static_cast<const char *>([remoteNotificationData bytes]), static_cast<int>([remoteNotificationData length]));
                shouldForward = launchNotificationHash != [MPNotificationController launchNotificationHash];
            }
        }

        for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:receivedNotificationSelector]) {
                if (static_cast<MPKitInstance>([kitRegister.code integerValue]) == MPKitInstanceKahuna && !shouldForward) {
                    continue;
                }
                
                MPKitExecStatus *execStatus = [kitRegister.wrapperInstance receivedUserNotification:userInfo];
                
                if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                    lastKit = execStatus.kitCode;
                    
                    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushNotification
                                                                                       execStatus:execStatus];
                    
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                    
                    MPILogDebug(@"Forwarded push notifications call to kit: %@", kitRegister.name);
                }
            }
        }
    }
}

- (void)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    SEL didUpdateUserActivitySelector = @selector(didUpdateUserActivity:);
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:didUpdateUserActivitySelector]) {
            [kitRegister.wrapperInstance didUpdateUserActivity:userActivity];
        }
    }
}
#endif

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^__nonnull)(NSArray * __nullable restorableObjects))restorationHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return NO;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    SEL continueUserActivitySelector = @selector(continueUserActivity:restorationHandler:);
    BOOL handlingActivity = NO;
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:continueUserActivitySelector]) {
            handlingActivity = YES;
            [kitRegister.wrapperInstance continueUserActivity:userActivity restorationHandler:restorationHandler];
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
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    SEL openURLOptionsSelector = @selector(openURL:options:);
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:openURLOptionsSelector]) {
            [kitRegister.wrapperInstance openURL:url options:options];
        }
    }
}

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
    SEL openURLSourceAppAnnotationSelector = @selector(openURL:sourceApplication:annotation:);
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:openURLSourceAppAnnotationSelector]) {
            [kitRegister.wrapperInstance openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }
}

@end
