#import "MPPromotion.h"
#import "MPIConstants.h"
#include "MPHasher.h"
#import "NSDictionary+MPCaseInsensitive.h"

// Internal keys
NSString *const kMPPMAction = @"an";
NSString *const kMPPMCreative = @"cr";
NSString *const kMPPMName = @"nm";
NSString *const kMPPMPosition = @"ps";
NSString *const kMPPMPromotionId = @"id";
NSString *const kMPPMPromotionList = @"pl";

// Expanded keys
NSString *const kMPExpPMCreative = @"Creative";
NSString *const kMPExpPMName = @"Name";
NSString *const kMPExpPMPosition = @"Position";
NSString *const kMPExpPMPromotionId = @"Id";

static NSArray *actionNames;

#pragma mark - MPPromotion
@interface MPPromotion()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *attributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *beautifiedAttributes;

@end

@implementation MPPromotion

@synthesize beautifiedAttributes = _beautifiedAttributes;

+ (void)initialize {
    actionNames = @[@"click", @"view"];
}

- (NSString *)description {
    __block NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ {\n", [[self class] description]];
    
    [_attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [description appendString:@"}\n"];
    
    return (NSString *)description;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MPPromotion class]]) {
        return NO;
    }
    
    if (_attributes && ((MPPromotion *)object)->_attributes) {
        return [_attributes isEqualToDictionary:((MPPromotion *)object)->_attributes];
    } else if (_attributes || ((MPPromotion *)object)->_attributes) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark Private accessors
- (NSMutableDictionary<NSString *, NSString *> *)attributes {
    if (_attributes) {
        return _attributes;
    }
    
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:4];
    return _attributes;
}

- (NSMutableDictionary<NSString *, NSString *> *)beautifiedAttributes {
    if (_beautifiedAttributes) {
        return _beautifiedAttributes;
    }
    
    _beautifiedAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
    return _beautifiedAttributes;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPPromotion *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_attributes = [_attributes mutableCopy];
        copyObject->_beautifiedAttributes = [_beautifiedAttributes mutableCopy];
    }
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (_attributes) {
        [coder encodeObject:_attributes forKey:@"attributes"];
    }
    
    if (_beautifiedAttributes) {
        [coder encodeObject:_beautifiedAttributes forKey:@"beautifiedAttributes"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        NSDictionary<NSString *, NSString *> *dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"attributes"];
        if (dictionary.count > 0) {
            self->_attributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        }
        
        dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"beautifiedAttributes"];
        if (dictionary) {
            self->_beautifiedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        }
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark MPPromotion+Dictionary
- (NSDictionary<NSString *, NSString *> *)dictionaryRepresentation {
    return _attributes;
}

- (NSDictionary<NSString *, NSString *> *)beautifiedDictionaryRepresentation {
    return _beautifiedAttributes;
}

- (MPPromotion *)copyMatchingHashedProperties:(NSDictionary *)hashedMap {
    __block MPPromotion *copyPromotion = [self copy];
    NSNumber *const zero = @0;
    
    [_beautifiedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        NSString *hashedKey = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        id hashedValue = hashedMap[hashedKey];
        
        if ([hashedValue isEqualToNumber:zero]) {
            [copyPromotion->_beautifiedAttributes removeObjectForKey:key];
        }
    }];
    
    return copyPromotion;
}

#pragma mark Public accessors
- (NSString *)creative {
    return self.attributes[kMPPMCreative];
}

- (void)setCreative:(NSString *)creative {
    if (creative) {
        self.attributes[kMPPMCreative] = creative;
        self.beautifiedAttributes[kMPExpPMCreative] = creative;
    } else {
        [self.attributes removeObjectForKey:kMPPMCreative];
        [self.beautifiedAttributes removeObjectForKey:kMPExpPMCreative];
    }
}

- (NSString *)name {
    return self.attributes[kMPPMName];
}

- (void)setName:(NSString *)name {
    if (name) {
        self.attributes[kMPPMName] = name;
        self.beautifiedAttributes[kMPExpPMName] = name;
    } else {
        [self.attributes removeObjectForKey:kMPPMName];
        [self.beautifiedAttributes removeObjectForKey:kMPExpPMName];
    }
}

- (NSString *)position {
    return self.attributes[kMPPMPosition];
}

- (void)setPosition:(NSString *)position {
    if (position) {
        self.attributes[kMPPMPosition] = position;
        self.beautifiedAttributes[kMPExpPMPosition] = position;
    } else {
        [self.attributes removeObjectForKey:kMPPMPosition];
        [self.beautifiedAttributes removeObjectForKey:kMPExpPMPosition];
    }
}

- (NSString *)promotionId {
    return self.attributes[kMPPMPromotionId];
}

- (void)setPromotionId:(NSString *)promotionId {
    if (promotionId) {
        self.attributes[kMPPMPromotionId] = promotionId;
        self.beautifiedAttributes[kMPExpPMPromotionId] = promotionId;
    } else {
        [self.attributes removeObjectForKey:kMPPMPromotionId];
        [self.beautifiedAttributes removeObjectForKey:kMPExpPMPromotionId];
    }
}

@end

#pragma mark - MPPromotionContainer
@interface MPPromotionContainer()

@property (nonatomic, strong) NSMutableArray<MPPromotion *> *promotionsArray;

@end

@implementation MPPromotionContainer

- (instancetype)initWithAction:(MPPromotionAction)action promotion:(MPPromotion *)promotion {
    self = [super init];
    if (self) {
        _action = action;
        
        if (!MPIsNull(promotion)) {
            NSAssert([promotion isKindOfClass:[MPPromotion class]], @"'promotion' must be of class type MPPromotion.");
            [self.promotionsArray addObject:promotion];
        }
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPPromotionContainer class]]) {
        return NO;
    }
    
    BOOL isEqual = _action == ((MPPromotionContainer *)object)->_action;
    
    if (isEqual) {
        if (_promotionsArray && ((MPPromotionContainer *)object)->_promotionsArray) {
            isEqual = [_promotionsArray isEqualToArray:((MPPromotionContainer *)object)->_promotionsArray];
        } else {
            isEqual = NO;
        }
    }
    
    return isEqual;
}

#pragma mark Private accessors
- (NSMutableArray *)promotionsArray {
    if (_promotionsArray) {
        return _promotionsArray;
    }
    
    _promotionsArray = [[NSMutableArray alloc] initWithCapacity:1];
    return _promotionsArray;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPPromotionContainer *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_action = _action;
        copyObject.promotionsArray = _promotionsArray ? [[NSMutableArray alloc] initWithArray:[_promotionsArray copy]] : nil;
    }
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:(NSUInteger)_action forKey:@"action"];
    
    if (_promotionsArray) {
        [coder encodeObject:_promotionsArray forKey:@"promotionsArray"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        _action = (MPPromotionAction)[coder decodeIntegerForKey:@"action"];
        
        NSArray *array = [coder decodeObjectOfClass:[NSArray class] forKey:@"promotionsArray"];
        if (array) {
            _promotionsArray = [[NSMutableArray alloc] initWithArray:array];
        }
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark MPPromotionContainer+Dictionary
- (NSString *)actionNameForAction:(MPPromotionAction)action {
    NSUInteger actionRaw = (NSUInteger)action;
    if (actionRaw >= 2) {
        return nil;
    }
    
    return actionNames[actionRaw];
}

- (MPPromotionAction)actionWithName:(NSString *)actionName {
    return (MPPromotionAction)[actionNames indexOfObject:actionName];
}

- (NSDictionary *)dictionaryRepresentation {
    if (_promotionsArray.count == 0) {
        return nil;
    }
    
    NSString *promotionAction = [self actionNameForAction:_action];
    NSMutableDictionary *dictionary = [@{kMPPMAction:promotionAction} mutableCopy];
    __block NSMutableArray *promotionDictionaries = [[NSMutableArray alloc] initWithCapacity:_promotionsArray.count];
    
    [_promotionsArray enumerateObjectsUsingBlock:^(MPPromotion *promotion, NSUInteger idx, BOOL *stop) {
        NSDictionary *promotionDictionary = [promotion dictionaryRepresentation];
        
        if (promotionDictionary) {
            [promotionDictionaries addObject:promotionDictionary];
        }
    }];
    
    if (promotionDictionaries.count > 0) {
        dictionary[kMPPMPromotionList] = promotionDictionaries;
        return (NSDictionary *)dictionary;
    } else {
        return nil;
    }
}

- (NSDictionary *)beautifiedDictionaryRepresentation {
    if (_promotionsArray.count == 0) {
        return nil;
    }
    
    NSString *promotionAction = [self actionNameForAction:_action];
    NSMutableDictionary *dictionary = [@{kMPPMAction:promotionAction} mutableCopy];
    __block NSMutableArray *promotionDictionaries = [[NSMutableArray alloc] initWithCapacity:_promotionsArray.count];
    
    [_promotionsArray enumerateObjectsUsingBlock:^(MPPromotion *promotion, NSUInteger idx, BOOL *stop) {
        NSDictionary *promotionDictionary = [promotion beautifiedDictionaryRepresentation];
        
        if (promotionDictionary) {
            [promotionDictionaries addObject:promotionDictionary];
        }
    }];
    
    if (promotionDictionaries.count > 0) {
        dictionary[kMPPMPromotionList] = promotionDictionaries;
        return (NSDictionary *)dictionary;
    } else {
        return nil;
    }
}

- (void)setPromotions:(NSArray<MPPromotion *> *)promotions {
    self.promotionsArray = promotions ? [[NSMutableArray alloc] initWithArray:promotions] : nil;
}

- (MPPromotionContainer *)copyMatchingHashedProperties:(NSDictionary *)hashedMap {
    MPPromotionContainer *copyPromotionContainer = [self copy];
    
    __block NSMutableArray<MPPromotion *> *promotions = [[NSMutableArray alloc] init];
    [_promotionsArray enumerateObjectsUsingBlock:^(MPPromotion *promotion, NSUInteger idx, BOOL *stop) {
        MPPromotion *filteredPromotion = [promotion copyMatchingHashedProperties:hashedMap];
        
        if (filteredPromotion) {
            [promotions addObject:filteredPromotion];
        }
    }];
    
    copyPromotionContainer->_promotionsArray = promotions;
    
    return copyPromotionContainer;
}

#pragma mark Public accessors
- (NSArray<MPPromotion *> *)promotions {
    return _promotionsArray.count > 0 ? (NSArray *)_promotionsArray : nil;
}

#pragma mark Public methods
- (void)addPromotion:(MPPromotion *)promotion {
    NSAssert(!MPIsNull(promotion), @"'promotion' cannot be nil/null.");
    NSAssert([promotion isKindOfClass:[MPPromotion class]], @"'promotion' is not an instance of MPPromotion.");
    
    if (_action == MPPromotionActionClick) {
        NSAssert(self.promotionsArray.count == 0, @"There can only be one promotion with action type 'click'.");
    }
    
    if (MPIsNull(promotion)) {
        return;
    }
    
    [self.promotionsArray addObject:promotion];
}

@end
