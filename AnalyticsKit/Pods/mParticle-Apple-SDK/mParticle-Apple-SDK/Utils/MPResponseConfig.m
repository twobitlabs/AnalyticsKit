//
//  MPResponseConfig.m
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

#import "MPResponseConfig.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"
#import "NSUserDefaults+mParticle.h"

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
        [[MPKitContainer sharedInstance] configureKits:_configuration[kMPRemoteConfigKitsKey]];
        
        stateMachine.latestSDKVersion = _configuration[kMPRemoteConfigLatestSDKVersionKey];
        [stateMachine configureCustomModules:_configuration[kMPRemoteConfigCustomModuleSettingsKey]];
        [stateMachine configureRampPercentage:_configuration[kMPRemoteConfigRampKey]];
        [stateMachine configureTriggers:_configuration[kMPRemoteConfigTriggerKey]];
        [stateMachine configureRestrictIDFA:_configuration[kMPRemoteConfigRestrictIDFA]];
    }
    
    _influencedOpenTimer = !MPIsNull(_configuration[kMPRemoteConfigInfluencedOpenTimerKey]) ? _configuration[kMPRemoteConfigInfluencedOpenTimerKey] : nil;
    
    // Exception handling
    NSString *auxString = !MPIsNull(_configuration[kMPRemoteConfigExceptionHandlingModeKey]) ? _configuration[kMPRemoteConfigExceptionHandlingModeKey] : nil;
    if (auxString) {
        stateMachine.exceptionHandlingMode = [auxString copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPConfigureExceptionHandlingNotification
                                                            object:nil
                                                          userInfo:nil];
    }
    
    // Network performance
    auxString = !MPIsNull(_configuration[kMPRemoteConfigNetworkPerformanceModeKey]) ? _configuration[kMPRemoteConfigNetworkPerformanceModeKey] : nil;
    if (auxString) {
        [self configureNetworkPerformanceMeasurement:auxString];
    }
    
    // Session timeout
    NSNumber *auxNumber = _configuration[kMPRemoteConfigSessionTimeoutKey];
    if (auxNumber) {
        [MParticle sharedInstance].sessionTimeout = [auxNumber doubleValue];
    }
    
    // Upload interval
    auxNumber = !MPIsNull(_configuration[kMPRemoteConfigUploadIntervalKey]) ? _configuration[kMPRemoteConfigUploadIntervalKey] : nil;
    if (auxNumber) {
        [MParticle sharedInstance].uploadInterval = [auxNumber doubleValue];
    }
    
    // Session history
    auxNumber = !MPIsNull(_configuration[kMPRemoteConfigIncludeSessionHistory]) ? _configuration[kMPRemoteConfigIncludeSessionHistory] : nil;
    stateMachine.shouldUploadSessionHistory = auxNumber ? [auxNumber boolValue] : YES;
    
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
- (void)configureNetworkPerformanceMeasurement:(NSString *)networkPerformanceMeasuringMode {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];

    if ([networkPerformanceMeasuringMode isEqualToString:stateMachine.networkPerformanceMeasuringMode]) {
        return;
    }
    
    stateMachine.networkPerformanceMeasuringMode = [networkPerformanceMeasuringMode copy];
    
    if ([stateMachine.networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceTrue]) {
        [[MParticle sharedInstance] beginMeasuringNetworkPerformance];
    } else if ([stateMachine.networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [[MParticle sharedInstance] endMeasuringNetworkPerformance];
    }
}

#pragma mark Public class methods
+ (void)save:(nonnull MPResponseConfig *)responseConfig {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    if (!responseConfig || !responseConfig.configuration) {
        // If a kit is registered against the core SDK, there is an eTag present, and there is no corresponding kit configuration, then
        // delete the saved eTag, thus "forcing" a config refresh on the next call to the server
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
        if (!eTag) {
            return;
        }

        NSArray<NSNumber *> *supportedKits = [[MPKitContainer sharedInstance] supportedKits];
        for (NSNumber *kitCode in supportedKits) {
            NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.eks", kitCode]];

            if (![fileManager fileExistsAtPath:kitPath]) {
                [userDefaults removeMPObjectForKey:kMPHTTPETagHeaderKey];
                break;
            }
        }

        return;
    }

    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];
    
    if ([fileManager fileExistsAtPath:configurationPath]) {
        [fileManager removeItemAtPath:configurationPath error:nil];
    }
    
    BOOL configurationArchived = [NSKeyedArchiver archiveRootObject:responseConfig.configuration toFile:configurationPath];
    if (!configurationArchived) {
        MPILogError(@"RequestConfig could not be archived.");
    }
}

+ (nullable MPResponseConfig *)restore {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];

    if (![fileManager fileExistsAtPath:configurationPath]) {
        return nil;
    }
    
    NSDictionary *configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:configurationPath];
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
}
#endif

@end
