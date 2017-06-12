//
//  MPStateMachine.h
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

#import "MPIConstants.h"
#import "MPEnums.h"
#import "MPLaunchInfo.h"
#import "MParticleReachability.h"

@class MPSession;
@class MPNotificationController;
@class MPConsumerInfo;
@class MPBags;
@class MPLocationManager;
@class MPCustomModule;
@class MPSearchAdsAttribution;
#if TARGET_OS_IOS == 1
    @class CLLocation;
#endif

typedef NS_ENUM(NSUInteger, MPConsoleLogging) {
    MPConsoleLoggingAutoDetect = 0,
    MPConsoleLoggingDisplay,
    MPConsoleLoggingSuppress
};

@interface MPStateMachine : NSObject

@property (nonatomic, strong, nonnull) NSString *apiKey __attribute__((const));
@property (nonatomic, strong, nonnull) MPBags *bags;
@property (nonatomic, strong, nonnull) MPConsumerInfo *consumerInfo;
@property (nonatomic, weak, nullable) MPSession *currentSession;
@property (nonatomic, strong, nullable) NSArray<MPCustomModule *> *customModules;
@property (nonatomic, strong, nullable) NSString *exceptionHandlingMode;
@property (nonatomic, strong, nullable) NSString *locationTrackingMode;
@property (nonatomic, strong, nullable) NSString *latestSDKVersion;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
#if TARGET_OS_IOS == 1
@property (nonatomic, strong, nullable) CLLocation *location;
#endif
@property (nonatomic, strong, nullable) MPLocationManager *locationManager;
@property (nonatomic, strong, nonnull) NSDate *minUploadDate;
@property (nonatomic, strong, nullable) NSString *networkPerformanceMeasuringMode;
@property (nonatomic, strong, nullable) NSString *pushNotificationMode;
@property (nonatomic, strong, nonnull) NSString *secret __attribute__((const));
@property (nonatomic, strong, nonnull) NSDate *startTime;
@property (nonatomic, strong, nullable) MPLaunchInfo *launchInfo;
@property (nonatomic, strong, readonly, nullable) NSString *deviceTokenType;
@property (nonatomic, strong, readonly, nonnull) NSNumber *firstSeenInstallation;
@property (nonatomic, strong, readonly, nullable) NSDate *launchDate;
@property (nonatomic, strong, readonly, nullable) NSArray *triggerEventTypes;
@property (nonatomic, strong, readonly, nullable) NSArray *triggerMessageTypes;
@property (nonatomic, unsafe_unretained) MPConsoleLogging consoleLogging;
@property (nonatomic, unsafe_unretained) MPILogLevel logLevel;
@property (nonatomic, unsafe_unretained) MPInstallationType installationType;
@property (nonatomic, unsafe_unretained, readonly) MParticleNetworkStatus networkStatus;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;
@property (nonatomic, unsafe_unretained, readonly) BOOL backgrounded;
@property (nonatomic, unsafe_unretained, readonly) BOOL dataRamped;
@property (nonatomic, unsafe_unretained) BOOL optOut;
@property (nonatomic, unsafe_unretained) BOOL alwaysTryToCollectIDFA;
@property (nonatomic, unsafe_unretained) BOOL shouldUploadSessionHistory;
@property (nonatomic, strong, nonnull) MPSearchAdsAttribution *searchAttribution;

+ (nonnull instancetype)sharedInstance;
+ (MPEnvironment)environment;
+ (void)setEnvironment:(MPEnvironment)environment;
+ (nullable NSString *)provisioningProfileString;
+ (BOOL)runningInBackground;
+ (void)setRunningInBackground:(BOOL)background;
- (void)configureCustomModules:(nullable NSArray<NSDictionary *> *)customModuleSettings;
- (void)configureRampPercentage:(nullable NSNumber *)rampPercentage;
- (void)configureTriggers:(nullable NSDictionary *)triggerDictionary;
- (void)configureRestrictIDFA:(nullable NSNumber *)restrictIDFA;

@end
