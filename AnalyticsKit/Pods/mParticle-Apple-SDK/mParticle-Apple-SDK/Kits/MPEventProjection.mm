#import "MPEventProjection.h"
#import "MPAttributeProjection.h"
#include <vector>
#include "EventTypeName.h"

using namespace std;

@implementation MPProjectionMatch

- (BOOL)isEqual:(id)object {
    BOOL isEqual = !MPIsNull(object) && [object isKindOfClass:[MPProjectionMatch class]];
    
    if (isEqual) {
        MPProjectionMatch *projectionMatch = (MPProjectionMatch *)object;
        
        isEqual = ((!_attributeKey && !projectionMatch.attributeKey) || [_attributeKey isEqual:projectionMatch.attributeKey]) &&
        ((!_attributeValues && !projectionMatch.attributeValues) || [_attributeValues isEqual:projectionMatch.attributeValues]);
    }
    
    return isEqual;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.attributeKey) {
        [coder encodeObject:_attributeKey forKey:@"attributeKey"];
    }
    
    if (self.attributeValues) {
        [coder encodeObject:_attributeValues forKey:@"attributeValues"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _attributeKey = [coder decodeObjectOfClass:[NSString class] forKey:@"attributeKey"];
        _attributeValues = [coder decodeObjectOfClass:[NSArray<NSString *> class] forKey:@"attributeValues"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPProjectionMatch *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject.attributeKey = [_attributeKey copy];
        copyObject.attributeValues = [_attributeValues copy];
    }
    
    return copyObject;
}

@end

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
    
    NSArray *matches = !MPIsNull(configuration[@"matches"]) ? configuration[@"matches"] : nil;
    NSDictionary *matchDictionary = !MPIsNull(matches) && matches.count > 0 ? matches[0] : nil;
    __block NSString *auxString;
    
    auxString = matchDictionary[@"event"];
    _eventType = !MPIsNull(auxString) && auxString.length > 0 ? (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([auxString cStringUsingEncoding:NSUTF8StringEncoding])) : MPEventTypeOther;
    
    _messageType = !MPIsNull(matchDictionary[@"message_type"]) ? (MPMessageType)[matchDictionary[@"message_type"] integerValue] : MPMessageTypeEvent;
    
    NSMutableArray<MPProjectionMatch *> *projectionMatches = !MPIsNull(matches) && matches.count > 0 ? [NSMutableArray array] : nil;
    
    [matches enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull matchDictionary, NSUInteger idx, BOOL * _Nonnull stop) {
        MPProjectionMatch *projectionMatch = [[MPProjectionMatch alloc] init];
        if (self->_messageType == MPMessageTypeCommerceEvent) {
            auxString = matchDictionary[@"property_name"];
            projectionMatch.attributeKey = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
            
            NSArray<NSString *> *propertyValues = matchDictionary[@"property_value"];
            projectionMatch.attributeValues = !MPIsNull(propertyValues) && propertyValues.count > 0 ? propertyValues : nil;
        } else {
            auxString = matchDictionary[@"attribute_key"];
            projectionMatch.attributeKey = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
            
            NSArray<NSString *> *attributeValues = matchDictionary[@"attribute_values"];
            projectionMatch.attributeValues = !MPIsNull(attributeValues) && attributeValues.count > 0 ? attributeValues : nil;
        }
        if (projectionMatch.attributeKey && projectionMatch.attributeValues) {
            [projectionMatches addObject:projectionMatch];
        }
    }];
    if (!MPIsNull(projectionMatches) && projectionMatches.count > 0) {
        _projectionMatches = projectionMatches;
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
            
            isEqual = ((!_projectionMatches && !eventProjection.projectionMatches) || [_projectionMatches isEqual:eventProjection.projectionMatches]) &&
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

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    if (self.projectionMatches) {
        [coder encodeObject:_projectionMatches forKey:@"projectionMatches"];
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
        
        _projectionMatches = [coder decodeObjectOfClass:[NSArray<MPProjectionMatch *> class] forKey:@"projectionMatches"];
        _attributeProjections = [coder decodeObjectOfClass:[NSArray<MPAttributeProjection *> class] forKey:@"attributeProjections"];
        _behaviorSelector = (MPProjectionBehaviorSelector)[coder decodeIntegerForKey:@"behaviorSelector"];
        _eventType = (MPEventType)[coder decodeIntegerForKey:@"eventType"];
        _messageType = (MPMessageType)[coder decodeIntegerForKey:@"messageType"];
        _maxCustomParameters = [coder decodeIntegerForKey:@"maxCustomParameters"];
        _appendAsIs = [coder decodeBoolForKey:@"appendAsIs"];
        _isDefault = [coder decodeBoolForKey:@"isDefault"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
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
        copyObject.projectionMatches = [_projectionMatches copy];
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
