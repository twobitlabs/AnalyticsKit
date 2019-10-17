#import "MPIConstants.h"
#import "MPEnums.h"

@class UIApplication;

extern NSString * _Nonnull const kMPApplicationInformationKey;

@interface MPApplication : NSObject <NSCopying>

@property (nonatomic, strong, nonnull) NSNumber *lastUseDate;
@property (nonatomic, strong, nullable) NSNumber *launchCount;
@property (nonatomic, strong, nullable) NSNumber *launchCountSinceUpgrade;
@property (nonatomic, strong, nullable) NSString *storedBuild;
@property (nonatomic, strong, nullable) NSString *storedVersion;
@property (nonatomic, strong, nullable) NSNumber *upgradeDate;
@property (nonatomic, strong, readonly, nonnull) NSString *architecture;
@property (nonatomic, strong, readonly, nullable) NSString *build __attribute__((const));
@property (nonatomic, strong, readonly, nullable) NSString *buildUUID;
@property (nonatomic, strong, readonly, nullable) NSString *bundleIdentifier __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *firstSeenInstallation __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *initialLaunchTime;
@property (nonatomic, strong, readonly, nullable) NSString *name __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *pirated;
@property (nonatomic, strong, readonly, nullable) NSString *version __attribute__((const));
@property (nonatomic, unsafe_unretained, readonly) MPEnvironment environment __attribute__((const));

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, readonly, nullable) NSNumber *badgeNumber;
@property (nonatomic, strong, readonly, nullable) NSNumber *remoteNotificationTypes;
#endif

+ (nullable NSString *)appStoreReceipt;
+ (void)markInitialLaunchTime;
+ (void)updateLastUseDate:(nonnull NSDate *)date;
+ (void)updateLaunchCountsAndDates;
+ (void)updateStoredVersionAndBuildNumbers;
+ (UIApplication *_Nullable)sharedUIApplication;
- (nonnull NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end
