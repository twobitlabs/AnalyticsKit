#import "MPApplication.h"
#import <mach-o/ldsyms.h>
#import <dlfcn.h>
#import <mach-o/arch.h>
#import <mach-o/dyld.h>
#import "MPIUserDefaults.h"
#import <UIKit/UIKit.h>
#import "MPStateMachine.h"
#import "MPSearchAdsAttribution.h"
#import "MParticle.h"

NSString *const kMPApplicationInformationKey = @"ai";
NSString *const kMPApplicationNameKey = @"an";
NSString *const kMPApplicationVersionKey = @"av";
NSString *const kMPAppPackageNameKey = @"apn";
NSString *const kMPAppInitialLaunchTimeKey = @"ict";
NSString *const kMPAppBuildNumberKey = @"abn";
NSString *const kMPAppBuildUUIDKey = @"bid";
NSString *const kMPAppArchitectureKey = @"arc";
NSString *const kMPAppPiratedKey = @"pir";
NSString *const kMPAppDeploymentTargetKey = @"tsv";
NSString *const kMPAppBuildSDKKey = @"bsv";
NSString *const kMPAppUpgradeDateKey = @"ud";
NSString *const kMPAppLaunchCountKey = @"lc";
NSString *const kMPAppLaunchCountSinceUpgradeKey = @"lcu";
NSString *const kMPAppLastUseDateKey = @"lud";
NSString *const kMPAppStoredVersionKey = @"asv";
NSString *const kMPAppStoredBuildKey = @"asb";
NSString *const kMPAppEnvironmentKey = @"env";
NSString *const kMPAppBadgeNumberKey = @"bn";
NSString *const kMPAppStoreReceiptKey = @"asr";

static NSString *kMPAppStoreReceiptString = nil;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@interface MPApplication() {
    NSDictionary *appInfo;
    MPIUserDefaults *userDefaults;
    BOOL syncUserDefaults;
}

@end


@implementation MPApplication

@synthesize architecture = _architecture;
@synthesize buildUUID = _buildUUID;
@synthesize environment = _environment;
@synthesize initialLaunchTime = _initialLaunchTime;
@synthesize pirated = _pirated;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    userDefaults = [MPIUserDefaults standardUserDefaults];
    syncUserDefaults = NO;
    
    return self;
}

- (void)dealloc {
    if (syncUserDefaults) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MPIUserDefaults standardUserDefaults] synchronize];
        });
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark Accessors
- (NSString *)architecture {
    if (_architecture) {
        return _architecture;
    }
    
    const struct mach_header *header = _dyld_get_image_header(0);
    const NXArchInfo *info = NXGetArchInfoFromCpuType(header->cputype, header->cpusubtype);
    
    _architecture = [[NSString alloc] initWithUTF8String:info->name];
    
    return _architecture;
}

- (NSString *)build {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleVersion"];
}

- (NSString *)buildUUID {
#if !TARGET_OS_SIMULATOR
    if (_buildUUID) {
        return _buildUUID;
    }
    
    const struct mach_header *machHeader = NULL;
    uint32_t i;
    
    for (i = 0; i < _dyld_image_count(); ++i) {
        const struct mach_header *header = _dyld_get_image_header(i);
        
        if (header->filetype == MH_EXECUTE) {
            machHeader = header;
            break;
        }
    }
    
    if (machHeader == NULL) {
        return nil;
    }
    
    BOOL is64bit = machHeader->magic == MH_MAGIC_64 || machHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)machHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (i = 0; i < machHeader->ncmds; ++i, cursor += segmentCommand->cmdsize) {
        segmentCommand = (struct segment_command *)cursor;
        
        if (segmentCommand->cmd == LC_UUID) {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            _buildUUID = [[[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid] UUIDString];
            break;
        }
    }
    
    return _buildUUID;
#endif
    return @"00000000-0000-0000-0000-000000000000";
}

- (NSString *)bundleIdentifier {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleIdentifier"];
}

- (MPEnvironment)environment {
    return [MPStateMachine environment];
}

- (NSNumber *)firstSeenInstallation {
    return [MParticle sharedInstance].stateMachine.firstSeenInstallation;
}

- (NSNumber *)initialLaunchTime {
    if (_initialLaunchTime != nil) {
        return _initialLaunchTime;
    }
    
    _initialLaunchTime = userDefaults[kMPAppInitialLaunchTimeKey];
    
    if (_initialLaunchTime == nil) {
        _initialLaunchTime = MPCurrentEpochInMilliseconds;
        userDefaults[kMPAppInitialLaunchTimeKey] = _initialLaunchTime;
        syncUserDefaults = YES;
    }
    
    return _initialLaunchTime;
}

- (NSString *)name {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleDisplayName"];
}

- (NSNumber *)lastUseDate {
    NSNumber *lastUseDate = userDefaults[kMPAppLastUseDateKey];
    if (lastUseDate == nil) {
        lastUseDate = MPMilliseconds([[MParticle sharedInstance].stateMachine.launchDate timeIntervalSince1970]);
    }
    
    return lastUseDate;
}

- (void)setLastUseDate:(NSNumber *)lastUseDate {
    userDefaults[kMPAppLastUseDateKey] = lastUseDate;
    syncUserDefaults = YES;
}

- (NSNumber *)launchCount {
    NSNumber *launchCount = userDefaults[kMPAppLaunchCountKey];
    return launchCount;
}

- (void)setLaunchCount:(NSNumber *)launchCount {
    userDefaults[kMPAppLaunchCountKey] = launchCount;
    syncUserDefaults = YES;
}

- (NSNumber *)launchCountSinceUpgrade {
    NSNumber *launchCount = userDefaults[kMPAppLaunchCountSinceUpgradeKey];
    return launchCount;
}

- (void)setLaunchCountSinceUpgrade:(NSNumber *)launchCountSinceUpgrade {
    userDefaults[kMPAppLaunchCountSinceUpgradeKey] = launchCountSinceUpgrade;
    syncUserDefaults = YES;
}

- (NSNumber *)pirated {
    _pirated = @(NO);
    return _pirated;
}

- (NSString *)storedBuild {
    NSString *storedBuild = userDefaults[kMPAppStoredBuildKey];
    return storedBuild;
}

- (void)setStoredBuild:(NSString *)storedBuild {
    if (storedBuild) {
        userDefaults[kMPAppStoredBuildKey] = storedBuild;
    } else {
        [userDefaults removeMPObjectForKey:kMPAppStoredBuildKey];
    }
    
    syncUserDefaults = YES;
}

- (NSString *)storedVersion {
    NSString *storedBuild = userDefaults[kMPAppStoredVersionKey];
    return storedBuild;
}

- (void)setStoredVersion:(NSString *)storedVersion {
    if (storedVersion) {
        userDefaults[kMPAppStoredVersionKey] = storedVersion;
    } else {
        [userDefaults removeMPObjectForKey:kMPAppStoredVersionKey];
    }
    
    syncUserDefaults = YES;
}

- (NSNumber *)upgradeDate {
    NSNumber *upgradeDate = userDefaults[kMPAppUpgradeDateKey];
    return upgradeDate;
}

- (void)setUpgradeDate:(NSNumber *)upgradeDate {
    userDefaults[kMPAppUpgradeDateKey] = upgradeDate;
    syncUserDefaults = YES;
}

- (NSString *)version {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleShortVersionString"];
}

+ (UIApplication *)sharedUIApplication {
    if ([[UIApplication class] respondsToSelector:@selector(sharedApplication)]) {
        return [[UIApplication class] performSelector:@selector(sharedApplication)];
    }
    return nil;
}

#if TARGET_OS_IOS == 1
- (NSNumber *)badgeNumber {
    if (![MPStateMachine isAppExtension]) {
        __block NSInteger appBadgeNumber = 0;
        if ([NSThread isMainThread]) {
            appBadgeNumber = [MPApplication sharedUIApplication].applicationIconBadgeNumber;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                appBadgeNumber = [MPApplication sharedUIApplication].applicationIconBadgeNumber;
            });
        }
        NSNumber *badgeNumber = appBadgeNumber != 0 ? @(appBadgeNumber) : nil;
        
        return badgeNumber;
    }
    return 0;
}

- (NSNumber *)remoteNotificationTypes {
    NSNumber *notificationTypes;
    
    if (![MPStateMachine isAppExtension]) {
        UIApplication *app = [[UIApplication class] performSelector:@selector(sharedApplication)];
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            __block UIUserNotificationSettings *userNotificationSettings = nil;
            if ([NSThread isMainThread]) {
                userNotificationSettings = [app currentUserNotificationSettings];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    userNotificationSettings = [app currentUserNotificationSettings];
                });
            }
            
#pragma clang diagnostic pop
            notificationTypes = @(userNotificationSettings.types);
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            notificationTypes = @([app enabledRemoteNotificationTypes]);
#pragma clang diagnostic pop
        }
    }
    
    return notificationTypes;
}
#endif

- (NSDictionary *)searchAdsAttribution {
    return MParticle.sharedInstance.stateMachine.searchAdsInfo;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MPApplication *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_architecture = [_architecture copy];
        copyObject->_buildUUID = [_buildUUID copy];
        copyObject->_initialLaunchTime = [_initialLaunchTime copy];
        copyObject->_pirated = [_pirated copy];
    }
    
    return copyObject;
}

#pragma mark Class methods
+ (NSString *)appStoreReceipt {
    if (MPIsNull(kMPAppStoreReceiptString)) {
        NSURL *url = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *appStoreReceiptData = [NSData dataWithContentsOfURL:url];
        
        if (appStoreReceiptData) {
            kMPAppStoreReceiptString = [appStoreReceiptData base64EncodedStringWithOptions:0];
        }
    }
    
    return kMPAppStoreReceiptString;
}

+ (void)markInitialLaunchTime {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *initialLaunchTime = userDefaults[kMPAppInitialLaunchTimeKey];
    
    if (initialLaunchTime == nil) {
        initialLaunchTime = MPCurrentEpochInMilliseconds;
        userDefaults[kMPAppInitialLaunchTimeKey] = initialLaunchTime;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [userDefaults synchronize];
        });
    }
}

+ (void)updateLastUseDate:(NSDate *)date {
    MPApplication *application = [[MPApplication alloc] init];
    application.lastUseDate = MPMilliseconds([date timeIntervalSince1970]);
}

+ (void)updateLaunchCountsAndDates {
    MPApplication *application = [[MPApplication alloc] init];
    
    application.launchCount = @([application.launchCount integerValue] + 1);
    
    if (![application.version isEqualToString:application.storedVersion] || ![application.build isEqualToString:application.storedBuild]) {
        application.launchCountSinceUpgrade = @1;
        application.upgradeDate = MPCurrentEpochInMilliseconds;
    } else {
        application.launchCountSinceUpgrade = @([application.launchCountSinceUpgrade integerValue] + 1);
    }
}

+ (void)updateStoredVersionAndBuildNumbers {
    MPApplication *application = [[MPApplication alloc] init];
    application.storedVersion = application.version;
    application.storedBuild = application.build;
}

#pragma mark Public methods
- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    if (appInfo) {
        NSMutableDictionary<NSString *, id> *mutableAppInfo = [appInfo mutableCopy];
        
        NSDictionary *auxDictionary = self.searchAdsAttribution;
        if (auxDictionary) {
            mutableAppInfo[kMPAppSearchAdsAttributionKey] = auxDictionary;
        }
        return [mutableAppInfo copy];
    }
    
    NSMutableDictionary<NSString *, id> *applicationInfo;
    NSString *auxString;
    
    applicationInfo = [@{kMPAppPiratedKey:self.pirated,
                         kMPAppInitialLaunchTimeKey:self.initialLaunchTime,
                         kMPAppDeploymentTargetKey:[NSString stringWithFormat:@"%i", __IPHONE_OS_VERSION_MIN_REQUIRED],
                         kMPAppBuildSDKKey:[NSString stringWithFormat:@"%i", __IPHONE_OS_VERSION_MAX_ALLOWED],
                         kMPAppEnvironmentKey:@(self.environment),
                         kMPAppFirstSeenInstallationKey:self.firstSeenInstallation
                         }
                       mutableCopy];
    
    NSDictionary *auxDictionary = self.searchAdsAttribution;
    if (auxDictionary) {
        applicationInfo[kMPAppSearchAdsAttributionKey] = auxDictionary;
    }
    
    auxString = self.bundleIdentifier;
    if (auxString) {
        applicationInfo[kMPAppPackageNameKey] = auxString;
    }
    
    auxString = self.buildUUID;
    if (auxString) {
        applicationInfo[kMPAppBuildUUIDKey] = auxString;
    }
    
    auxString = self.architecture;
    if (auxString) {
        applicationInfo[kMPAppArchitectureKey] = auxString;
    }
    
    auxString = self.name;
    if (auxString) {
        applicationInfo[kMPApplicationNameKey] = auxString;
    }
    
    NSNumber *auxNumber = self.upgradeDate;
    if (auxNumber != nil) {
        applicationInfo[kMPAppUpgradeDateKey] = auxNumber;
    }
    
    auxNumber = self.launchCount;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLaunchCountKey] = auxNumber;
    }
    
    auxNumber = self.launchCountSinceUpgrade;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLaunchCountSinceUpgradeKey] = auxNumber;
    }
    
    auxNumber = self.lastUseDate;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLastUseDateKey] = auxNumber;
    }
    
    auxString = self.version;
    if (auxString) {
        applicationInfo[kMPApplicationVersionKey] = auxString;
    }
    
    auxString = self.build;
    if (auxString) {
        applicationInfo[kMPAppBuildNumberKey] = auxString;
    }
    
    if ([MParticle sharedInstance].stateMachine.allowASR && [MPApplication appStoreReceipt]) {
        applicationInfo[kMPAppStoreReceiptKey] = [MPApplication appStoreReceipt];
    }
    
#if TARGET_OS_IOS == 1
    NSNumber *notificationTypes = self.remoteNotificationTypes;
    if (notificationTypes != nil) {
        applicationInfo[kMPDeviceSupportedPushNotificationTypesKey] = notificationTypes;
    }
    
    NSNumber *badgeNumber = self.badgeNumber;
    if (badgeNumber != nil) {
        applicationInfo[kMPAppBadgeNumberKey] = badgeNumber;
    }
#endif
    
    appInfo = (NSDictionary *)applicationInfo;
    
    return appInfo;
}

@end
