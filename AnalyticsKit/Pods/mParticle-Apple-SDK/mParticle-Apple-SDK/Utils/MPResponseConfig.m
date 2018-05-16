#import "MPResponseConfig.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@implementation MPResponseConfig

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    return [self initWithConfiguration:configuration dataReceivedFromServer:YES];
}

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration dataReceivedFromServer:(BOOL)dataReceivedFromServer {
    self = [super init];
    if (!self || MPIsNull(configuration)) {
        return nil;
    }

    _configuration = [configuration copy];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (dataReceivedFromServer) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[MPKitContainer sharedInstance] configureKits:self->_configuration[kMPRemoteConfigKitsKey]];
        });
    }
    
    [stateMachine configureCustomModules:_configuration[kMPRemoteConfigCustomModuleSettingsKey]];
    [stateMachine configureRampPercentage:_configuration[kMPRemoteConfigRampKey]];
    [stateMachine configureTriggers:_configuration[kMPRemoteConfigTriggerKey]];
    [stateMachine configureRestrictIDFA:_configuration[kMPRemoteConfigRestrictIDFA]];
        
    // Exception handling
    NSString *auxString = !MPIsNull(_configuration[kMPRemoteConfigExceptionHandlingModeKey]) ? _configuration[kMPRemoteConfigExceptionHandlingModeKey] : nil;
    if (auxString) {
        stateMachine.exceptionHandlingMode = [auxString copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPConfigureExceptionHandlingNotification
                                                            object:nil
                                                          userInfo:nil];
    }
    
    // Session timeout
    NSNumber *auxNumber = _configuration[kMPRemoteConfigSessionTimeoutKey];
    if (auxNumber != nil) {
        [MParticle sharedInstance].sessionTimeout = [auxNumber doubleValue];
    }
    
#if TARGET_OS_IOS == 1
    // Push notifications
    NSDictionary *auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigPushNotificationDictionaryKey]) ? _configuration[kMPRemoteConfigPushNotificationDictionaryKey] : nil;
    if (auxDictionary) {
        [self configurePushNotifications:auxDictionary];
    }
    
    // Location tracking
    auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigLocationKey]) ? _configuration[kMPRemoteConfigLocationKey] : nil;
    if (auxDictionary) {
        [self configureLocationTracking:auxDictionary];
    }
#endif
    
    return self;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_configuration forKey:@"configuration"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSDictionary *configuration = [coder decodeObjectForKey:@"configuration"];
    self = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return self;
}

#pragma mark Private methods

#pragma mark Public class methods
+ (void)save:(nonnull MPResponseConfig *)responseConfig eTag:(nonnull NSString *)eTag {
    if (responseConfig && responseConfig.configuration) {
        [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfig.configuration andETag:eTag];
    }
}

+ (nullable MPResponseConfig *)restore {
    NSDictionary *configuration = [[MPIUserDefaults standardUserDefaults] getConfiguration];
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return responseConfig;
}

#pragma mark Public instance methods
#if TARGET_OS_IOS == 1
- (void)configureLocationTracking:(NSDictionary *)locationDictionary {
    NSString *locationMode = locationDictionary[kMPRemoteConfigLocationModeKey];
    [MPStateMachine sharedInstance].locationTrackingMode = locationMode;
    
    if ([locationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *accurary = locationDictionary[kMPRemoteConfigLocationAccuracyKey];
        NSNumber *minimumDistance = locationDictionary[kMPRemoteConfigLocationMinimumDistanceKey];
        
        [[MParticle sharedInstance] beginLocationTracking:[accurary doubleValue] minDistance:[minimumDistance doubleValue] authorizationRequest:MPLocationAuthorizationRequestAlways];
    } else if ([locationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [[MParticle sharedInstance] endLocationTracking];
    }
}

- (void)configurePushNotifications:(NSDictionary *)pushNotificationDictionary {
    NSString *pushNotificationMode = pushNotificationDictionary[kMPRemoteConfigPushNotificationModeKey];
    [MPStateMachine sharedInstance].pushNotificationMode = pushNotificationMode;
#if !defined(MPARTICLE_APP_EXTENSIONS)
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *pushNotificationType = pushNotificationDictionary[kMPRemoteConfigPushNotificationTypeKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [app registerForRemoteNotificationTypes:[pushNotificationType integerValue]];
#pragma clang diagnostic pop
    } else if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [app unregisterForRemoteNotifications];
    }
#endif
}
#endif

@end
