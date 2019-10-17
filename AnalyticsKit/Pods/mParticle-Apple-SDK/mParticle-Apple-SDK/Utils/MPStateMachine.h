#import "MPIConstants.h"
#import "MPEnums.h"
#import "MPLaunchInfo.h"
#import "MParticleReachability.h"

@class MPSession;
@class MPNotificationController;
@class MPConsumerInfo;
@class MPLocationManager;
@class MPCustomModule;
@class MPSearchAdsAttribution;
#if TARGET_OS_IOS == 1
    @class CLLocation;
#endif

@interface MPStateMachine : NSObject

@property (nonatomic, strong, nonnull) NSString *apiKey __attribute__((const));
@property (nonatomic, strong, nonnull) MPConsumerInfo *consumerInfo;
@property (nonatomic, weak, nullable) MPSession *currentSession;
@property (nonatomic, strong, nullable) NSArray<MPCustomModule *> *customModules;
@property (nonatomic, strong, nullable) NSString *exceptionHandlingMode;
@property (nonatomic, strong, nullable) NSString *locationTrackingMode;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
#if TARGET_OS_IOS == 1
@property (nonatomic, strong, nullable) CLLocation *location;
#endif
@property (nonatomic, strong, nullable) MPLocationManager *locationManager;
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
@property (nonatomic, unsafe_unretained) MPILogLevel logLevel;
@property (nonatomic, unsafe_unretained) MPInstallationType installationType;
@property (nonatomic, unsafe_unretained, readonly) MParticleNetworkStatus networkStatus;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;
@property (nonatomic, unsafe_unretained, readonly) BOOL backgrounded;
@property (nonatomic, unsafe_unretained, readonly) BOOL dataRamped;
@property (nonatomic, unsafe_unretained) BOOL optOut;
@property (nonatomic, unsafe_unretained) BOOL alwaysTryToCollectIDFA;
@property (nonatomic, strong, nonnull) NSNumber *aliasMaxWindow;
@property (nonatomic, strong, nonnull) MPSearchAdsAttribution *searchAttribution;
@property (nonatomic, strong, nonnull) NSDictionary *searchAdsInfo;
@property (nonatomic, assign) BOOL automaticSessionTracking;
@property (nonatomic, assign) BOOL allowASR;

+ (MPEnvironment)environment;
+ (void)setEnvironment:(MPEnvironment)environment;
+ (nullable NSString *)provisioningProfileString;
+ (BOOL)runningInBackground;
+ (void)setRunningInBackground:(BOOL)background;
+ (BOOL)isAppExtension;
- (void)configureCustomModules:(nullable NSArray<NSDictionary *> *)customModuleSettings;
- (void)configureRampPercentage:(nullable NSNumber *)rampPercentage;
- (void)configureTriggers:(nullable NSDictionary *)triggerDictionary;
- (void)configureRestrictIDFA:(nullable NSNumber *)restrictIDFA;
- (void)configureAliasMaxWindow:(nullable NSNumber *)aliasMaxWindow;
- (void)setMinUploadDate:(nullable NSDate *)date uploadType:(MPUploadType)uploadType;
- (nonnull NSDate *)minUploadDateForUploadType:(MPUploadType)uploadType;

@end
