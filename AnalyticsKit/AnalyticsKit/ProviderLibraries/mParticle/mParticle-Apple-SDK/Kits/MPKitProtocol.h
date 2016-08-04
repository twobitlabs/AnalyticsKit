//
//  MPKitProtocol.h
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

#ifndef mParticle_Apple_SDK_MPKitProtocol_h
#define mParticle_Apple_SDK_MPKitProtocol_h

#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@class MPCommerceEvent;
@class MPEvent;
@class MPKitExecStatus;
@class MPMediaTrack;
@class MPUserSegments;


@protocol MPKitProtocol <NSObject>
#pragma mark - Required methods
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately;

+ (nonnull NSNumber *)kitCode;

#pragma mark - Optional methods
@optional

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, strong, nullable, readonly) id providerKitInstance;

#pragma mark Kit lifecycle
- (void)start;
- (void)deinit;

#pragma mark Application
- (nonnull MPKitExecStatus *)checkForDeferredDeepLinkWithCompletionHandler:(void(^ _Nonnull)(NSDictionary<NSString *, NSString *> * _Nullable linkInfo, NSError * _Nullable error))completionHandler;
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler;
- (nonnull MPKitExecStatus *)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity;
- (nonnull MPKitExecStatus *)didBecomeActive;
- (nonnull MPKitExecStatus *)failedToRegisterForUserNotifications:(nullable NSError *)error;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nonnull NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)setDeviceToken:(nonnull NSData *)deviceToken;

#if TARGET_OS_IOS == 1
- (nonnull MPKitExecStatus *)didRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings;
#endif

#pragma mark Location tracking
#if TARGET_OS_IOS == 1
- (nonnull MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;
- (nonnull MPKitExecStatus *)endLocationTracking;
- (nonnull MPKitExecStatus *)setLocation:(nonnull CLLocation *)location;
#endif

#pragma mark Session management
- (nonnull MPKitExecStatus *)beginSession;
- (nonnull MPKitExecStatus *)endSession;

#pragma mark User attributes and identities
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;

- (nonnull MPKitExecStatus *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nullable NSString *)value;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values;
- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;
- (nonnull MPKitExecStatus *)setUserTag:(nonnull NSString *)tag;

#pragma mark e-Commerce
- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent;
- (nonnull MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(nonnull MPEvent *)event;

#pragma mark Events
- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logInstall;
- (nonnull MPKitExecStatus *)logout;
- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logUpdate;

#pragma mark Timed events
- (nonnull MPKitExecStatus *)beginTimedEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)endTimedEvent:(nonnull MPEvent *)event;

#pragma mark Errors and exceptions
- (nonnull MPKitExecStatus *)leaveBreadcrumb:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logError:(nullable NSString *)message eventInfo:(nullable NSDictionary *)eventInfo;
- (nonnull MPKitExecStatus *)logException:(nonnull NSException *)exception;

#pragma mark Assorted
- (nonnull MPKitExecStatus *)setDebugMode:(BOOL)debugMode;
- (nonnull MPKitExecStatus *)setKitAttribute:(nonnull NSString *)key value:(nullable id)value;
- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut;
- (nullable NSString *)surveyURLWithUserAttributes:(nonnull NSDictionary *)userAttributes;

#pragma mark Media tracking
- (nonnull MPKitExecStatus *)beginPlaying:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)endPlaying:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)logMetadataWithMediaTrack:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)logTimedMetadataWithMediaTrack:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)updatePlaybackPosition:(nonnull MPMediaTrack *)mediaTrack;

@end

#endif
