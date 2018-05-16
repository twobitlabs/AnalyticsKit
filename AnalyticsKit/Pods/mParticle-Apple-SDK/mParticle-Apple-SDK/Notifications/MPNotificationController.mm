#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"
#include "MPHasher.h"
#import "MParticle.h"
#import "MPBackendController.h"

@interface MPNotificationController() {
    BOOL appJustFinishedLaunching;
    BOOL backgrounded;
    BOOL notificationLaunchedApp;
}

@end

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

#if TARGET_OS_IOS == 1
static NSData *deviceToken = nil;
static int64_t launchNotificationHash = 0;
#endif

@implementation MPNotificationController

#if TARGET_OS_IOS == 1

- (instancetype)initWithDelegate:(id<MPNotificationControllerDelegate>)delegate {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _delegate = delegate;
    _initialRedactedUserNotificationString = nil;
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
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIUserNotificationSettings *userNotificationSettings = nil;
    if ([NSThread isMainThread]) {
        userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    }

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
#pragma clang diagnostic pop
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UILocalNotification *launchLocalNotification = userInfo[UIApplicationLaunchOptionsLocalNotificationKey];
#pragma clang diagnostic pop
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
    
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];
    

    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeLocal
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    [self.delegate receivedUserNotification:userNotification];

}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];

    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeRemote
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    [self.delegate receivedUserNotification:userNotification];
}

#pragma mark Public static methods
+ (NSData *)deviceToken {
#ifndef MP_UNIT_TESTING
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    deviceToken = userDefaults[kMPDeviceTokenKey];
#else
    deviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif
    
    return deviceToken;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (NSDictionary *)dictionaryFromLocalNotification:(UILocalNotification *)notification {
#pragma clang diagnostic pop
    NSDictionary *userInfo = [notification userInfo];
    
    if (!userInfo) {
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
    
    NSMutableDictionary *notificationDictionary = [@{kMPUserNotificationApsKey:apsDictionary}
                                                   mutableCopy];
    
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
        NSString *newTokenString = nil;
        NSString *oldTokenString = nil;
        if (newDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationDeviceTokenKey] = newDeviceToken;
            newTokenString = [[NSString alloc] initWithData:newDeviceToken encoding:NSUTF8StringEncoding];
        }
        
        if (oldDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationOldDeviceTokenKey] = oldDeviceToken;
            oldTokenString = [[NSString alloc] initWithData:oldDeviceToken encoding:NSUTF8StringEncoding];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationDeviceTokenNotification
                                                            object:nil
                                                          userInfo:deviceTokenDictionary];
        
        if (oldTokenString && newTokenString) {
         [[MParticle sharedInstance].backendController.networkCommunication modifyDeviceID:@"push_token" value:newTokenString oldValue:oldTokenString];
        }
        
#ifndef MP_UNIT_TESTING
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
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
#endif

@end
