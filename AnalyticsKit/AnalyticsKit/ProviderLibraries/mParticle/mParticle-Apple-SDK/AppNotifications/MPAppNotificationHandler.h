//
//  MPAppNotificationHandler.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
    #import "MParticleUserNotification.h"
#endif

@interface MPAppNotificationHandler : NSObject

#if TARGET_OS_IOS == 1
@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationRunningMode runningMode;

- (void)didFailToRegisterForRemoteNotificationsWithError:(nullable NSError *)error;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;
- (void)didRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings;
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo;
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo withResponseInfo:(nullable NSDictionary *)responseInfo;
- (void)receivedUserNotification:(nonnull NSDictionary *)userInfo actionIdentifier:(nullable NSString *)actionIdentifier userNotificationMode:(MPUserNotificationMode)userNotificationMode;
- (void)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity;
#endif

+ (nonnull instancetype)sharedInstance;
- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^__nonnull)(NSArray * __nullable restorableObjects))restorationHandler;
- (void)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;
- (void)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;

@end
