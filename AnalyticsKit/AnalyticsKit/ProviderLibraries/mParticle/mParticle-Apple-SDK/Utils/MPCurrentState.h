//
//  MPCurrentState.h
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
