//
//  MPDevice.h
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
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IOS == 1
    #import <CoreTelephony/CTTelephonyNetworkInfo.h>
    #import <CoreTelephony/CTCarrier.h>
#endif

extern NSString * _Nonnull const kMPDeviceInformationKey;


@interface MPDevice : NSObject <NSCopying> 

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, readonly, nullable) CTCarrier *carrier;
@property (nonatomic, strong, readonly, nonnull) NSString *radioAccessTechnology;
#endif

@property (nonatomic, strong, readonly, nullable) NSString *advertiserId;
@property (nonatomic, strong, readonly, nonnull) NSString *architecture;
@property (nonatomic, strong, readonly, nonnull) NSString *brand;
@property (nonatomic, strong, readonly, nullable) NSString *country;
@property (nonatomic, strong, readonly, nonnull) NSString *deviceIdentifier;
@property (nonatomic, strong, readonly, nullable) NSString *language;
@property (nonatomic, strong, readonly, nonnull) NSNumber *limitAdTracking;
@property (nonatomic, strong, readonly, nonnull) NSString *manufacturer __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSString *model;
@property (nonatomic, strong, readonly, nullable) NSString *name;
@property (nonatomic, strong, readonly, nonnull) NSString *platform __attribute__((const));
@property (nonatomic, strong, readonly, nullable) NSString *product;
@property (nonatomic, strong, readonly, nullable) NSString *operatingSystem;
@property (nonatomic, strong, readonly, nonnull) NSString *timezoneOffset;
@property (nonatomic, strong, readonly, nullable) NSString *timezoneDescription;
@property (nonatomic, strong, readonly, nullable) NSString *vendorId;
@property (nonatomic, unsafe_unretained, readonly) CGSize screenSize;
@property (nonatomic, unsafe_unretained, readonly, getter = isTablet) BOOL tablet;

+ (nonnull NSDictionary *)jailbrokenInfo;
- (nonnull NSDictionary *)dictionaryRepresentation;

@end
