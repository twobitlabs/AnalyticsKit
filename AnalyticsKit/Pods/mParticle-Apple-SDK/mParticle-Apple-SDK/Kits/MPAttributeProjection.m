//
//  MPAttributeProjection.m
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

#import "MPAttributeProjection.h"

@implementation MPAttributeProjection

- (id)init {
    self = [self initWithConfiguration:nil projectionType:MPProjectionTypeAttribute attributeIndex:0];
    return self;
}

- (instancetype)initWithConfiguration:(NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex {
    self = [super initWithConfiguration:configuration projectionType:projectionType attributeIndex:attributeIndex];
    if (!self) {
        return nil;
    }
    
    NSDictionary *actionDictionary = configuration[@"action"];
    NSArray *attributeMaps = actionDictionary[@"attribute_maps"];
    NSDictionary *attributeMap = attributeMaps[attributeIndex];
    
    self.dataType = !MPIsNull(attributeMap[@"data_type"]) ? (MPDataType)[attributeMap[@"data_type"] integerValue] : MPDataTypeString;
    _required = !MPIsNull(attributeMap[@"is_required"]) ? [attributeMap[@"is_required"] boolValue] : NO;
    
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = [object isKindOfClass:[self class]];
    
    if (isEqual) {
        isEqual = [super isEqual:object];
        
        if (isEqual) {
            isEqual = _dataType == ((MPAttributeProjection *)object).dataType &&
                      _required == ((MPAttributeProjection *)object).required;
        }
    }
    
    return isEqual;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeInteger:_dataType forKey:@"dataType"];
    [coder encodeBool:_required forKey:@"required"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }

    self.dataType = (MPDataType)[coder decodeIntegerForKey:@"dataType"];
    _required = [coder decodeBoolForKey:@"required"];
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPAttributeProjection *copyObject = [[[self class] alloc] initWithConfiguration:_configuration projectionType:MPProjectionTypeAttribute attributeIndex:_attributeIndex];
    
    if (copyObject) {
        copyObject.name = [_name copy];
        copyObject.projectedName = [_projectedName copy];
        copyObject.matchType = _matchType;
        copyObject->_projectionType = _projectionType;
        copyObject->_propertyKind = _propertyKind;
        copyObject.dataType = _dataType;
        copyObject.required = _required;
    }
    
    return copyObject;
}

#pragma mark Public accessors
- (void)setDataType:(MPDataType)dataType {
    _dataType = dataType;
    
    if (_dataType < MPDataTypeString || _dataType > MPDataTypeLong) {
        _dataType = MPDataTypeString;
    }
}

@end
