#import "MPTransactionAttributes.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "NSNumber+MPFormatter.h"
#import "MPILogger.h"
#import "MParticle.h"

// Internal keys
NSString *const kMPTAAffiliation = @"ta";
NSString *const kMPTAShipping = @"ts";
NSString *const kMPTATax = @"tt";
NSString *const kMPTARevenue = @"tr";
NSString *const kMPTATransactionId = @"ti";
NSString *const kMPTACouponCode = @"tcc";

// Expanded keys
NSString *const kMPExpTAAffiliation = @"Affiliation";
NSString *const kMPExpTAShipping = @"Shipping Amount";
NSString *const kMPExpTATax = @"Tax Amount";
NSString *const kMPExpTARevenue = @"Total Amount";
NSString *const kMPExpTATransactionId = @"Transaction Id";
NSString *const kMPExpTACouponCode = @"Coupon Code";

@interface MPTransactionAttributes()

@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableDictionary *beautifiedAttributes;

@end


@implementation MPTransactionAttributes

- (NSString *)description {
    __block NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ {\n", [[self class] description]];
    
    [_attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [description appendString:@"}\n"];
    
    return (NSString *)description;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MPTransactionAttributes class]]) {
        return NO;
    }
    
    return [_attributes isEqualToDictionary:((MPTransactionAttributes *)object)->_attributes];
}

#pragma mark Private accessors
- (NSMutableDictionary *)attributes {
    if (_attributes) {
        return _attributes;
    }
    
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:5];
    return _attributes;
}

- (NSMutableDictionary *)beautifiedAttributes {
    if (_beautifiedAttributes) {
        return _beautifiedAttributes;
    }
    
    _beautifiedAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
    return _beautifiedAttributes;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPTransactionAttributes *copyObject = [[[self class] alloc] init];
    if (copyObject) {
        copyObject->_attributes = [_attributes mutableCopy];
        copyObject->_beautifiedAttributes = _beautifiedAttributes ? [_beautifiedAttributes mutableCopy] : nil;
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
        NSDictionary *dictionary;
        
        @try {
            dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"attributes"];
        }
        
        @catch ( NSException *e) {
            dictionary = nil;
            MPILogError(@"Exception decoding MPTransactionAttributes: %@", [e reason]);
        }
        
        @finally {
            if (dictionary.count > 0) {
                self->_attributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
            }
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

#pragma mark MPTransactionAttributes+Dictionary
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *dictionary = nil;
    
    if (_attributes.count > 0) {
        dictionary = [_attributes transformValuesToString];
    }
    
    return dictionary;
}

- (NSDictionary *)beautifiedDictionaryRepresentation {
    NSDictionary *dictionary = nil;
    
    if (_beautifiedAttributes.count > 0) {
        dictionary = [_beautifiedAttributes transformValuesToString];
    }
    
    return dictionary;
}

#pragma mark Public accessors
- (NSString *)affiliation {
    return self.attributes[kMPTAAffiliation];
}

- (void)setAffiliation:(NSString *)affiliation {
    if (affiliation) {
        self.attributes[kMPTAAffiliation] = affiliation;
        self.beautifiedAttributes[kMPExpTAAffiliation] = affiliation;
    } else {
        [self.attributes removeObjectForKey:kMPTAAffiliation];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTAAffiliation];
    }
}

- (NSString *)couponCode {
    return self.attributes[kMPTACouponCode];
}

- (void)setCouponCode:(NSString *)couponCode {
    if (couponCode) {
        self.attributes[kMPTACouponCode] = couponCode;
        self.beautifiedAttributes[kMPExpTACouponCode] = couponCode;
    } else {
        [self.attributes removeObjectForKey:kMPTACouponCode];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTACouponCode];
    }
}

- (NSNumber *)shipping {
    return self.attributes[kMPTAShipping];
}

- (void)setShipping:(NSNumber *)shipping {
    if (shipping && [shipping isKindOfClass:[NSNumber class]]) {
        NSNumber *formattedNumber = [shipping formatWithNonScientificNotation];
        self.attributes[kMPTAShipping] = formattedNumber;
        self.beautifiedAttributes[kMPExpTAShipping] = formattedNumber;
    } else {
        [self.attributes removeObjectForKey:kMPTAShipping];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTAShipping];
    }
}

- (NSNumber *)tax {
    return self.attributes[kMPTATax];
}

- (void)setTax:(NSNumber *)tax {
    if (tax && [tax isKindOfClass:[NSNumber class]]) {
        NSNumber *formattedNumber = [tax formatWithNonScientificNotation];
        self.attributes[kMPTATax] = formattedNumber;
        self.beautifiedAttributes[kMPExpTATax] = formattedNumber;
    } else {
        [self.attributes removeObjectForKey:kMPTATax];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTATax];
    }
}

- (NSNumber *)revenue {
    return self.attributes[kMPTARevenue];
}

- (void)setRevenue:(NSNumber *)revenue {
    if (revenue && [revenue isKindOfClass:[NSNumber class]]) {
        NSNumber *formattedNumber = [revenue formatWithNonScientificNotation];
        self.attributes[kMPTARevenue] = formattedNumber;
        self.beautifiedAttributes[kMPExpTARevenue] = formattedNumber;
    } else {
        [self.attributes removeObjectForKey:kMPTARevenue];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTARevenue];
    }
}

- (NSString *)transactionId {
    return self.attributes[kMPTATransactionId];
}

- (void)setTransactionId:(NSString *)transactionId {
    if (transactionId) {
        self.attributes[kMPTATransactionId] = transactionId;
        self.beautifiedAttributes[kMPExpTATransactionId] = transactionId;
    } else {
        [self.attributes removeObjectForKey:kMPTATransactionId];
        [self.beautifiedAttributes removeObjectForKey:kMPExpTATransactionId];
    }
}

@end
