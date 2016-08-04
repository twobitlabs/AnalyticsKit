//
//  MPEventProjection.mm
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

#import "MPEventProjection.h"
#import "MPAttributeProjection.h"
#include <vector>
#include "EventTypeName.h"

using namespace std;

@implementation MPEventProjection

- (id)init {
    self = [self initWithConfiguration:nil];
    return self;
}

- (instancetype)initWithConfiguration:(NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex {
    self = [self initWithConfiguration:configuration];
    return self;
}

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    if (!self) {
        return nil;
    }
    
    NSDictionary *matchDictionary = !MPIsNull(configuration[@"match"]) ? configuration[@"match"] : nil;
    NSString *auxString;
    
    auxString = matchDictionary[@"event"];
    _eventType = !MPIsNull(auxString) && auxString.length > 0 ? (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([auxString cStringUsingEncoding:NSUTF8StringEncoding])) : MPEventTypeOther;
    
    _messageType = !MPIsNull(matchDictionary[@"message_type"]) ? (MPMessageType)[matchDictionary[@"message_type"] integerValue] : MPMessageTypeEvent;
    
    if (_messageType == MPMessageTypeCommerceEvent) {
        auxString = matchDictionary[@"property_name"];
        _attributeKey = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
        
        auxString = matchDictionary[@"property_value"];
        _attributeValue = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
    } else {
        auxString = matchDictionary[@"attribute_key"];
        _attributeKey = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
        
        auxString = matchDictionary[@"attribute_value"];
        _attributeValue = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
    }
    
    NSDictionary *behaviorDictionary = !MPIsNull(configuration[@"behavior"]) ? configuration[@"behavior"] : nil;
    if (behaviorDictionary) {
        _appendAsIs = !MPIsNull(behaviorDictionary[@"append_unmapped_as_is"]) ? [behaviorDictionary[@"append_unmapped_as_is"] boolValue] : YES;
        _isDefault = !MPIsNull(behaviorDictionary[@"is_default"]) ? [behaviorDictionary[@"is_default"] boolValue] : NO;
        _maxCustomParameters = !MPIsNull(behaviorDictionary[@"max_custom_params"]) ? [behaviorDictionary[@"max_custom_params"] integerValue] : INT_MAX;
        
        auxString = behaviorDictionary[@"selector"];
        if (!MPIsNull(auxString)) {
            _behaviorSelector = [auxString isEqualToString:@"last"] ? MPProjectionBehaviorSelectorLast : MPProjectionBehaviorSelectorForEach;
        } else {
            _behaviorSelector = MPProjectionBehaviorSelectorForEach;
        }
    } else {
        _appendAsIs = YES;
        _isDefault = NO;
        _maxCustomParameters = INT_MAX;
        _behaviorSelector = MPProjectionBehaviorSelectorForEach;
    }

    NSDictionary *actionDictionary = configuration[@"action"];
    
    _outboundMessageType = !MPIsNull(actionDictionary[@"outbound_message_type"]) ? (MPMessageType)[actionDictionary[@"outbound_message_type"] integerValue] : MPMessageTypeEvent;
    
    NSArray *attributeMaps = !MPIsNull(actionDictionary[@"attribute_maps"]) ? actionDictionary[@"attribute_maps"] : nil;
    if (attributeMaps) {
        __block vector<MPAttributeProjection *> attributeProjectionsVector;
        
        [attributeMaps enumerateObjectsUsingBlock:^(NSDictionary *attributeMap, NSUInteger idx, BOOL *stop) {
            MPAttributeProjection *attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:idx];
            
            if (attributeProjection) {
                attributeProjectionsVector.push_back(attributeProjection);
            }
        }];
        
        _attributeProjections = !attributeProjectionsVector.empty() ? [NSArray arrayWithObjects:&attributeProjectionsVector[0] count:attributeProjectionsVector.size()] : nil;
    } else {
        _attributeProjections = nil;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = !MPIsNull(object) && [object isKindOfClass:[MPEventProjection class]];
    
    if (isEqual) {
        isEqual = [super isEqual:object];
        
        if (isEqual) {
            MPEventProjection *eventProjection = (MPEventProjection *)object;
            
            isEqual = ((!_attributeKey && !eventProjection.attributeKey) || [_attributeKey isEqualToString:eventProjection.attributeKey]) &&
                      ((!_attributeValue && !eventProjection.attributeValue) || [_attributeValue isEqualToString:eventProjection.attributeValue]) &&
                      _messageType == eventProjection.messageType &&
                      _maxCustomParameters == eventProjection.maxCustomParameters &&
                      _appendAsIs == eventProjection.appendAsIs &&
                      _isDefault == eventProjection.isDefault;
   
            if (isEqual) {
                isEqual = (!_attributeProjections && !eventProjection.attributeProjections) || [_attributeProjections isEqualToArray:eventProjection.attributeProjections];
            }
        }
    }
    
    return isEqual;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    if (self.attributeKey) {
        [coder encodeObject:_attributeKey forKey:@"attributeKey"];
    }
    
    if (self.attributeValue) {
        [coder encodeObject:_attributeValue forKey:@"attributeValue"];
    }
    
    if (self.attributeProjections) {
        [coder encodeObject:_attributeProjections forKey:@"attributeProjections"];
    }
    
    [coder encodeInteger:_behaviorSelector forKey:@"behaviorSelector"];
    [coder encodeInteger:_eventType forKey:@"eventType"];
    [coder encodeInteger:_messageType forKey:@"messageType"];
    [coder encodeInteger:_maxCustomParameters forKey:@"maxCustomParameters"];
    [coder encodeBool:_appendAsIs forKey:@"appendAsIs"];
    [coder encodeBool:_isDefault forKey:@"isDefault"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _attributeKey = [coder decodeObjectForKey:@"attributeKey"];
        _attributeValue = [coder decodeObjectForKey:@"attributeValue"];
        _attributeProjections = [coder decodeObjectForKey:@"attributeProjections"];
        _behaviorSelector = (MPProjectionBehaviorSelector)[coder decodeIntegerForKey:@"behaviorSelector"];
        _eventType = (MPEventType)[coder decodeIntegerForKey:@"eventType"];
        _messageType = (MPMessageType)[coder decodeIntegerForKey:@"messageType"];
        _maxCustomParameters = [coder decodeIntegerForKey:@"maxCustomParameters"];
        _appendAsIs = [coder decodeBoolForKey:@"appendAsIs"];
        _isDefault = [coder decodeBoolForKey:@"isDefault"];
    }
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPEventProjection *copyObject = [[[self class] alloc] initWithConfiguration:_configuration projectionType:MPProjectionTypeEvent attributeIndex:_attributeIndex];

    if (copyObject) {
        copyObject.name = [_name copy];
        copyObject.projectedName = [_projectedName copy];
        copyObject.matchType = _matchType;
        copyObject->_projectionType = _projectionType;
        copyObject->_propertyKind = _propertyKind;
        copyObject.attributeKey = [_attributeKey copy];
        copyObject.attributeValue = [_attributeValue copy];
        copyObject.attributeProjections = [_attributeProjections copy];
        copyObject.behaviorSelector = _behaviorSelector;
        copyObject.eventType = _eventType;
        copyObject.messageType = _messageType;
        copyObject.maxCustomParameters = _maxCustomParameters;
        copyObject.appendAsIs = _appendAsIs;
        copyObject.isDefault = _isDefault;
    }
    
    return copyObject;
}

@end
