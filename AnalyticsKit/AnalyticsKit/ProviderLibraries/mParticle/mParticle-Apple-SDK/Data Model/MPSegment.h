//
//  MPSegment.h
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

#import "MPDataModelAbstract.h"

@class MPSegmentMembership;

extern NSString *const kMPSegmentListKey;

@interface MPSegment : MPDataModelAbstract <NSCopying>

@property (nonatomic, strong) NSNumber *segmentId;
@property (nonatomic, strong) NSArray *endpointIds;
@property (nonatomic, strong, readonly) NSDate *expiration;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<MPSegmentMembership *> *memberships;
@property (nonatomic, unsafe_unretained, readonly) BOOL expired;

- (instancetype)initWithSegmentId:(NSNumber *)segmentId UUID:(NSString *)uuid name:(NSString *)name memberships:(NSArray<MPSegmentMembership *> *)memberships endpointIds:(NSArray *)endpointIds;
- (instancetype)initWithDictionary:(NSDictionary *)segmentDictionary;

@end
