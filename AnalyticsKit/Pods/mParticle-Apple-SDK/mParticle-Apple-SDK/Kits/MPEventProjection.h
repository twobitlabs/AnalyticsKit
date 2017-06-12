//
//  MPEventProjection.h
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

#import "MPBaseProjection.h"
#import "MPEnums.h"

@class MPAttributeProjection;

typedef NS_ENUM(NSUInteger, MPProjectionBehaviorSelector) {
    MPProjectionBehaviorSelectorForEach = 0,
    MPProjectionBehaviorSelectorLast
};

@interface MPProjectionMatch : NSObject <NSCopying, NSCoding>
@property (nonatomic, strong, nullable) NSString *attributeKey;
@property (nonatomic, strong, nullable) NSArray<NSString *> *attributeValues;
@end

@interface MPEventProjection : MPBaseProjection <NSCopying, NSCoding>

@property (nonatomic, strong, nullable) NSArray<MPProjectionMatch *> *projectionMatches;
@property (nonatomic, strong, nullable) NSArray<MPAttributeProjection *> *attributeProjections;
@property (nonatomic, unsafe_unretained) MPProjectionBehaviorSelector behaviorSelector;
@property (nonatomic, unsafe_unretained) MPEventType eventType;
@property (nonatomic, unsafe_unretained) MPMessageType messageType;
@property (nonatomic, unsafe_unretained) MPMessageType outboundMessageType;
@property (nonatomic, unsafe_unretained) NSUInteger maxCustomParameters;
@property (nonatomic, unsafe_unretained) BOOL appendAsIs;
@property (nonatomic, unsafe_unretained) BOOL isDefault;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration;

@end
