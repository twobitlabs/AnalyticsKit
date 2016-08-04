//
//  MPLocationManager.h
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
#import "MPEnums.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@interface MPLocationManager : NSObject

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, strong, nullable) CLLocationManager *locationManager;
@property (nonatomic, unsafe_unretained, readonly) MPLocationAuthorizationRequest authorizationRequest;
@property (nonatomic, unsafe_unretained, readonly) CLLocationAccuracy requestedAccuracy;
@property (nonatomic, unsafe_unretained, readonly) CLLocationDistance requestedDistanceFilter;
@property (nonatomic, unsafe_unretained) BOOL backgroundLocationTracking;

- (nullable instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;
- (void)endLocationTracking;
#endif

+ (BOOL)trackingLocation;

@end
