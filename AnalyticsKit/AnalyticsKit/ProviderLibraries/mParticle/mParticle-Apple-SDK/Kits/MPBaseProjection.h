//
//  MPBaseProjection.h
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

typedef NS_ENUM(NSInteger, MPProjectionMatchType) {
    MPProjectionMatchTypeNotSpecified = -1,
    MPProjectionMatchTypeString = 0,
    MPProjectionMatchTypeHash,
    MPProjectionMatchTypeField,
    MPProjectionMatchTypeStatic
};

typedef NS_ENUM(NSUInteger, MPProjectionType) {
    MPProjectionTypeAttribute = 0,
    MPProjectionTypeEvent
};

typedef NS_ENUM(NSUInteger, MPProjectionPropertyKind) {
    MPProjectionPropertyKindEventField = 0,
    MPProjectionPropertyKindEventAttribute,
    MPProjectionPropertyKindProductField,
    MPProjectionPropertyKindProductAttribute,
    MPProjectionPropertyKindPromotionField,
    MPProjectionPropertyKindPromotionAttribute
};

@interface MPBaseProjection : NSObject <NSCopying, NSCoding> {
    @protected
    NSDictionary *_configuration;
    NSString *_name;
    NSString *_projectedName;
    MPProjectionMatchType _matchType;
    MPProjectionType _projectionType;
    MPProjectionPropertyKind _propertyKind;
    NSUInteger _projectionId;
    NSUInteger _attributeIndex;
}

@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nullable) NSString *projectedName;
@property (nonatomic, unsafe_unretained) MPProjectionMatchType matchType;
@property (nonatomic, unsafe_unretained, readonly) MPProjectionType projectionType;
@property (nonatomic, unsafe_unretained, readonly) MPProjectionPropertyKind propertyKind;
@property (nonatomic, unsafe_unretained, readonly) NSUInteger projectionId;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex;

@end
