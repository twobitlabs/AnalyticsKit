#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * _Nonnull const kMPStateInformationKey;
extern NSString * _Nonnull const kMPStateDeviceOrientationKey;
extern NSString * _Nonnull const kMPStateStatusBarOrientationKey;
extern NSString * _Nonnull const kMPStateBatteryLevelKey;
extern NSString * _Nonnull const kMPStateGPSKey;

@interface MPCurrentState : NSObject

@property (nonatomic, strong, readonly, nonnull) NSNumber *applicationMemory;
@property (nonatomic, strong, readonly, nonnull) NSDictionary<NSString *, NSString *> *cpuUsageInfo;
@property (nonatomic, strong, readonly, nonnull) NSString *dataConnectionStatus;
@property (nonatomic, strong, readonly, nonnull) NSDictionary<NSString *, id> *diskSpaceInfo;
@property (nonatomic, strong, readonly, nonnull) NSDictionary<NSString *, NSNumber *> *systemMemoryInfo;
@property (nonatomic, strong, readonly, nonnull) NSNumber *timeSinceStart;

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, readonly, nonnull) NSNumber *batteryLevel;
@property (nonatomic, strong, readonly, nonnull) NSNumber *deviceOrientation;
@property (nonatomic, strong, readonly, nonnull) NSNumber *gpsState;
@property (nonatomic, strong, readonly, nonnull) NSNumber *statusBarOrientation;
#endif

- (nonnull NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end
