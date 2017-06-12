//
//  MPApplication.h
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
- (nonnull NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end
