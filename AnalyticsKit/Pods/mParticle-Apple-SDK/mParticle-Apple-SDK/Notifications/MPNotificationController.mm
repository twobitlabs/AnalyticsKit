//
//  MPNotificationController.mm
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

#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "NSUserDefaults+mParticle.h"
#include "MPHasher.h"

@interface MPNotificationController() {
    BOOL appJustFinishedLaunching;
    BOOL backgrounded;
    BOOL notificationLaunchedApp;
}

@end

#if TARGET_OS_IOS == 1
static NSData *deviceToken = nil;
static int64_t launchNotificationHash = 0;
#endif

@implementation MPNotificationController

#if TARGET_OS_IOS == 1
@synthesize influencedOpenTimer = _influencedOpenTimer;

- (instancetype)initWithDelegate:(id<MPNotificationControllerDelegate>)delegate {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _delegate = delegate;
    _initialRedactedUserNotificationString = nil;
    _influencedOpenTimer = 0.0;
    appJustFinishedLaunching = YES;
    backgrounded = YES;
    notificationLaunchedApp = NO;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidFinishLaunching:)
                               name:UIApplicationDidFinishLaunchingNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleRemoteNotificationReceived:)
                               name:kMPRemoteNotificationReceivedNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleLocalNotificationReceived:)
                               name:kMPLocalNotificationReceivedNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:kMPRemoteNotificationReceivedNotification object:nil];
    [notificationCenter removeObserver:self name:kMPLocalNotificationReceivedNotification object:nil];
}

#pragma mark Private methods
- (BOOL)actionIdentifierBringsAppToTheForegound:(NSString *)actionIdentifier notificationDictionary:(NSDictionary *)notificationDictionary {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 || !actionIdentifier) {
        return NO;
    }
    
    NSDictionary *apsDictionary = notificationDictionary[kMPUserNotificationApsKey];
    NSString *categoryIdentifier = apsDictionary[kMPUserNotificationCategoryKey];
    if (!categoryIdentifier) {
        return NO;
    }
    
    UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (!userNotificationSettings) {
        return NO;
    }
    
    BOOL bringsToForeground = NO;
    for (UIUserNotificationCategory *category in userNotificationSettings.categories) {
        if ([category.identifier isEqualToString:categoryIdentifier]) {
            for (UIUserNotificationAction *action in [category actionsForContext:UIUserNotificationActionContextDefault]) {
                if ([action.identifier isEqualToString:actionIdentifier]) {
                    bringsToForeground = action.activationMode == UIUserNotificationActivationModeForeground;
                    break;
                }
            }
            
            break;
        }
    }
    
    return bringsToForeground;
}

- (void)verifyIfInfluencedOpen {
    NSTimeInterval referenceDate = [[[NSDate date] dateByAddingTimeInterval:(-self.influencedOpenTimer)] timeIntervalSince1970];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray<MParticleUserNotification *> *displayedLocalUserNotifications = [persistence fetchDisplayedLocalUserNotificationsSince:referenceDate];
    NSArray<MParticleUserNotification *> *displayedUserNotifications = [persistence fetchDisplayedRemoteUserNotificationsSince:referenceDate];
    
    if (displayedUserNotifications) {
        if (displayedLocalUserNotifications) {
            displayedUserNotifications = [displayedUserNotifications arrayByAddingObjectsFromArray:displayedLocalUserNotifications];
        }
    } else {
        displayedUserNotifications = displayedLocalUserNotifications;
    }
    
    if (!displayedUserNotifications) {
        return;
    }
    
    NSMutableArray *influencedUserNotifications = [[NSMutableArray alloc] initWithCapacity:displayedUserNotifications.count];
    MParticleUserNotification *userNotification;
    
    for (userNotification in displayedUserNotifications) {
        if (!userNotification.hasBeenUsedInDirectOpen && !userNotification.hasBeenUsedInInfluencedOpen && userNotification.campaignExpiration >= now) {
            userNotification.hasBeenUsedInInfluencedOpen = YES;
            userNotification.behavior = MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorInfluencedOpen;
            [influencedUserNotifications addObject:userNotification];
        }
    }
    
    if (influencedUserNotifications.count > 0) {
        for (userNotification in influencedUserNotifications) {
            [self.delegate receivedUserNotification:userNotification];
        }
    }
}

- (MParticleUserNotification *)userNotificationWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state userNotificationMode:(MPUserNotificationMode)userNotificationMode runningMode:(MPUserNotificationRunningMode)runningMode {
    if (!state) {
        state = backgrounded || actionIdentifier ? kMPPushNotificationStateBackground : kMPPushNotificationStateForeground;
    } else {
        state = state;
    }
    
    MPUserNotificationBehavior behavior = MPUserNotificationBehaviorReceived;
    
    if (notificationLaunchedApp || actionIdentifier) {
        notificationLaunchedApp = NO;
        
        behavior |= MPUserNotificationBehaviorRead;
        
        if ([self actionIdentifierBringsAppToTheForegound:actionIdentifier notificationDictionary:notificationDictionary]) {
            behavior |= MPUserNotificationBehaviorDirectOpen;
        }
    } else if (!notificationLaunchedApp && !actionIdentifier) {
        MPUserNotificationCommand command = static_cast<MPUserNotificationCommand>([notificationDictionary[kMPUserNotificationCommandKey] integerValue]);
        
        if (command != MPUserNotificationCommandAlertUserLocalTime) {
            behavior |= MPUserNotificationBehaviorDisplayed;
        }
    }
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:notificationDictionary
                                                                                       actionIdentifier:actionIdentifier
                                                                                                  state:state
                                                                                               behavior:behavior
                                                                                                   mode:userNotificationMode
                                                                                            runningMode:runningMode];
    
    return userNotification;
}

#pragma mark Notification handlers
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    appJustFinishedLaunching = YES;
    
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *launchRemoteNotificationDictionary = userInfo[UIApplicationLaunchOptionsRemoteNotificationKey];
    UILocalNotification *launchLocalNotification = userInfo[UIApplicationLaunchOptionsLocalNotificationKey];
    NSDictionary *launchLocalNotificationDictionary = nil;
    MParticleUserNotification *userNotification = nil;
    
    BOOL shouldDelegateReceivedRemoteNotification = NO;
    
    if (launchRemoteNotificationDictionary) {
        notificationLaunchedApp = YES;
        NSError *error = nil;
        NSData *remoteNotificationData = [NSJSONSerialization dataWithJSONObject:launchRemoteNotificationDictionary options:0 error:&error];
        
        if (!error && remoteNotificationData.length > 0) {
            launchNotificationHash = mParticle::Hasher::hashFNV1a(static_cast<const char *>([remoteNotificationData bytes]), static_cast<int>([remoteNotificationData length]));
        }

        NSDictionary *apsDictionary = launchRemoteNotificationDictionary[kMPUserNotificationApsKey];
        NSNumber *contentAvailable = apsDictionary[kMPUserNotificationContentAvailableKey];
        
        shouldDelegateReceivedRemoteNotification = ![contentAvailable boolValue];
        
        userNotification = [self newUserNotificationWithDictionary:launchRemoteNotificationDictionary
                                                  actionIdentifier:nil
                                                             state:kMPPushNotificationStateNotRunning];
        
        _initialRedactedUserNotificationString = userNotification.redactedUserNotificationString;
    } else if (launchLocalNotification) {
        notificationLaunchedApp = YES;
        shouldDelegateReceivedRemoteNotification = YES;
        
        launchLocalNotificationDictionary = [MPNotificationController dictionaryFromLocalNotification:launchLocalNotification];
        if (launchLocalNotificationDictionary) {
            userNotification = [self userNotificationWithDictionary:launchLocalNotificationDictionary
                                                   actionIdentifier:nil
                                                              state:kMPPushNotificationStateNotRunning
                                               userNotificationMode:MPUserNotificationModeLocal
                                                        runningMode:MPUserNotificationRunningModeForeground];
        }
    } else {
        notificationLaunchedApp = NO;
        [self verifyIfInfluencedOpen];
    }
    
    if (userNotification && shouldDelegateReceivedRemoteNotification) {
        [self.delegate receivedUserNotification:userNotification];
    }
}

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    backgrounded = YES;
    
    __weak MPNotificationController *weakSelf = self;
#ifndef MP_UNIT_TESTING
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        __strong MPNotificationController *strongSelf = weakSelf;
        
        if (strongSelf) {
            strongSelf->notificationLaunchedApp = NO;
            strongSelf->_initialRedactedUserNotificationString = nil;
        }
        
        launchNotificationHash = 0;
#ifndef MP_UNIT_TESTING
    });
#endif
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    __weak MPNotificationController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPNotificationController *strongSelf = weakSelf;
        
        if (strongSelf) {
            strongSelf->backgrounded = NO;
        }
    });
    
    if (appJustFinishedLaunching) {
        appJustFinishedLaunching = NO;
        return;
    }
    
    [self verifyIfInfluencedOpen];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];
    
    NSArray<MParticleUserNotification *> *displayedUserNotifications = [[MPPersistenceController sharedInstance] fetchDisplayedLocalUserNotifications];

    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeLocal
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    MParticleUserNotification *displayedUserNotification = nil;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL existingUserNotification = NO;
    
    for (displayedUserNotification in displayedUserNotifications) {
        existingUserNotification = [userNotification isEqual:displayedUserNotification];
        
        if (existingUserNotification) {
            displayedUserNotification.command = MPUserNotificationCommandAlertUser;
            
            if (displayedUserNotification.campaignExpiration >= now) {
                if (actionIdentifier) {
                    displayedUserNotification.actionIdentifier = actionIdentifier;
                    displayedUserNotification.actionTitle = userNotification.actionTitle;
                    displayedUserNotification.type = kMPPushMessageAction;
                }
                
                if (!displayedUserNotification.hasBeenUsedInInfluencedOpen && !displayedUserNotification.hasBeenUsedInDirectOpen) {
                    displayedUserNotification.behavior = MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorRead;
                    
                    if (!actionIdentifier || [self actionIdentifierBringsAppToTheForegound:actionIdentifier notificationDictionary:notificationDictionary]) {
                        displayedUserNotification.behavior |= MPUserNotificationBehaviorDirectOpen;
                        displayedUserNotification.hasBeenUsedInDirectOpen = YES;
                    } else if (displayedUserNotification.hasBeenUsedInInfluencedOpen && displayedUserNotification.type == kMPPushMessageAction) {
                        displayedUserNotification.behavior = MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorRead;
                        displayedUserNotification.shouldPersist = NO;
                    }
                }
            }
            
            break;
        }
    }
    
    if (existingUserNotification) {
        if (displayedUserNotification.campaignExpiration >= now) {
            [self.delegate receivedUserNotification:displayedUserNotification];
        }
    } else {
        [self.delegate receivedUserNotification:userNotification];
    }
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];
    
    NSArray<MParticleUserNotification *> *displayedUserNotifications = [[MPPersistenceController sharedInstance] fetchDisplayedRemoteUserNotifications];

    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeRemote
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    MParticleUserNotification *displayedUserNotification = nil;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL existingUserNotification = NO;
    
    for (displayedUserNotification in displayedUserNotifications) {
        existingUserNotification = [userNotification isEqual:displayedUserNotification];

        if (existingUserNotification) {
            if (displayedUserNotification.campaignExpiration >= now) {
                if (actionIdentifier) {
                    displayedUserNotification.actionIdentifier = actionIdentifier;
                    displayedUserNotification.actionTitle = userNotification.actionTitle;
                    displayedUserNotification.type = kMPPushMessageAction;
                }
                
                if (!displayedUserNotification.hasBeenUsedInInfluencedOpen && !displayedUserNotification.hasBeenUsedInDirectOpen) {
                    displayedUserNotification.behavior = MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorRead;
                    
                    if (!actionIdentifier || [self actionIdentifierBringsAppToTheForegound:actionIdentifier notificationDictionary:notificationDictionary]) {
                        displayedUserNotification.behavior |= MPUserNotificationBehaviorDirectOpen;
                        displayedUserNotification.hasBeenUsedInDirectOpen = YES;
                    }
                } else if (displayedUserNotification.hasBeenUsedInInfluencedOpen && displayedUserNotification.type == kMPPushMessageAction) {
                    displayedUserNotification.behavior = MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorRead;
                    displayedUserNotification.shouldPersist = NO;
                }
            }
            
            break;
        }
    }
    
    if (existingUserNotification) {
        if (!displayedUserNotification.hasBeenUsedInInfluencedOpen && !displayedUserNotification.hasBeenUsedInDirectOpen && displayedUserNotification.campaignExpiration >= now) {
            [self.delegate receivedUserNotification:displayedUserNotification];
        }
    } else {
        [self.delegate receivedUserNotification:userNotification];
    }
}

#pragma mark Public accessors
- (NSTimeInterval)influencedOpenTimer {
    if (_influencedOpenTimer > 0.0) {
        return _influencedOpenTimer;
    }
    
    NSNumber *influencedOpenNumber = nil;
#ifndef MP_UNIT_TESTING
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    influencedOpenNumber = userDefaults[kMPInfluencedOpenTimerKey];
#endif
    
    if (influencedOpenNumber) {
        _influencedOpenTimer = [influencedOpenNumber doubleValue];
    } else {
        _influencedOpenTimer = 1800;
    }
    
    return _influencedOpenTimer;
}

- (void)setInfluencedOpenTimer:(NSTimeInterval)influencedOpenTimer {
    void (^persistInfluencedOpenTimer)(NSNumber *) = ^(NSNumber *infOpenTimer) {
#ifndef MP_UNIT_TESTING
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            if (!infOpenTimer) {
                [userDefaults removeMPObjectForKey:kMPInfluencedOpenTimerKey];
                [userDefaults synchronize];
            } else {
                NSNumber *udInfOpenTimer = userDefaults[kMPInfluencedOpenTimerKey];
                if (!udInfOpenTimer || ![udInfOpenTimer isEqualToNumber:infOpenTimer]) {
                    userDefaults[kMPInfluencedOpenTimerKey] = infOpenTimer;
                    [userDefaults synchronize];
                }
            }
        });
#endif
    };
    
    influencedOpenTimer *= 60.0; // Transforms from minutes to seconds
    
    if (influencedOpenTimer == 0.0) {
        _influencedOpenTimer = 0.0;
        
        persistInfluencedOpenTimer(nil);
    } else if (_influencedOpenTimer != influencedOpenTimer) {
        [self willChangeValueForKey:@"influencedOpenTimer"];
        _influencedOpenTimer = influencedOpenTimer;
        [self didChangeValueForKey:@"influencedOpenTimer"];
        
        persistInfluencedOpenTimer(@(influencedOpenTimer));
    }
}

- (BOOL)registeredForSilentNotifications {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        return NO;
    }
    
    return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
}

#pragma mark Public static methods
+ (NSData *)deviceToken {
    if (deviceToken) {
        return deviceToken;
    }
    
#ifndef MP_UNIT_TESTING
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    deviceToken = userDefaults[kMPDeviceTokenKey];
#else
    deviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif
    
    return deviceToken;
}

+ (NSDictionary *)dictionaryFromLocalNotification:(UILocalNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    if (!userInfo || !userInfo[kMPUserNotificationCampaignIdKey] || !userInfo[kMPUserNotificationContentIdKey]) {
        return nil;
    }
    
    NSMutableDictionary *apsDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    apsDictionary[kMPUserNotificationAlertKey] = @{kMPUserNotificationBodyKey:notification.alertBody};
    apsDictionary[@"content-available"] = @1;

    if (notification.applicationIconBadgeNumber > 0) {
        apsDictionary[@"badge"] = @(notification.applicationIconBadgeNumber);
    }
    
    if (notification.soundName) {
        apsDictionary[@"sound"] = notification.soundName;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && notification.category) {
        apsDictionary[kMPUserNotificationCategoryKey] = notification.category;
    }
    
    NSMutableDictionary *notificationDictionary = [@{kMPUserNotificationApsKey:apsDictionary,
                                                     kMPUserNotificationCampaignIdKey:userInfo[kMPUserNotificationCampaignIdKey],
                                                     kMPUserNotificationContentIdKey:userInfo[kMPUserNotificationContentIdKey]}
                                                   mutableCopy];
    
    if (userInfo[kMPUserNotificationUniqueIdKey]) {
        notificationDictionary[kMPUserNotificationUniqueIdKey] = userInfo[kMPUserNotificationUniqueIdKey];
    }
    
    return (NSDictionary *)notificationDictionary;
}

+ (void)setDeviceToken:(NSData *)devToken {
    if ([MPNotificationController deviceToken] && [[MPNotificationController deviceToken] isEqualToData:devToken]) {
        return;
    }
    
    NSData *newDeviceToken = [devToken copy];
    NSData *oldDeviceToken = [deviceToken copy];
    
    deviceToken = devToken;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *deviceTokenDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        if (newDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationDeviceTokenKey] = newDeviceToken;
        }
        
        if (oldDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationOldDeviceTokenKey] = oldDeviceToken;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationDeviceTokenNotification
                                                            object:nil
                                                          userInfo:deviceTokenDictionary];
        
#ifndef MP_UNIT_TESTING
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        userDefaults[kMPDeviceTokenKey] = deviceToken;
        [userDefaults synchronize];
#endif
    });
}

+ (int64_t)launchNotificationHash {
    return launchNotificationHash;
}

#pragma mark Public methods
- (MParticleUserNotification *)newUserNotificationWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state {
    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:state
                                                                  userNotificationMode:MPUserNotificationModeRemote
                                                                           runningMode:MPUserNotificationRunningModeForeground];
    
    return userNotification;
}

- (void)registerForSilentNotifications {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        return;
    }
    
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSArray *backgroundModes = bundleInfoDictionary[@"UIBackgroundModes"];
    if ([backgroundModes containsObject:@"remote-notification"]) {
#if !TARGET_IPHONE_SIMULATOR
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    }
}

- (void)scheduleNotification:(MParticleUserNotification *)userNotification {
    if (!userNotification || userNotification.mode != MPUserNotificationModeLocal || [userNotification.localAlertDate compare:[NSDate date]] != NSOrderedDescending) {
        return;
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = userNotification.localAlertDate;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    NSMutableDictionary *userInfo = [@{kMPUserNotificationCampaignIdKey:userNotification.campaignId,
                                       kMPUserNotificationContentIdKey:userNotification.contentId}
                                     mutableCopy];
    
    if (userNotification.uniqueIdentifier) {
        userInfo[kMPUserNotificationUniqueIdKey] = userNotification.uniqueIdentifier;
    }
    
    localNotification.userInfo = userInfo;

    NSDictionary *apsDictionary = userNotification.deferredPayload[kMPUserNotificationApsKey];
    
    id alert = apsDictionary[kMPUserNotificationAlertKey];
    NSString *alertBody = nil;
    if ([alert isKindOfClass:[NSDictionary class]]) {
        alertBody = [(NSDictionary *)alert objectForKey:kMPUserNotificationBodyKey];
    } else if ([alert isKindOfClass:[NSString class]]) {
        alertBody = (NSString *)alert;
    }
    
    if (alertBody) {
        localNotification.alertBody = alertBody;
    }
    
    if (apsDictionary[@"badge"]) {
        localNotification.applicationIconBadgeNumber = [apsDictionary[@"badge"] intValue];
    }
    
    if (apsDictionary[@"sound"]) {
        localNotification.soundName = apsDictionary[@"sound"];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationSettings *notificationSettings = [app currentUserNotificationSettings];
        if (notificationSettings.types == UIUserNotificationTypeNone) {
            return;
        }

        NSString *category = apsDictionary[kMPUserNotificationCategoryKey];
        
        if (category) {
            localNotification.category = category;
        }
    }
    
    [app scheduleLocalNotification:localNotification];
}
#endif

@end
