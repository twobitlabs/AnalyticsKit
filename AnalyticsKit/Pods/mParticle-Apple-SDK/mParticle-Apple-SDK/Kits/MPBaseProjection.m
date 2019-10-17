#import "MPBaseProjection.h"

@implementation MPBaseProjection

@synthesize name = _name;
@synthesize projectedName = _projectedName;
@synthesize matchType = _matchType;
@synthesize projectionType = _projectionType;
@synthesize propertyKind = _propertyKind;
@synthesize projectionId = _projectionId;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex {
    self = [super init];
    NSDictionary *actionDictionary = !MPIsNull(configuration[@"action"]) ? configuration[@"action"] : nil;
    
    if (!self || !actionDictionary) {
        return nil;
    }
    
    _configuration = configuration;
    _attributeIndex = attributeIndex;
    _projectionType = projectionType;
    NSString *matchType = nil;
    NSString *auxString;
    
    MPProjectionPropertyKind (^propertyKindForString)(NSString *) = ^(NSString *property) {
        MPProjectionPropertyKind propertyKind;
        
        if (!MPIsNull(property) && property.length > 0) {
            if ([property isEqualToString:@"EventField"]) {
                propertyKind = MPProjectionPropertyKindEventField;
            } else if ([property isEqualToString:@"EventAttribute"]) {
                propertyKind = MPProjectionPropertyKindEventAttribute;
            } else if ([property isEqualToString:@"ProductField"]) {
                propertyKind = MPProjectionPropertyKindProductField;
            } else if ([property isEqualToString:@"ProductAttribute"]) {
                propertyKind = MPProjectionPropertyKindProductAttribute;
            } else if ([property isEqualToString:@"PromotionField"]) {
                propertyKind = MPProjectionPropertyKindPromotionField;
            } else if ([property isEqualToString:@"PromotionAttribute"]) {
                propertyKind = MPProjectionPropertyKindPromotionAttribute;
            } else {
                propertyKind = MPProjectionPropertyKindEventField;
            }
        } else {
            propertyKind = MPProjectionPropertyKindEventField;
        }
        
        return propertyKind;
    };
    
    switch (projectionType) {
        case MPProjectionTypeAttribute: {
                NSArray *attributesMap = !MPIsNull(actionDictionary[@"attribute_maps"]) ? (NSArray *)actionDictionary[@"attribute_maps"] : nil;
                NSDictionary *attributeMap = nil;
                
                if (attributesMap && attributeIndex < attributesMap.count) {
                    attributeMap = attributesMap[attributeIndex];
                    
                    if (!MPIsNull(attributeMap)) {
                        auxString = attributeMap[@"value"];
                        _name = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
                        
                        auxString = attributeMap[@"projected_attribute_name"];
                        _projectedName = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
                        
                        auxString = attributeMap[@"property"];
                        _propertyKind = propertyKindForString(auxString);
                        
                        matchType = !MPIsNull(attributeMap[@"match_type"]) ? attributeMap[@"match_type"] : @"String";
                    }
                } else {
                    return nil;
                }
            }
            break;
            
        case MPProjectionTypeEvent:
            _projectionId = [configuration[@"id"] integerValue];
            NSArray *matches = !MPIsNull(configuration[@"matches"]) ? configuration[@"matches"] : nil;
            NSDictionary *matchDictionary = !MPIsNull(matches) && matches.count > 0 ? matches[0] : nil;
            
            if (matchDictionary) {
                auxString = matchDictionary[@"event"];
                _name = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
                
                auxString = actionDictionary[@"projected_event_name"];
                _projectedName = !MPIsNull(auxString) && auxString.length > 0 ? auxString : nil;
                
                matchType = !MPIsNull(matchDictionary[@"event_match_type"]) ? matchDictionary[@"event_match_type"] : nil;
                
                auxString = matchDictionary[@"property"];
                _propertyKind = propertyKindForString(auxString);
            }
            break;
    }
    
    if (!matchType) {
        _matchType = MPProjectionMatchTypeNotSpecified;
    } else if ([matchType isEqualToString:@"String"]) {
        _matchType = MPProjectionMatchTypeString;
    } else if ([matchType isEqualToString:@"Hash"]) {
        _matchType = MPProjectionMatchTypeHash;
    } else if ([matchType isEqualToString:@"Field"]) {
        _matchType = MPProjectionMatchTypeField;
    } else if ([matchType isEqualToString:@"Static"]) {
        _matchType = MPProjectionMatchTypeStatic;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = [object isKindOfClass:[self class]];
    
    if (isEqual) {
        MPBaseProjection *baseProjection = (MPBaseProjection *)object;
        
        isEqual = [_name isEqualToString:baseProjection.name] &&
                  [_projectedName isEqualToString:baseProjection.projectedName] &&
                  _matchType == baseProjection.matchType &&
                  _projectionType == baseProjection.projectionType;
    }
    
    return isEqual;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] init];
    
    if (_name) {
        [description appendFormat:@" name: %@\n", _name];
    }
    
    if (_projectedName) {
        [description appendFormat:@" projected name: %@\n", _projectedName];
    }
    
    NSString *matchType;
    switch (_matchType) {
        case MPProjectionMatchTypeString:
            matchType = @"String";
            break;
            
        case MPProjectionMatchTypeHash:
            matchType = @"Hash";
            break;

        case MPProjectionMatchTypeField:
            matchType = @"Field";
            break;

        case MPProjectionMatchTypeStatic:
            matchType = @"Static";
            break;
            
        case MPProjectionMatchTypeNotSpecified:
            matchType = @"Not Specified";
            break;
    }
    [description appendFormat:@" matchType: %@\n", matchType];
    
    NSString *projectionType;
    switch (_projectionType) {
        case MPProjectionTypeAttribute:
            projectionType = @"Attribute";
            break;
            
        case MPProjectionTypeEvent:
            projectionType = @"Event";
            break;
    }
    [description appendFormat:@" projectionType: %@\n", projectionType];
    
    NSString *propertyKind;
    switch (_propertyKind) {
        case MPProjectionPropertyKindEventField:
            propertyKind = @"Event Field";
            break;
            
        case MPProjectionPropertyKindEventAttribute:
            propertyKind = @"Event Attribute";
            break;
            
        case MPProjectionPropertyKindProductField:
            propertyKind = @"Product Field";
            break;
            
        case MPProjectionPropertyKindProductAttribute:
            propertyKind = @"Product Attribute";
            break;
            
        case MPProjectionPropertyKindPromotionField:
            propertyKind = @"Promotion Field";
            break;
            
        case MPProjectionPropertyKindPromotionAttribute:
            propertyKind = @"Promotion Attribute";
            break;
    }
    [description appendFormat:@" propertyKind: %@\n", propertyKind];
    
    return (NSString *)description;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.name) {
        [coder encodeObject:_name forKey:@"name"];
    }
    
    if (self.projectedName) {
        [coder encodeObject:_projectedName forKey:@"projectedName"];
    }
    
    [coder encodeObject:_configuration forKey:@"configuration"];
    [coder encodeInteger:_matchType forKey:@"matchType"];
    [coder encodeInteger:_projectionType forKey:@"projectionType"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_propertyKind] forKey:@"propertyKind"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_projectionId] forKey:@"projectionId"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_attributeIndex] forKey:@"attributeIndex"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];

    if (self) {
        [coder decodeObjectOfClass:[NSNumber class] forKey:@"propertyKind"];
        _configuration = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"configuration"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _projectedName = [coder decodeObjectOfClass:[NSString class] forKey:@"projectedName"];
        _matchType = (MPProjectionMatchType)[coder decodeIntegerForKey:@"matchType"];
        _projectionType = (MPProjectionType)[coder decodeIntegerForKey:@"projectionType"];
        _propertyKind = (MPProjectionPropertyKind)[[coder decodeObjectOfClass:[NSNumber class] forKey:@"propertyKind"] unsignedIntegerValue];
        _projectionId = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"projectionId"] unsignedIntegerValue];
        _attributeIndex = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"attributeIndex"] unsignedIntegerValue];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPBaseProjection *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject.name = [_name copy];
        copyObject.projectedName = [_projectedName copy];
        copyObject.matchType = _matchType;
        copyObject->_configuration = [_configuration copy];
        copyObject->_projectionType = _projectionType;
        copyObject->_propertyKind = _propertyKind;
        copyObject->_projectionId = _projectionId;
        copyObject->_attributeIndex = _attributeIndex;
    }
    
    return copyObject;
}

@end
