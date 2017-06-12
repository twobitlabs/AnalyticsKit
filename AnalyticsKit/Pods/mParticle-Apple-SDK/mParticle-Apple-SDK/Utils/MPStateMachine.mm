//
//  MPStateMachine.m
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

#import "MPStateMachine.h"
#import "NSUserDefaults+mParticle.h"
#import "MPIConstants.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPDevice.h"
#include <sys/sysctl.h>
#import "MPNotificationController.h"
#import "MPDateFormatter.h"
#import "MPHasher.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MPBags.h"
#include "MessageTypeName.h"
#import "MPLocationManager.h"
#import "MPKitContainer.h"
#import "MPSearchAdsAttribution.h"
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

NSString *const kCookieDateKey = @"e";
NSString *const kMinUploadDateKey = @"MinUploadDate";

static MPEnvironment runningEnvironment = MPEnvironmentAutoDetect;
static BOOL runningInBackground = NO;

@interface MPStateMachine() {
    BOOL lastestSDKWarningShown;
    BOOL optOutSet;
    BOOL alwaysTryToCollectIDFASet;
}

@property (nonatomic, unsafe_unretained) MParticleNetworkStatus networkStatus;
@property (nonatomic, strong) NSString *storedSDKVersion;
@property (nonatomic, strong) MParticleReachability *reachability;

@end


@implementation MPStateMachine

@synthesize consoleLogging = _consoleLogging;
@synthesize consumerInfo = _consumerInfo;
@synthesize deviceTokenType = _deviceTokenType;
@synthesize firstSeenInstallation = _firstSeenInstallation;
@synthesize installationType = _installationType;
@synthesize locationTrackingMode = _locationTrackingMode;
@synthesize logLevel = _logLevel;
@synthesize minUploadDate = _minUploadDate;
@synthesize optOut = _optOut;
@synthesize alwaysTryToCollectIDFA = _alwaysTryToCollectIDFA;
@synthesize pushNotificationMode = _pushNotificationMode;
@synthesize storedSDKVersion = _storedSDKVersion;
@synthesize triggerEventTypes = _triggerEventTypes;
@synthesize triggerMessageTypes = _triggerMessageTypes;

#if TARGET_OS_IOS == 1
@synthesize location = _location;
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        optOutSet = NO;
        _exceptionHandlingMode = kMPRemoteConfigExceptionHandlingModeAppDefined;
        _networkPerformanceMeasuringMode = kMPRemoteConfigAppDefined;
        _uploadStatus = MPUploadStatusBatch;
        _startTime = [NSDate dateWithTimeIntervalSinceNow:-1];
        _backgrounded = NO;
        _consoleLogging = MPConsoleLoggingAutoDetect;
        lastestSDKWarningShown = NO;
        _dataRamped = NO;
        _installationType = MPInstallationTypeAutodetect;
        _launchDate = [NSDate date];
        _launchOptions = nil;
        _logLevel = [MPStateMachine environment] == MPEnvironmentProduction ? MPILogLevelNone : MPILogLevelWarning;
        _shouldUploadSessionHistory = YES;
        _searchAttribution = [[MPSearchAdsAttribution alloc] init];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        __weak MPStateMachine *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MPStateMachine *strongSelf = weakSelf;
            
            strongSelf.storedSDKVersion = kMParticleSDKVersion;
            
            [strongSelf.reachability startNotifier];
            strongSelf.networkStatus = [strongSelf->_reachability currentReachabilityStatus];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationDidEnterBackground:)
                                       name:UIApplicationDidEnterBackgroundNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationWillEnterForeground:)
                                       name:UIApplicationWillEnterForegroundNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationWillTerminate:)
                                       name:UIApplicationWillTerminateNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleMemoryWarningNotification:)
                                       name:UIApplicationDidReceiveMemoryWarningNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleReachabilityChanged:)
                                       name:MParticleReachabilityChangedNotification
                                     object:nil];
            
            [MPApplication markInitialLaunchTime];
            [MPApplication updateLaunchCountsAndDates];
        });
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [notificationCenter removeObserver:self name:MParticleReachabilityChangedNotification object:nil];
}

#pragma mark Private accessors
- (MParticleReachability *)reachability {
    if (_reachability) {
        return _reachability;
    }
    
    [self willChangeValueForKey:@"reachability"];
    _reachability = [MParticleReachability reachabilityForInternetConnection];
    [self didChangeValueForKey:@"reachability"];
    
    return _reachability;
}

- (void)setNetworkStatus:(MParticleNetworkStatus)networkStatus {
    _networkStatus = networkStatus;

    NSString *networkStatusDescription;
    switch (networkStatus) {
        case MParticleNetworkStatusReachableViaWiFi:
            networkStatusDescription = @"Reachable via Wi-Fi";
            break;
            
        case MParticleNetworkStatusReachableViaWAN:
            networkStatusDescription = @"Reachable via WAN";
            break;
            
        case MParticleNetworkStatusNotReachable:
            networkStatusDescription = @"Not reachable";
            break;
    }
    
    MPILogVerbose(@"Network Status: %@", networkStatusDescription);
}

- (NSString *)storedSDKVersion {
    if (_storedSDKVersion) {
        return _storedSDKVersion;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _storedSDKVersion = userDefaults[@"storedSDKVersion"];
    
    return _storedSDKVersion;
}

- (void)setStoredSDKVersion:(NSString *)storedSDKVersion {
    if (self.storedSDKVersion && storedSDKVersion && [_storedSDKVersion isEqualToString:storedSDKVersion]) {
        return;
    }
    
    NSString *storedSDKMajorVersion = [_storedSDKVersion substringWithRange:NSMakeRange(0, 1)];
    NSString *newSDKMajorVersion = [storedSDKVersion substringWithRange:NSMakeRange(0, 1)];
    if (newSDKMajorVersion && ![storedSDKMajorVersion isEqualToString:newSDKMajorVersion]) {
        [[MPKitContainer sharedInstance] removeAllKitConfigurations];
    }

    _storedSDKVersion = storedSDKVersion;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (MPIsNull(_storedSDKVersion)) {
        [userDefaults removeMPObjectForKey:@"storedSDKVersion"];
    } else {
        userDefaults[@"storedSDKVersion"] = _storedSDKVersion;
    }
    
    [userDefaults removeMPObjectForKey:kMPHTTPETagHeaderKey];
}

#pragma mark Private methods
+ (MPEnvironment)getEnvironment {
    MPEnvironment environment;
    
#if !TARGET_OS_SIMULATOR
    int numberOfBytes = 4;
    int *name = new int[numberOfBytes];
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    struct kinfo_proc info;
    size_t infoSize = sizeof(info);
    info.kp_proc.p_flag = 0;
    
    sysctl(name, numberOfBytes, &info, &infoSize, NULL, 0);
    delete[] name;
    BOOL isDebuggerRunning = (info.kp_proc.p_flag & P_TRACED) != 0;
    
    if (isDebuggerRunning) {
        environment = MPEnvironmentDevelopment;
    } else {
        NSString *provisioningProfileString = [MPStateMachine provisioningProfileString];
        environment = provisioningProfileString ? MPEnvironmentDevelopment : MPEnvironmentProduction;
    }
#else
    environment = MPEnvironmentDevelopment;
#endif
    
    return environment;
}

- (void)resetRampPercentage {
    if (_dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        _dataRamped = NO;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)resetTriggers {
    if (_triggerEventTypes) {
        [self willChangeValueForKey:@"triggerEventTypes"];
        _triggerEventTypes = nil;
        [self didChangeValueForKey:@"triggerEventTypes"];
    }
    
    if (_triggerMessageTypes) {
        [self willChangeValueForKey:@"triggerMessageTypes"];
        _triggerMessageTypes = nil;
        [self didChangeValueForKey:@"triggerMessageTypes"];
    }
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    [MPApplication updateLastUseDate:_launchDate];
    [MPApplication updateStoredVersionAndBuildNumbers];
    _backgrounded = YES;

    __weak MPStateMachine *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPStateMachine *strongSelf = weakSelf;
        strongSelf.launchInfo = nil;
    });
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    __weak MPStateMachine *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPStateMachine *strongSelf = weakSelf;
        strongSelf->_backgrounded = NO;
    });
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [MPApplication updateLastUseDate:_launchDate];
    [MPApplication updateStoredVersionAndBuildNumbers];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
}

- (void)handleReachabilityChanged:(NSNotification *)notification {
    MParticleReachability *currentReachability = [notification object];
    
    if ([currentReachability isKindOfClass:[MParticleReachability class]]) {
        [self willChangeValueForKey:@"networkStatus"];
        self.networkStatus = [currentReachability currentReachabilityStatus];
        [self didChangeValueForKey:@"networkStatus"];
    }
}

#pragma mark Class methods
+ (instancetype)sharedInstance {
    static MPStateMachine *sharedInstance = nil;
    static dispatch_once_t stateMachinePredicate;
    
    dispatch_once(&stateMachinePredicate, ^{
        sharedInstance = [[MPStateMachine alloc] init];
    });
    
    return sharedInstance;
}

+ (MPEnvironment)environment {
    if (runningEnvironment != MPEnvironmentAutoDetect) {
        return runningEnvironment;
    }
    
    runningEnvironment = [MPStateMachine getEnvironment];
    
    return runningEnvironment;
}

+ (void)setEnvironment:(MPEnvironment)environment {
    if ([MPStateMachine getEnvironment] == MPEnvironmentProduction && environment == MPEnvironmentDevelopment) {
        MPILogError(@"Please be aware you are forcing the SDK running environment into development; be sure to undo this before submitting to the App Store.");
    }

    runningEnvironment = environment;
}

+ (NSString *)provisioningProfileString {
    NSString *provisioningProfilePath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    
    if (!provisioningProfilePath) {
        return nil;
    }
    
    NSData *provisioningProfileData = [NSData dataWithContentsOfFile:provisioningProfilePath];
    NSUInteger dataLength = provisioningProfileData.length;
    const char *provisioningProfileBytes = (const char *)[provisioningProfileData bytes];
    NSMutableString *provisioningProfileString = [[NSMutableString alloc] initWithCapacity:provisioningProfileData.length];
    
    for (NSUInteger i = 0; i < dataLength; ++i) {
        [provisioningProfileString appendFormat:@"%c", provisioningProfileBytes[i]];
    }
    
    NSString *singleLineProvisioningProfileString = [[provisioningProfileString componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
    
    return singleLineProvisioningProfileString;
}

+ (BOOL)runningInBackground {
    return runningInBackground;
}

+ (void)setRunningInBackground:(BOOL)background {
    runningInBackground = background;
}

#pragma mark Public accessors
- (MPBags *)bags {
    if (_bags) {
        return _bags;
    }
    
    _bags = [[MPBags alloc] init];
    return _bags;
}

- (MPConsoleLogging)consoleLogging {
    if (_consoleLogging != MPConsoleLoggingAutoDetect) {
        return _consoleLogging;
    }
    
    _consoleLogging = [MPStateMachine environment] == MPEnvironmentProduction ? MPConsoleLoggingSuppress : MPConsoleLoggingDisplay;
    if (_consoleLogging == MPConsoleLoggingSuppress) {
        _logLevel = MPILogLevelNone;
    }
    
    return _consoleLogging;
}

- (void)setConsoleLogging:(MPConsoleLogging)consoleLogging {
    if (consoleLogging == MPConsoleLoggingSuppress) {
        _logLevel = MPILogLevelNone;
    } else if ([MPStateMachine environment] == MPEnvironmentDevelopment && _consoleLogging != MPConsoleLoggingSuppress) {
        _logLevel = MPILogLevelWarning;
    }
    
    _consoleLogging = consoleLogging;
}

- (MPConsumerInfo *)consumerInfo {
    if (_consumerInfo) {
        return _consumerInfo;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    _consumerInfo = [persistence fetchConsumerInfo];
    
    if (!_consumerInfo) {
        _consumerInfo = [[MPConsumerInfo alloc] init];
        [persistence saveConsumerInfo:_consumerInfo];
    }

    return _consumerInfo;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    if ([MPStateMachine environment] == MPEnvironmentProduction) {
        _logLevel = MPILogLevelNone;
        _consoleLogging = MPConsoleLoggingSuppress;
    } else {
        _logLevel = logLevel;
        
        if (logLevel == MPILogLevelNone) {
            _consoleLogging = MPConsoleLoggingSuppress;
        }
    }
}

- (NSString *)deviceTokenType {
    if (_deviceTokenType) {
        return _deviceTokenType;
    }
    
    [self willChangeValueForKey:@"deviceTokenType"];

    _deviceTokenType = @"";
    NSString *provisioningProfileString = [MPStateMachine provisioningProfileString];
    
    if (provisioningProfileString) {
        NSRange range = [provisioningProfileString rangeOfString:@"<key>aps-environment</key><string>production</string>"];
        if (range.location != NSNotFound) {
            _deviceTokenType = kMPDeviceTokenTypeProduction;
        } else {
            range = [provisioningProfileString rangeOfString:@"<key>aps-environment</key><string>development</string>"];
            
            if (range.location != NSNotFound) {
                _deviceTokenType = kMPDeviceTokenTypeDevelopment;
            }
        }
    }

    [self didChangeValueForKey:@"deviceTokenType"];
    
    return _deviceTokenType;
}

- (NSNumber *)firstSeenInstallation {
    if (_firstSeenInstallation) {
        return _firstSeenInstallation;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *firstSeenInstallation = userDefaults[kMPAppFirstSeenInstallationKey];
    if (firstSeenInstallation) {
        _firstSeenInstallation = firstSeenInstallation;
    } else {
        [self willChangeValueForKey:@"firstSeenInstallation"];
        _firstSeenInstallation = @YES;
        [self didChangeValueForKey:@"firstSeenInstallation"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            userDefaults[kMPAppFirstSeenInstallationKey] = _firstSeenInstallation;
            [userDefaults synchronize];
        });
    }
    
    return _firstSeenInstallation;
}

- (void)setFirstSeenInstallation:(NSNumber *)firstSeenInstallation {
    if (_firstSeenInstallation) {
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *fsi = userDefaults[kMPAppFirstSeenInstallationKey];
    if (!fsi) {
        [self willChangeValueForKey:@"firstSeenInstallation"];
        _firstSeenInstallation = firstSeenInstallation;
        [self didChangeValueForKey:@"firstSeenInstallation"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            userDefaults[kMPAppFirstSeenInstallationKey] = _firstSeenInstallation;
            [userDefaults synchronize];
        });
    }
}

- (MPInstallationType)installationType {
    if (_installationType != MPInstallationTypeAutodetect) {
        return _installationType;
    }
    
    [self willChangeValueForKey:@"installationType"];

    MPApplication *application = [[MPApplication alloc] init];
    if (application.storedVersion || application.storedBuild) {
        if (![application.version isEqualToString:application.storedVersion] || ![application.build isEqualToString:application.storedBuild]) {
            _installationType = MPInstallationTypeKnownUpgrade;
        } else {
            _installationType = MPInstallationTypeKnownSameVersion;
        }
    } else {
        _installationType = MPInstallationTypeKnownInstall;
    }
    
    [self didChangeValueForKey:@"installationType"];
    
    return _installationType;
}

- (void)setInstallationType:(MPInstallationType)installationType {
    [self willChangeValueForKey:@"installationType"];
    _installationType = installationType;
    [self didChangeValueForKey:@"installationType"];
    
    self.firstSeenInstallation = installationType != MPInstallationTypeKnownUpgrade ? @YES : @NO;
}

- (void)setLatestSDKVersion:(NSString *)latestSDKVersion {
    if (MPIsNull(latestSDKVersion)) {
        return;
    }
    
    if (!_latestSDKVersion || ![_latestSDKVersion isEqualToString:latestSDKVersion]) {
        [self willChangeValueForKey:@"latestSDKVersion"];
        _latestSDKVersion = latestSDKVersion;
        [self didChangeValueForKey:@"latestSDKVersion"];
    }
    
    if (!lastestSDKWarningShown && ([MPStateMachine environment] == MPEnvironmentDevelopment) && latestSDKVersion && [latestSDKVersion compare:kMParticleSDKVersion] == NSOrderedDescending) {
        NSLog(@"****");
        NSLog(@"*");
        NSLog(@"* Version %@ of the mParticle SDK is available.", latestSDKVersion);
        NSLog(@"* You are running version %@.", kMParticleSDKVersion);
        NSLog(@"*");
        NSLog(@"****");
        
        lastestSDKWarningShown = YES;
    }
}

#if TARGET_OS_IOS == 1
- (CLLocation *)location {
    if ([MPLocationManager trackingLocation]) {
        return self.locationManager.location;
    } else {
        return _location;
    }
}

- (void)setLocation:(CLLocation *)location {
    if ([MPLocationManager trackingLocation]) {
        if (self.locationManager) {
            self.locationManager.location = location;
        }
        
        _location = nil;
    } else {
        _location = location;
    }
}
#endif

- (NSString *)locationTrackingMode {
    if (_locationTrackingMode) {
        return _locationTrackingMode;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *locationTrackingMode = userDefaults[kMPRemoteConfigLocationModeKey];
    
    [self willChangeValueForKey:@"locationTrackingMode"];
    
    if (locationTrackingMode) {
        _locationTrackingMode = locationTrackingMode;
    } else {
        _locationTrackingMode = kMPRemoteConfigAppDefined;
    }
    
    [self didChangeValueForKey:@"locationTrackingMode"];
    
    return _locationTrackingMode;
}

- (void)setLocationTrackingMode:(NSString *)locationTrackingMode {
    if ([_locationTrackingMode isEqualToString:locationTrackingMode]) {
        return;
    }
    
    [self willChangeValueForKey:@"locationTrackingMode"];
    _locationTrackingMode = locationTrackingMode;
    [self didChangeValueForKey:@"locationTrackingMode"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    userDefaults[kMPRemoteConfigLocationModeKey] = _locationTrackingMode;
    dispatch_async(dispatch_get_main_queue(), ^{
        [userDefaults synchronize];
    });
}

- (NSDate *)minUploadDate {
    if (_minUploadDate) {
        return _minUploadDate;
    }
    
    [self willChangeValueForKey:@"minUploadDate"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *minUploadDate = userDefaults[kMinUploadDateKey];
    if (minUploadDate) {
        if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
            _minUploadDate = minUploadDate;
        } else {
            _minUploadDate = [NSDate distantPast];
        }
    } else {
        _minUploadDate = [NSDate distantPast];
    }

    [self didChangeValueForKey:@"minUploadDate"];
    
    return _minUploadDate;
}

- (void)setMinUploadDate:(NSDate *)minUploadDate {
    _minUploadDate = minUploadDate;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        userDefaults[kMinUploadDateKey] = minUploadDate;
    } else if (userDefaults[kMinUploadDateKey]) {
        [userDefaults removeMPObjectForKey:kMinUploadDateKey];
    }
}

- (BOOL)optOut {
    if (optOutSet) {
        return _optOut;
    }
    
    [self willChangeValueForKey:@"optOut"];
    
    optOutSet = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *optOutNumber = userDefaults[kMPOptOutStatus];
    if (optOutNumber) {
        _optOut = [optOutNumber boolValue];
    } else {
        _optOut = NO;
        userDefaults[kMPOptOutStatus] = @(_optOut);
        dispatch_async(dispatch_get_main_queue(), ^{
            [userDefaults synchronize];
        });
    }
    
    [self didChangeValueForKey:@"optOut"];
    
    return _optOut;
}

- (void)setOptOut:(BOOL)optOut {
    _optOut = optOut;
    optOutSet = YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    userDefaults[kMPOptOutStatus] = @(_optOut);
    dispatch_async(dispatch_get_main_queue(), ^{
        [userDefaults synchronize];
    });
}

- (BOOL)alwaysTryToCollectIDFA {
    if (alwaysTryToCollectIDFASet) {
        return _alwaysTryToCollectIDFA;
    }
    
    [self willChangeValueForKey:@"alwaysTryToCollectIDFA"];
    
    alwaysTryToCollectIDFASet = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *alwaysTryToCollectIDFANumber = userDefaults[kMPAlwaysTryToCollectIDFA];
    
    if (alwaysTryToCollectIDFANumber) {
        _alwaysTryToCollectIDFA = [alwaysTryToCollectIDFANumber boolValue];
    }
    else {
        _alwaysTryToCollectIDFA = NO;
        userDefaults[kMPAlwaysTryToCollectIDFA] = @(_alwaysTryToCollectIDFA);
        dispatch_async(dispatch_get_main_queue(), ^{
            [userDefaults synchronize];
        });
    }
    
    [self didChangeValueForKey:@"alwaysTryToCollectIDFA"];
    
    return _alwaysTryToCollectIDFA;
}

- (void)setAlwaysTryToCollectIDFA:(BOOL)alwaysTryToCollectIDFA {
    _alwaysTryToCollectIDFA = alwaysTryToCollectIDFA;
    alwaysTryToCollectIDFASet = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    userDefaults[kMPAlwaysTryToCollectIDFA] = @(alwaysTryToCollectIDFA);
    dispatch_async(dispatch_get_main_queue(), ^{
        [userDefaults synchronize];
    });
}

- (NSString *)pushNotificationMode {
    if (_pushNotificationMode) {
        return _pushNotificationMode;
    }
    
    [self willChangeValueForKey:@"pushNotificationMode"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *pushNotificationMode = userDefaults[kMPRemoteConfigPushNotificationModeKey];
    if (pushNotificationMode) {
        _pushNotificationMode = pushNotificationMode;
    } else {
        _pushNotificationMode = kMPRemoteConfigAppDefined;
    }
    
    [self didChangeValueForKey:@"pushNotificationMode"];
    
    return _pushNotificationMode;
}

- (void)setPushNotificationMode:(NSString *)pushNotificationMode {
    if ([_pushNotificationMode isEqualToString:pushNotificationMode]) {
        return;
    }
    
    [self willChangeValueForKey:@"pushNotificationMode"];
    _pushNotificationMode = pushNotificationMode;
    [self didChangeValueForKey:@"pushNotificationMode"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    userDefaults[kMPRemoteConfigPushNotificationModeKey] = _pushNotificationMode;
    dispatch_async(dispatch_get_main_queue(), ^{
        [userDefaults synchronize];
    });
}

- (NSDate *)startTime {
    if (_startTime) {
        return _startTime;
    }
    
    [self willChangeValueForKey:@"startTime"];
    _startTime = [NSDate dateWithTimeIntervalSinceNow:-1];
    [self didChangeValueForKey:@"startTime"];
    
    return _startTime;
}

- (NSArray *)triggerEventTypes {
    return _triggerEventTypes;
}

- (NSArray *)triggerMessageTypes {
    return _triggerMessageTypes;
}

#pragma mark Public methods
- (void)configureCustomModules:(NSArray<NSDictionary *> *)customModuleSettings {
    if (MPIsNull(customModuleSettings)) {
        return;
    }
    
    NSMutableArray<MPCustomModule *> *localCustomModules = [[NSMutableArray alloc] initWithCapacity:customModuleSettings.count];
    MPCustomModule *customModule;
    for (NSDictionary *customModuleDictionary in customModuleSettings) {
        customModule = [[MPCustomModule alloc] initWithDictionary:customModuleDictionary];
        if (customModule) {
            [localCustomModules addObject:customModule];
        }
    }
    
    if (localCustomModules.count == 0) {
        localCustomModules = nil;
    }
    
    self.customModules = [localCustomModules copy];
}

- (void)configureRampPercentage:(NSNumber *)rampPercentage {
    if (MPIsNull(rampPercentage)) {
        [self resetRampPercentage];
        
        return;
    }
    
    MPDevice *device = [[MPDevice alloc] init];
    NSData *rampData = [device.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    uint64_t rampHash = mParticle::Hasher::hashFNV1a((const char *)[rampData bytes], (int)[rampData length]);
    NSUInteger modRampHash = rampHash % 100;
    
    BOOL dataRamped = modRampHash > [rampPercentage integerValue];
    if (_dataRamped != dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        _dataRamped = dataRamped;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)configureTriggers:(NSDictionary *)triggerDictionary {
    // When configured, triggerMessageTypes will at least have one item: MPMessageTypeCommerceEvent,
    // so if there the received configuration is nil and there are more than 1 trigger configured,
    // then reset the configuration and let commerce event be configured as trigger. Otherwise returns
    if (MPIsNull(triggerDictionary)) {
        if (_triggerMessageTypes.count > 1) {
            [self resetTriggers];
        } else if (_triggerMessageTypes.count == 1) {
            return;
        }
        
        triggerDictionary = nil;
    }
    
    NSArray *eventTypes = triggerDictionary[kMPRemoteConfigTriggerEventsKey];
    if (MPIsNull(eventTypes)) {
        [self willChangeValueForKey:@"triggerEventTypes"];
        _triggerEventTypes = nil;
        [self didChangeValueForKey:@"triggerEventTypes"];
    } else {
        if (![_triggerEventTypes isEqualToArray:eventTypes]) {
            [self willChangeValueForKey:@"triggerEventTypes"];
            _triggerEventTypes = eventTypes;
            [self didChangeValueForKey:@"triggerEventTypes"];
        }
    }
    
    NSString *messageTypeCommerceEventKey = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::CommerceEvent).c_str() encoding:NSUTF8StringEncoding];
    NSMutableArray *messageTypes = [@[messageTypeCommerceEventKey] mutableCopy];
    NSArray *configMessageTypes = triggerDictionary[kMPRemoteConfigTriggerMessageTypesKey];
    
    if (!MPIsNull(configMessageTypes)) {
        [messageTypes addObjectsFromArray:configMessageTypes];
    }
    
    [self willChangeValueForKey:@"triggerMessageTypes"];
    _triggerMessageTypes = (NSArray *)messageTypes;
    [self didChangeValueForKey:@"triggerMessageTypes"];
}

- (void)configureRestrictIDFA:(NSNumber *)restrictIDFA {
    if (MPIsNull(restrictIDFA)) {
        restrictIDFA = @YES;
    }
    self.alwaysTryToCollectIDFA = [restrictIDFA isEqual:@NO];
}

@end
