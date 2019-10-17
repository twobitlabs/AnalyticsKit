#import "MParticleUserNotification.h"
#import "MPApplication.h"
#import "MParticle.h"

NSString *const kMPUserNotificationApsKey = @"aps";
NSString *const kMPUserNotificationAlertKey = @"alert";
NSString *const kMPUserNotificationBodyKey = @"body";
NSString *const kMPUserNotificationContentAvailableKey = @"content-available";
NSString *const kMPUserNotificationCategoryKey = @"category";

#if TARGET_OS_IOS == 1

#import "MPIConstants.h"
#import "MPDateFormatter.h"
#import <UIKit/UIKit.h>
#import "MPILogger.h"

@implementation MParticleUserNotification

- (instancetype)initWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state behavior:(MPUserNotificationBehavior)behavior mode:(MPUserNotificationMode)mode {
    self = [super init];
    if (!self || !state) {
        return nil;
    }
    
    _shouldPersist = YES;
    
    if (mode == MPUserNotificationModeAutoDetect) {
        _mode = MPUserNotificationModeRemote;
    } else {
        _mode = mode;
    }

    _behavior = behavior;
    _state = state;
    _redactedUserNotificationString = [self redactUserNotification:notificationDictionary];
    _uuid = [[NSUUID UUID] UUIDString];
    
    if (actionIdentifier) {
        _actionIdentifier = [actionIdentifier copy];
        _type = kMPPushMessageAction;
        
        if (_categoryIdentifier) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            __block UIUserNotificationSettings *userNotificationSettings = nil;
            if ([NSThread isMainThread]) {
                userNotificationSettings = [[MPApplication sharedUIApplication] currentUserNotificationSettings];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    userNotificationSettings = [[MPApplication sharedUIApplication] currentUserNotificationSettings];
                });
            }
            
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
#pragma clang diagnostic pop
        }
    } else {
        _actionIdentifier = nil;
        _actionTitle = nil;
        _type = kMPPushMessageReceived;
        _receiptTime = [NSDate date];
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"User Notification\n Receipt Time: %@\n State: %@\n Type Id: %@\n", self.receiptTime, self.state, self.type];
    
    if (self.redactedUserNotificationString) {
        [description appendFormat:@" Redacted notification: %@\n", self.redactedUserNotificationString];
    }
    
    if (self.categoryIdentifier) {
        [description appendFormat:@" Category identifier: %@\n", self.categoryIdentifier];
    }
    
    if (self.actionIdentifier) {
        [description appendFormat:@" Action identifier: %@\n Action title: %@\n", self.actionIdentifier, self.actionTitle];
    }
    
    if (self.behavior > 0) {
        [description appendFormat:@" Behavior: %d\n", (int)self.behavior];
    }
    
    if (_userNotificationId > 0) {
        [description appendFormat:@" Notification Id: %d\n", (int)_userNotificationId];
    }
    
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
    
    if (_redactedUserNotificationString && object.redactedUserNotificationString) {
        NSData *redactedUserData1 = [_redactedUserNotificationString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *redactedUserDictionary1 = [NSJSONSerialization JSONObjectWithData:redactedUserData1 options:0 error:nil];
        NSData *redactedUserData2 = [object.redactedUserNotificationString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *redactedUserDictionary2 = [NSJSONSerialization JSONObjectWithData:redactedUserData2 options:0 error:nil];
        
        isEqual = [redactedUserDictionary1 isEqualToDictionary:redactedUserDictionary2];
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
    
    NSMutableDictionary *mPushNotificationDictionary = [notificationDictionary mutableCopy];
    NSDictionary *apsDictionary = mPushNotificationDictionary[kMPUserNotificationApsKey];
    
    if (![apsDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    _categoryIdentifier = apsDictionary[kMPUserNotificationCategoryKey];
    
    id alert = apsDictionary[kMPUserNotificationAlertKey];
    
    if (!alert) {
        redactedNotificationString = dictionaryToString(notificationDictionary);
        return redactedNotificationString;
    }
    
    [mPushNotificationDictionary removeObjectForKey:kMPUserNotificationApsKey];
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
    
    mPushNotificationDictionary[kMPUserNotificationApsKey] = mAPSDictionary;
    
    redactedNotificationString = dictionaryToString(mPushNotificationDictionary);
    
    return redactedNotificationString;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_receiptTime forKey:@"receiptTime"];
    [coder encodeObject:_state forKey:@"state"];
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_uuid forKey:@"uuid"];
    [coder encodeInt64:_userNotificationId forKey:@"userNotificationId"];
    [coder encodeInteger:_behavior forKey:@"behavior"];
    [coder encodeInteger:_mode forKey:@"mode"];
    
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
    
    if (_localAlertDate) {
        [coder encodeObject:_localAlertDate forKey:@"localAlertDate"];
    }
    
    if (_deferredPayload) {
        [coder encodeObject:_deferredPayload forKey:@"deferredPayload"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldPersist = YES;
    _receiptTime = [coder decodeObjectOfClass:[NSDate class] forKey:@"receiptTime"];
    _state = [coder decodeObjectOfClass:[NSString class] forKey:@"state"];
    _type = [coder decodeObjectOfClass:[NSString class] forKey:@"type"];
    _uuid = [coder decodeObjectOfClass:[NSString class] forKey:@"uuid"];
    _userNotificationId = [coder decodeInt64ForKey:@"userNotificationId"];
    _behavior = [coder decodeIntegerForKey:@"behavior"];
    _mode = [coder decodeIntegerForKey:@"mode"];
    
    id object = [coder decodeObjectOfClass:[NSString class] forKey:@"categoryIdentifier"];
    if (object) {
        _categoryIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectOfClass:[NSString class] forKey:@"redactedUserNotificationString"];
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
    
    object = [coder decodeObjectForKey:@"localAlertDate"];
    if (object) {
        _localAlertDate = (NSDate *)object;
    }
    
    object = [coder decodeObjectForKey:@"deferredPayload"];
    if (object) {
        _deferredPayload = (NSDictionary *)object;
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

#endif
