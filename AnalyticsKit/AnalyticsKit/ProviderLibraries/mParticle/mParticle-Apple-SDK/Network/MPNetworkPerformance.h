//
//  MPNetworkPerformance.h
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

typedef NS_ENUM(NSInteger, MPNetworkMeasurementMode) {
    MPNetworkMeasurementModeExclude = 0,
    MPNetworkMeasurementModePreserveQuery,
    MPNetworkMeasurementModeAbridged
};

@interface MPNetworkPerformance : NSObject <NSCopying>

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong, readonly) NSString *POSTBody;
@property (nonatomic, unsafe_unretained) NSTimeInterval startTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval endTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval elapsedTime;
@property (nonatomic, unsafe_unretained) NSUInteger bytesIn;
@property (nonatomic, unsafe_unretained) NSUInteger bytesOut;
@property (nonatomic, unsafe_unretained) NSInteger responseCode;
@property (nonatomic, unsafe_unretained, readonly) MPNetworkMeasurementMode networkMeasurementMode;

- (instancetype)initWithURLRequest:(NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode;
- (void)setStartDate:(NSDate *)date;
- (void)setEndDate:(NSDate *)date;
- (NSDictionary *)dictionaryRepresentation;

@end
