#import "MPResponseConfig.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPPersistenceController.h"
#import "MPApplication.h"
#import "MPBackendController.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@interface MParticle ()

@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *deferredKitConfiguration;
@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;
@property (nonatomic, strong, readonly) MPKitContainer *kitContainer;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

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
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    if (dataReceivedFromServer) {
        BOOL hasConsentFilters = NO;
        
        if (!MPIsNull(self->_configuration[kMPRemoteConfigKitsKey])) {
            for (NSDictionary *kitDictionary in self->_configuration[kMPRemoteConfigKitsKey]) {
                
                NSDictionary *consentKitFilter = kitDictionary[kMPConsentKitFilter];
                BOOL hasConsentKitFilter = MPIsNonEmptyDictionary(consentKitFilter);
                
                BOOL hasRegulationOrPurposeFilters = NO;
                
                NSDictionary *hashes = kitDictionary[kMPRemoteConfigKitHashesKey];
                
                if (MPIsNonEmptyDictionary(hashes)) {
                    
                    NSDictionary *regulationFilters = hashes[kMPConsentRegulationFilters];
                    NSDictionary *purposeFilters = hashes[kMPConsentPurposeFilters];
                    
                    BOOL hasRegulationFilters = MPIsNonEmptyDictionary(regulationFilters);
                    BOOL hasPurposeFilters = MPIsNonEmptyDictionary(purposeFilters);
                    
                    if (hasRegulationFilters || hasPurposeFilters) {
                        hasRegulationOrPurposeFilters = YES;
                    }
                    
                }
                
                if (hasConsentKitFilter || hasRegulationOrPurposeFilters) {
       
                    hasConsentFilters = YES;
                    break;
                    
                }
            }
        }
        
        
        NSNumber *mpid = [MPPersistenceController mpId];
        BOOL hasInitialIdentity = mpid != nil && ![mpid isEqual:@0];
        
        BOOL shouldDefer = hasConsentFilters && !hasInitialIdentity;
        
        if (!shouldDefer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MParticle sharedInstance].kitContainer configureKits:self->_configuration[kMPRemoteConfigKitsKey]];
            });
        } else {
            [MParticle sharedInstance].deferredKitConfiguration = [self->_configuration[kMPRemoteConfigKitsKey] copy];
        }
        
    }
    
    [stateMachine configureCustomModules:_configuration[kMPRemoteConfigCustomModuleSettingsKey]];
    [stateMachine configureRampPercentage:_configuration[kMPRemoteConfigRampKey]];
    [stateMachine configureTriggers:_configuration[kMPRemoteConfigTriggerKey]];
    [stateMachine configureRestrictIDFA:_configuration[kMPRemoteConfigRestrictIDFA]];
    [stateMachine configureAliasMaxWindow:_configuration[kMPRemoteConfigAliasMaxWindow]];
    stateMachine.allowASR = [_configuration[kMPRemoteConfigAllowASR] boolValue];
        
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
        [MParticle sharedInstance].backendController.sessionTimeout = [auxNumber doubleValue];
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

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_configuration forKey:@"configuration"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSDictionary *configuration = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"configuration"];
    self = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Private methods

#pragma mark Public class methods
+ (nullable MPResponseConfig *)restore {
    NSDictionary *configuration = [[MPIUserDefaults standardUserDefaults] getConfiguration];
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return responseConfig;
}

#pragma mark Public instance methods
#if TARGET_OS_IOS == 1
- (void)configureLocationTracking:(NSDictionary *)locationDictionary {
    NSString *locationMode = locationDictionary[kMPRemoteConfigLocationModeKey];
    [MParticle sharedInstance].stateMachine.locationTrackingMode = locationMode;
    
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
    [MParticle sharedInstance].stateMachine.pushNotificationMode = pushNotificationMode;
    if (![MPStateMachine isAppExtension]) {
        UIApplication *app = [MPApplication sharedUIApplication];
        
        if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceTrue]) {
            NSNumber *pushNotificationType = pushNotificationDictionary[kMPRemoteConfigPushNotificationTypeKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [app registerForRemoteNotificationTypes:[pushNotificationType integerValue]];
#pragma clang diagnostic pop
        } else if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceFalse]) {
            [app unregisterForRemoteNotifications];
        }
    }
}
#endif

@end
