//
//  MPSegmentMembership.h
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

typedef NS_ENUM(NSUInteger, MPSegmentMembershipAction) {
    MPSegmentMembershipActionAdd = 1,
    MPSegmentMembershipActionDrop
};

@interface MPSegmentMembership : NSObject <NSCopying>

@property (nonatomic, unsafe_unretained) int64_t segmentId;
@property (nonatomic, unsafe_unretained) int64_t segmentMembershipId;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) MPSegmentMembershipAction action;

- (instancetype)initWithSegmentId:(int64_t)segmentId membershipDictionary:(NSDictionary *)membershipDictionary;
- (instancetype)initWithSegmentId:(int64_t)segmentId segmentMembershipId:(int64_t)segmentMembershipId timestamp:(NSTimeInterval)timestamp membershipAction:(MPSegmentMembershipAction)action __attribute__((objc_designated_initializer));

@end
