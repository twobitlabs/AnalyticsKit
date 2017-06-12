//
//  MParticleUserNotification.h
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

#import "MPDataModelAbstract.h"

typedef NS_OPTIONS(NSUInteger, MPUserNotificationBehavior) {
    MPUserNotificationBehaviorReceived = 1 << 0,
    MPUserNotificationBehaviorDirectOpen = 1 << 1,
    MPUserNotificationBehaviorRead = 1 << 2,
    MPUserNotificationBehaviorInfluencedOpen = 1 << 3,
    MPUserNotificationBehaviorDisplayed = 1 << 4
};

typedef NS_ENUM(NSUInteger, MPUserNotificationCommand) {
    MPUserNotificationCommandDoNothing = 0,         // Not particularly useful but good to have a harmless default value
    MPUserNotificationCommandAlertUser,             // Immediately alert the user with the message contents
    MPUserNotificationCommandAlertUserLocalTime,    // Alert the user with the message contents at the time (in local timezone) specified by the m_ldt parameter
    MPUserNotificationCommandBackground,            // Do not alert the user but process the push normally otherwise
    MPUserNotificationCommandConfigRefresh          // Perform a config refresh against the SDK server
};

typedef NS_ENUM(NSInteger, MPUserNotificationMode) {
    MPUserNotificationModeAutoDetect = 0,
    MPUserNotificationModeRemote,
    MPUserNotificationModeLocal
};

typedef NS_ENUM(NSInteger, MPUserNotificationRunningMode) {
    MPUserNotificationRunningModeBackground = 1,
    MPUserNotificationRunningModeForeground
};

extern NSString * _Nonnull const kMPUserNotificationApsKey;
extern NSString * _Nonnull const kMPUserNotificationAlertKey;
extern NSString * _Nonnull const kMPUserNotificationBodyKey;
extern NSString * _Nonnull const kMPUserNotificationContentAvailableKey;
extern NSString * _Nonnull const kMPUserNotificationCommandKey;
extern NSString * _Nonnull const kMPUserNotificationCampaignIdKey;
extern NSString * _Nonnull const kMPUserNotificationContentIdKey;
extern NSString * _Nonnull const kMPUserNotificationExpirationKey;
extern NSString * _Nonnull const kMPUserNotificationLocalDeliveryTimeKey;
extern NSString * _Nonnull const kMPUserNotificationDeferredApsKey;
extern NSString * _Nonnull const kMPUserNotificationUniqueIdKey;
extern NSString * _Nonnull const kMPUserNotificationCategoryKey;

#if TARGET_OS_IOS == 1

@interface MParticleUserNotification : MPDataModelAbstract <NSCoding>

@property (nonatomic, strong, nullable) NSString *actionIdentifier;
@property (nonatomic, strong, nullable) NSString *actionTitle;
@property (nonatomic, strong, nullable) NSDictionary *deferredPayload;
@property (nonatomic, strong, nonnull) NSString *type;
@property (nonatomic, strong, readonly, nullable) NSNumber *campaignId;
@property (nonatomic, strong, readonly, nullable) NSString *categoryIdentifier;
@property (nonatomic, strong, readonly, nullable) NSNumber *contentId;
@property (nonatomic, strong, readonly, nullable) NSDate *localAlertDate;
@property (nonatomic, strong, readonly, nullable) NSString *redactedUserNotificationString;
@property (nonatomic, strong, readonly, nonnull) NSDate *receiptTime;
@property (nonatomic, strong, readonly, nonnull) NSString *state;
@property (nonatomic, strong, readonly, nullable) NSNumber *uniqueIdentifier;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval campaignExpiration;
@property (nonatomic, unsafe_unretained, readwrite) int64_t userNotificationId;
@property (nonatomic, unsafe_unretained, readwrite) MPUserNotificationBehavior behavior;
@property (nonatomic, unsafe_unretained, readwrite) MPUserNotificationCommand command;
@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationMode mode;
@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationRunningMode runningMode;
@property (nonatomic, unsafe_unretained, readwrite) BOOL hasBeenUsedInDirectOpen;
@property (nonatomic, unsafe_unretained, readwrite) BOOL hasBeenUsedInInfluencedOpen;
@property (nonatomic, unsafe_unretained, readwrite) BOOL shouldPersist;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)notificationDictionary actionIdentifier:(nullable NSString *)actionIdentifier state:(nonnull NSString *)state behavior:(MPUserNotificationBehavior)behavior mode:(MPUserNotificationMode)mode runningMode:(MPUserNotificationRunningMode)runningMode;

@end

#endif
