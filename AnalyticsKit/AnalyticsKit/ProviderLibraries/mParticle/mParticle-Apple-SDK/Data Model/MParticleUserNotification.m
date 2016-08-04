//
//  MParticleUserNotification.m
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

#import "MParticleUserNotification.h"

NSString *const kMPUserNotificationApsKey = @"aps";
NSString *const kMPUserNotificationAlertKey = @"alert";
NSString *const kMPUserNotificationBodyKey = @"body";
NSString *const kMPUserNotificationContentAvailableKey = @"content-available";
NSString *const kMPUserNotificationCommandKey = @"m_cmd";
NSString *const kMPUserNotificationCampaignIdKey = @"m_cid";
NSString *const kMPUserNotificationContentIdKey = @"m_cntid";
NSString *const kMPUserNotificationExpirationKey = @"m_expy";
NSString *const kMPUserNotificationLocalDeliveryTimeKey = @"m_ldt";
NSString *const kMPUserNotificationDeferredApsKey = @"m_aps";
NSString *const kMPUserNotificationUniqueIdKey = @"m_uid";
NSString *const kMPUserNotificationCategoryKey = @"category";

#if TARGET_OS_IOS == 1

#import "MPIConstants.h"
#import "MPDateFormatter.h"
#import <UIKit/UIKit.h>
#import "MPStateMachine.h"
#import "MPILogger.h"

@implementation MParticleUserNotification

- (instancetype)initWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state behavior:(MPUserNotificationBehavior)behavior mode:(MPUserNotificationMode)mode runningMode:(MPUserNotificationRunningMode)runningMode {
    self = [super init];
    if (!self || !state) {
        return nil;
    }
    
    _hasBeenUsedInDirectOpen = NO;
    _hasBeenUsedInInfluencedOpen = NO;
    _campaignId = notificationDictionary[kMPUserNotificationCampaignIdKey];
    _contentId = notificationDictionary[kMPUserNotificationContentIdKey];
    _runningMode = runningMode;
    _uniqueIdentifier = notificationDictionary[kMPUserNotificationUniqueIdKey];
    _shouldPersist = YES;
    
    if (notificationDictionary[kMPUserNotificationCommandKey]) {
        _command = [notificationDictionary[kMPUserNotificationCommandKey] integerValue];
        
        if (_command > MPUserNotificationCommandConfigRefresh) {
            _command = MPUserNotificationCommandDoNothing;
        }
    } else {
        _command = MPUserNotificationCommandAlertUser;
    }
    
    NSString *localDeliveryDate = notificationDictionary[kMPUserNotificationLocalDeliveryTimeKey];
    
    if (mode == MPUserNotificationModeAutoDetect) {
        if (_command == MPUserNotificationCommandAlertUserLocalTime || (_contentId && !localDeliveryDate)) {
            _mode = MPUserNotificationModeLocal;
        } else {
            _mode = MPUserNotificationModeRemote;
        }
    } else {
        _mode = mode;
    }
    
    if (_command == MPUserNotificationCommandAlertUserLocalTime) {
        if (!localDeliveryDate) {
            return nil;
        }
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSTimeZone *timeZone = [calendar timeZone];
        _localAlertDate = [MPDateFormatter dateFromStringRFC3339:localDeliveryDate];
        _localAlertDate = [NSDate dateWithTimeInterval:([timeZone secondsFromGMT] * -1) sinceDate:_localAlertDate];
        
        _deferredPayload = notificationDictionary[kMPUserNotificationDeferredApsKey];
    }

    _behavior = behavior;
    _state = state;
    _redactedUserNotificationString = [self redactUserNotification:notificationDictionary];
    _uuid = [[NSUUID UUID] UUIDString];
    
    if (actionIdentifier) {
        _actionIdentifier = [actionIdentifier copy];
        _type = kMPPushMessageAction;
        
        if (_categoryIdentifier) {
            UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
            
            if (userNotificationSettings) {
                for (UIUserNotificationCategory *category in userNotificationSettings.categories) {
                    if ([category.identifier isEqualToString:_categoryIdentifier]) {
                        for (UIUserNotificationAction *action in [category actionsForContext:UIUserNotificationActionContextDefault]) {
                            if ([action.identifier isEqualToString:actionIdentifier]) {
                                _actionTitle = action.title;
                                break;
                            }
                        }
                        
                        break;
                    }
                }
            }
        }
    } else {
        _actionIdentifier = nil;
        _actionTitle = nil;
        _type = kMPPushMessageReceived;
        _receiptTime = [NSDate date];
    }
    
    if (notificationDictionary[kMPUserNotificationExpirationKey]) {
        _campaignExpiration = [notificationDictionary[kMPUserNotificationExpirationKey] doubleValue] / 1000.0;
    } else {
        _campaignExpiration = 0.0;
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"User Notification\n Receipt Time: %@\n State: %@\n Type Id: %@\n", self.receiptTime, self.state, self.type];
    
    if (self.uniqueIdentifier) {
        [description appendFormat:@" Unique identifier: %@\n", self.uniqueIdentifier];
    }
    
    if (self.redactedUserNotificationString) {
        [description appendFormat:@" Redacted notification: %@\n", self.redactedUserNotificationString];
    }
    
    if (self.categoryIdentifier) {
        [description appendFormat:@" Category identifier: %@\n", self.categoryIdentifier];
    }
    
    if (self.actionIdentifier) {
        [description appendFormat:@" Action identifier: %@\n Action title: %@\n", self.actionIdentifier, self.actionTitle];
    }
    
    if (self.campaignId) {
        [description appendFormat:@" Campaign Id: %@\n", self.campaignId];
    }
    
    if (self.contentId) {
        [description appendFormat:@" Content Id: %@\n", self.contentId];
    }
    
    if (self.campaignExpiration > 0.0) {
        [description appendFormat:@" Campaign expiration: %@\n", [NSDate dateWithTimeIntervalSince1970:self.campaignExpiration]];
    }
    
    if (self.behavior > 0) {
        [description appendFormat:@" Behavior: %d\n", (int)self.behavior];
    }
    
    if (_userNotificationId > 0) {
        [description appendFormat:@" Notification Id: %d\n", (int)_userNotificationId];
    }
    
    [description appendFormat:@" Has been used in direct open: %@\n", _hasBeenUsedInDirectOpen ? @"YES" : @"NO"];
    [description appendFormat:@" Has been used in influenced open: %@", _hasBeenUsedInInfluencedOpen ? @"YES" : @"NO"];
    
    return description;
}

- (BOOL)isEqual:(MParticleUserNotification *)object {
    BOOL isEqual = NO;
    
    if (_userNotificationId > 0 && object.userNotificationId > 0) {
        isEqual = _userNotificationId == object.userNotificationId;
        
        if (isEqual) {
            return YES;
        }
    }
    
    if (_uniqueIdentifier && object.uniqueIdentifier) {
        isEqual = [_uniqueIdentifier isEqualToNumber:object.uniqueIdentifier];
        
        if (isEqual) {
            return YES;
        }
    } else {
        if (_redactedUserNotificationString && object.redactedUserNotificationString) {
            NSData *redactedUserData1 = [_redactedUserNotificationString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *redactedUserDictionary1 = [NSJSONSerialization JSONObjectWithData:redactedUserData1 options:0 error:nil];
            NSData *redactedUserData2 = [object.redactedUserNotificationString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *redactedUserDictionary2 = [NSJSONSerialization JSONObjectWithData:redactedUserData2 options:0 error:nil];
            
            isEqual = [redactedUserDictionary1 isEqualToDictionary:redactedUserDictionary2];
        }

        if (isEqual) {
            if (_contentId && object.contentId) {
                isEqual = [_contentId isEqualToNumber:object.contentId];
            } else if (_contentId || object.contentId) {
                isEqual = NO;
            }
        }
    }
    
    return isEqual;
}

#pragma mark Private methods
- (NSString *)redactUserNotification:(NSDictionary *)notificationDictionary {
    NSString * (^dictionaryToString)(NSDictionary *) = ^(NSDictionary *dictionary) {
        NSString *dictionaryString = nil;
        
        if (dictionary == nil) {
            return dictionaryString;
        }
        
        NSError *error = nil;
        @try {
            NSData *dictionaryData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
            
            if (!error) {
                dictionaryString = [[NSString alloc] initWithData:dictionaryData encoding:NSUTF8StringEncoding];
            }
        } @catch (NSException *exception) {
            MPILogError(@"Exception serializing a notification dictionary: %@", [exception reason]);
        }
        
        return dictionaryString;
    };
    
    NSString *redactedNotificationString = nil;
    
    if (notificationDictionary[kMPUserNotificationContentAvailableKey]) {
        redactedNotificationString = dictionaryToString(notificationDictionary);
        return redactedNotificationString;
    }
    
    NSString *payloadKey = _mode == MPUserNotificationModeRemote || !notificationDictionary[kMPUserNotificationCommandKey] ? kMPUserNotificationApsKey : kMPUserNotificationDeferredApsKey;
    
    NSMutableDictionary *mPushNotificationDictionary = [notificationDictionary mutableCopy];
    NSDictionary *apsDictionary = mPushNotificationDictionary[payloadKey];
    
    if (![apsDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    _categoryIdentifier = apsDictionary[kMPUserNotificationCategoryKey];
    
    id alert = apsDictionary[kMPUserNotificationAlertKey];
    
    if (!alert) {
        redactedNotificationString = dictionaryToString(notificationDictionary);
        return redactedNotificationString;
    }
    
    [mPushNotificationDictionary removeObjectForKey:payloadKey];
    NSMutableDictionary *mAPSDictionary = [[NSMutableDictionary alloc] initWithCapacity:apsDictionary.count];
    NSEnumerator *apsEnumerator = [apsDictionary keyEnumerator];
    NSString *apsKey;
    
    if ([alert isKindOfClass:[NSString class]]) {
        while ((apsKey = [apsEnumerator nextObject])) {
            if (![apsKey isEqualToString:kMPUserNotificationAlertKey]) {
                mAPSDictionary[apsKey] = apsDictionary[apsKey];
            }
        }
    } else if ([alert isKindOfClass:[NSDictionary class]]) {
        while ((apsKey = [apsEnumerator nextObject])) {
            if ([apsKey isEqualToString:kMPUserNotificationAlertKey]) {
                NSMutableDictionary *alertDictionary = [[NSMutableDictionary alloc] init];
                NSEnumerator *alertEnumerator = [alert keyEnumerator];
                NSString *alertKey;
                
                while ((alertKey = [alertEnumerator nextObject])) {
                    if ([alertKey isEqualToString:kMPUserNotificationBodyKey]) {
                        continue;
                    }
                    
                    alertDictionary[alertKey] = alert[alertKey];
                }
                
                mAPSDictionary[kMPUserNotificationAlertKey] = alertDictionary;
            } else {
                mAPSDictionary[apsKey] = apsDictionary[apsKey];
            }
        }
    }
    
    mPushNotificationDictionary[payloadKey] = mAPSDictionary;

    NSArray *keysToRemove = @[kMPUserNotificationCommandKey, kMPUserNotificationExpirationKey, kMPUserNotificationLocalDeliveryTimeKey, kMPUserNotificationDeferredApsKey];
    for (NSString *key in keysToRemove) {
        if (mPushNotificationDictionary[key]) {
            [mPushNotificationDictionary removeObjectForKey:key];
        }
    }
    
    redactedNotificationString = dictionaryToString(mPushNotificationDictionary);
    
    return redactedNotificationString;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_receiptTime forKey:@"receiptTime"];
    [coder encodeObject:_state forKey:@"state"];
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_uuid forKey:@"uuid"];
    [coder encodeInt64:_userNotificationId forKey:@"userNotificationId"];
    [coder encodeInteger:_behavior forKey:@"behavior"];
    [coder encodeInteger:_mode forKey:@"mode"];
    [coder encodeInteger:_runningMode forKey:@"runningMode"];
    
    if (_redactedUserNotificationString) {
        [coder encodeObject:_redactedUserNotificationString forKey:@"redactedUserNotificationString"];
    }
    
    if (_categoryIdentifier) {
        [coder encodeObject:_categoryIdentifier forKey:@"categoryIdentifier"];
    }
    
    if (_actionIdentifier) {
        [coder encodeObject:_actionIdentifier forKey:@"actionIdentifier"];
    }
    
    if (_actionTitle) {
        [coder encodeObject:_actionTitle forKey:@"actionTitle"];
    }
    
    if (_campaignId) {
        [coder encodeObject:_campaignId forKey:@"campaignId"];
    }
    
    if (_contentId) {
        [coder encodeObject:_contentId forKey:@"contentId"];
    }
    
    if (_localAlertDate) {
        [coder encodeObject:_localAlertDate forKey:@"localAlertDate"];
    }
    
    if (_deferredPayload) {
        [coder encodeObject:_deferredPayload forKey:@"deferredPayload"];
    }
    
    if (_campaignExpiration > 0) {
        [coder encodeDouble:_campaignExpiration forKey:@"campaignExpiration"];
    }
    
    if (_command != MPUserNotificationCommandDoNothing) {
        [coder encodeInteger:_command forKey:@"command"];
    }
    
    if (_hasBeenUsedInDirectOpen) {
        [coder encodeBool:_hasBeenUsedInDirectOpen forKey:@"hasBeenUsedInDirectOpen"];
    }
    
    if (_hasBeenUsedInInfluencedOpen) {
        [coder encodeBool:_hasBeenUsedInInfluencedOpen forKey:@"hasBeenUsedInInfluencedOpen"];
    }
    
    if (_uniqueIdentifier) {
        [coder encodeObject:_uniqueIdentifier forKey:@"uniqueIdentifier"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldPersist = YES;
    _receiptTime = [coder decodeObjectForKey:@"receiptTime"];
    _state = [coder decodeObjectForKey:@"state"];
    _type = [coder decodeObjectForKey:@"type"];
    _uuid = [coder decodeObjectForKey:@"uuid"];
    _userNotificationId = [coder decodeInt64ForKey:@"userNotificationId"];
    _behavior = [coder decodeIntegerForKey:@"behavior"];
    _mode = [coder decodeIntegerForKey:@"mode"];
    _runningMode = [coder decodeIntegerForKey:@"runningMode"];
    
    id object = [coder decodeObjectForKey:@"categoryIdentifier"];
    if (object) {
        _categoryIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"redactedUserNotificationString"];
    if (object) {
        _redactedUserNotificationString = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionIdentifier"];
    if (object) {
        _actionIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionTitle"];
    if (object) {
        _actionTitle = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"campaignId"];
    if (object) {
        _campaignId = (NSNumber *)object;
    }
    
    object = [coder decodeObjectForKey:@"contentId"];
    if (object) {
        _contentId = (NSNumber *)object;
    }
    
    object = [coder decodeObjectForKey:@"localAlertDate"];
    if (object) {
        _localAlertDate = (NSDate *)object;
    }
    
    object = [coder decodeObjectForKey:@"deferredPayload"];
    if (object) {
        _deferredPayload = (NSDictionary *)object;
    }
    
    object = [coder decodeObjectForKey:@"uniqueIdentifier"];
    if (object) {
        _uniqueIdentifier = (NSNumber *)object;
    }
    
    NSTimeInterval expiration = [coder decodeDoubleForKey:@"campaignExpiration"];
    if (expiration > 0) {
        _campaignExpiration = expiration;
    }
    
    NSUInteger command = [coder decodeIntegerForKey:@"command"];
    if (command != MPUserNotificationCommandDoNothing) {
        _command = command;
    }
    
    BOOL flag = [coder decodeBoolForKey:@"hasBeenUsedInDirectOpen"];
    if (flag) {
        _hasBeenUsedInDirectOpen = flag;
    }
    
    flag = [coder decodeBoolForKey:@"hasBeenUsedInInfluencedOpen"];
    if (flag) {
        _hasBeenUsedInInfluencedOpen = flag;
    }
    
    return self;
}

@end

#endif
