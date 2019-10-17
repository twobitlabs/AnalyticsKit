#import "MPProduct.h"
#import "MPIConstants.h"
#include "MPHasher.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "NSNumber+MPFormatter.h"
#import "MPILogger.h"
#import "MParticle.h"

// Internal
NSString *const kMPProductBrand = @"br";
NSString *const kMPProductCouponCode = @"cc";
NSString *const kMPProductVariant = @"va";
NSString *const kMPProductPosition = @"ps";
NSString *const kMPProductAddedToCart = @"act";
NSString *const kMPProductName = @"nm";
NSString *const kMPProductSKU = @"id";
NSString *const kMPProductUnitPrice = @"pr";
NSString *const kMPProductQuantity = @"qt";
NSString *const kMPProductRevenue = @"tr";
NSString *const kMPProductCategory = @"ca";
NSString *const kMPProductTotalAmount = @"tpa";
NSString *const kMPProductTransactionId = @"ti";
NSString *const kMPProductAffiliation = @"ta";
NSString *const kMPProductCurrency = @"cu";
NSString *const kMPProductTax = @"tt";
NSString *const kMPProductShipping = @"ts";

// Expanded
NSString *const kMPExpProductBrand = @"Brand";
NSString *const kMPExpProductName = @"Name";
NSString *const kMPExpProductSKU = @"Id";
NSString *const kMPExpProductUnitPrice = @"Item Price";
NSString *const kMPExpProductQuantity = @"Quantity";
NSString *const kMPExpProductCategory = @"Category";
NSString *const kMPExpProductCouponCode = @"Coupon Code";
NSString *const kMPExpProductVariant = @"Variant";
NSString *const kMPExpProductPosition = @"Position";
NSString *const kMPExpProductTotalAmount = @"Total Product Amount";

@interface MPProduct()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *beautifiedAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *objectDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *userDefinedAttributes;

@end

@implementation MPProduct

@synthesize beautifiedAttributes = _beautifiedAttributes;
@synthesize userDefinedAttributes = _userDefinedAttributes;

- (instancetype)initWithName:(NSString *)name sku:(NSString *)sku quantity:(NSNumber *)quantity price:(NSNumber *)price {
    Class stringClass = [NSString class];
    BOOL validName = !MPIsNull(name) && [name isKindOfClass:stringClass];
    NSAssert(validName, @"The 'name' variable not valid.");
    
    BOOL validSKU = !MPIsNull(sku) && [sku isKindOfClass:stringClass];
    NSAssert(validSKU, @"The 'sku' variable not valid.");
    
    BOOL validPrice = !MPIsNull(price) && [price isKindOfClass:[NSNumber class]];
    NSAssert(validPrice, @"The 'price' variable not valid.");
    
    self = [super init];
    if (!self || !validName || !validSKU || !validPrice) {
        return nil;
    }
    
    self.name = name;
    self.sku = sku;
    self.quantity = quantity ? : @1;
    self.price = price;

    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendString:@"MPProduct {\n"];
    
    [_objectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [_userDefinedAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [description appendFormat:@"  %@ : %@\n", key, obj];
    }];
    
    [description appendString:@"}\n"];

    return description;
}

- (BOOL)isEqual:(id)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPProduct class]]) {
        return NO;
    }
    
    return [_objectDictionary isEqualToDictionary:((MPProduct *)object)->_objectDictionary];
}

#pragma mark Private accessors
- (NSMutableDictionary<NSString *, id> *)beautifiedAttributes {
    if (_beautifiedAttributes) {
        return _beautifiedAttributes;
    }
    
    _beautifiedAttributes = [[NSMutableDictionary alloc] initWithCapacity:4];
    return _beautifiedAttributes;
}

- (NSMutableDictionary<NSString *, id> *)objectDictionary {
    if (_objectDictionary) {
        return _objectDictionary;
    }
    
    _objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    return _objectDictionary;
}

- (NSMutableDictionary<NSString *, id> *)userDefinedAttributes {
    if (_userDefinedAttributes) {
        return _userDefinedAttributes;
    }
    
    _userDefinedAttributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _userDefinedAttributes;
}

#pragma mark Private methods
- (void)calculateTotalAmount {
    double quantity = [self.quantity doubleValue] > 0 ? [self.quantity doubleValue] : 1;
    NSNumber *totalAmount = @(quantity * [self.price doubleValue]);
    
    self.objectDictionary[kMPProductTotalAmount] = totalAmount;
    self.beautifiedAttributes[kMPExpProductTotalAmount] = totalAmount;
}

#pragma mark Subscripting
- (id)objectForKeyedSubscript:(NSString *const)key {
    NSAssert(key != nil, @"'key' cannot be nil.");

    id object = [self.userDefinedAttributes objectForKey:key];
    
    if (!object) {
        object = [self.objectDictionary objectForKey:key];
    }
    
    return object;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    NSAssert(key != nil, @"'key' cannot be nil.");
    NSAssert(obj != nil, @"'obj' cannot be nil.");
    NSAssert([obj isKindOfClass:[NSString class]], @"'obj' for custom attributes must be a NSString");
    
    if (obj != nil) {
        [self.userDefinedAttributes setObject:obj forKey:key];
    }
}

- (NSArray *)allKeys {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    if (_objectDictionary) {
        [keys addObjectsFromArray:[_objectDictionary allKeys]];
    }
    
    if (_userDefinedAttributes) {
        [keys addObjectsFromArray:[_userDefinedAttributes allKeys]];
    }
    
    return (NSArray *)keys;
}

- (NSUInteger)count {
    NSUInteger count = self.objectDictionary.count + self.userDefinedAttributes.count;
    return count;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPProduct *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_beautifiedAttributes = _beautifiedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_beautifiedAttributes copy]] : nil;
        copyObject->_objectDictionary = _objectDictionary ? [[NSMutableDictionary alloc] initWithDictionary:[_objectDictionary copy]] : nil;
        copyObject->_userDefinedAttributes = _userDefinedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_userDefinedAttributes copy]] : nil;
    }
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (_beautifiedAttributes) {
        [coder encodeObject:_beautifiedAttributes forKey:@"beautifiedAttributes"];
    }
    
    if (_objectDictionary) {
        [coder encodeObject:_objectDictionary forKey:@"productDictionary"];
    }
    
    if (_userDefinedAttributes) {
        [coder encodeObject:_userDefinedAttributes forKey:@"userDefinedAttributes"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    
    NSDictionary *dictionary;
    
    dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"beautifiedAttributes"];
    if (dictionary) {
        self->_beautifiedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"productDictionary"];
    if (dictionary) {
        self->_objectDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    @try {
        dictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"userDefinedAttributes"];
    }
    
    @catch ( NSException *e) {
        dictionary = nil;
        MPILogError(@"Exception decoding MPProduct User Defined Attributes: %@", [e reason]);
    }
    
    @finally {
        if (dictionary.count > 0) {
            self->_userDefinedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        }
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark MPProduct+Dictionary
- (NSDictionary<NSString *, id> *)commerceDictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *commerceDictionary = [[NSMutableDictionary alloc] init];
    
    if (_userDefinedAttributes) {
        commerceDictionary[kMPAttributesKey] = [_userDefinedAttributes transformValuesToString];
    }
    
    if (_objectDictionary) {
        [commerceDictionary addEntriesFromDictionary:[_objectDictionary transformValuesToString]];
    }
    
    return commerceDictionary.count > 0 ? (NSDictionary *)commerceDictionary : nil;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    
    if (_objectDictionary) {
        [dictionary addEntriesFromDictionary:[_objectDictionary transformValuesToString]];
    }
    
    if (_userDefinedAttributes) {
        [dictionary addEntriesFromDictionary:[_userDefinedAttributes transformValuesToString]];
    }
    
    return dictionary.count > 0 ? (NSDictionary *)dictionary : nil;
}

- (NSDictionary<NSString *, id> *)beautifiedDictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    
    if (_beautifiedAttributes) {
        [dictionary addEntriesFromDictionary:[_beautifiedAttributes transformValuesToString]];
    }
    
    if (_userDefinedAttributes) {
        [dictionary addEntriesFromDictionary:[_userDefinedAttributes transformValuesToString]];
    }
    
    return dictionary.count > 0 ? (NSDictionary *)dictionary : nil;
}

- (void)setTimeAddedToCart:(NSDate *)date {
    if (date) {
        self.objectDictionary[kMPProductAddedToCart] = MPMilliseconds([date timeIntervalSince1970]);
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductAddedToCart];
    }
}

- (MPProduct *)copyMatchingHashedProperties:(NSDictionary *)hashedMap {
    __block MPProduct *copyProduct = [self copy];
    __block NSString *hashedKey;
    __block id hashedValue;
    NSNumber *const zero = @0;
    
    [_beautifiedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        hashedKey = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        hashedValue = hashedMap[hashedKey];
        
        if ([hashedValue isEqualToNumber:zero]) {
            [copyProduct->_beautifiedAttributes removeObjectForKey:key];
        }
    }];
    
    [_userDefinedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        hashedKey = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        hashedValue = hashedMap[hashedKey];
        
        if ([hashedValue isEqualToNumber:zero]) {
            [copyProduct->_userDefinedAttributes removeObjectForKey:key];
        }
    }];
    
    return copyProduct;
}

#pragma mark Public accessors
- (NSString *)affiliation {
    return self.objectDictionary[kMPProductAffiliation];
}

- (void)setAffiliation:(NSString *)affiliation {
    if (affiliation) {
        self.objectDictionary[kMPProductAffiliation] = affiliation;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductAffiliation];
    }
}

- (NSString *)brand {
    return self.objectDictionary[kMPProductBrand];
}

- (void)setBrand:(NSString *)brand {
    if (brand) {
        self.objectDictionary[kMPProductBrand] = brand;
        self.beautifiedAttributes[kMPExpProductBrand] = brand;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductBrand];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductBrand];
    }
}

- (NSString *)category {
    return self.objectDictionary[kMPProductCategory];
}

- (void)setCategory:(NSString *)category {
    if (category) {
        self.objectDictionary[kMPProductCategory] = category;
        self.beautifiedAttributes[kMPExpProductCategory] = category;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductCategory];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductCategory];
    }
}

- (NSString *)couponCode {
    return self.objectDictionary[kMPProductCouponCode];
}

- (void)setCouponCode:(NSString *)couponCode {
    if (couponCode) {
        self.objectDictionary[kMPProductCouponCode] = couponCode;
        self.beautifiedAttributes[kMPExpProductCouponCode] = couponCode;
    } else {
        [self.objectDictionary removeObjectForKey:kMPProductCouponCode];
        [self.beautifiedAttributes removeObjectForKey:kMPExpProductCouponCode];
    }
}

- (NSString *)currency {
    return self.objectDictionary[kMPProductCurrency];
}

- (void)setCurrency:(NSString *)currency {
    self.objectDictionary[kMPProductCurrency] = currency ? : @"USD";
}

- (NSString *)name {
    return self.objectDictionary[kMPProductName];
}

- (void)setName:(NSString *)name {
    NSAssert(!MPIsNull(name), @"'name' is a required property.");
    
    if (name) {
        self.objectDictionary[kMPProductName] = name;
        self.beautifiedAttributes[kMPExpProductName] = name;
    }
}

- (NSNumber *)price {
    return self.objectDictionary[kMPProductUnitPrice];
}

- (void)setPrice:(NSNumber *)price {
    BOOL validPrice = !MPIsNull(price) && [price isKindOfClass:[NSNumber class]];
    NSAssert(validPrice, @"'price' is a required property. Use @0 if the product does not have a price.");

    if (validPrice) {
        NSNumber *formattedPrice = [price formatWithNonScientificNotation];
        self.objectDictionary[kMPProductUnitPrice] = formattedPrice;
        self.beautifiedAttributes[kMPExpProductUnitPrice] = formattedPrice;
        [self calculateTotalAmount];
    }
}

- (NSString *)sku {
    return self.objectDictionary[kMPProductSKU];
}

- (void)setSku:(NSString *)sku {
    NSAssert(!MPIsNull(sku), @"'sku' is a required property.");
    
    if (sku) {
        self.objectDictionary[kMPProductSKU] = sku;
        self.beautifiedAttributes[kMPExpProductSKU] = sku;
    }
}

- (NSString *)transactionId {
    return self.objectDictionary[kMPProductTransactionId];
}

- (void)setTransactionId:(NSString *)transactionId {
    if (transactionId) {
        self.objectDictionary[kMPProductTransactionId] = transactionId;
    }
}

- (NSString *)variant {
    return self.objectDictionary[kMPProductVariant];
}

- (void)setVariant:(NSString *)variant {
    if (variant) {
        self.objectDictionary[kMPProductVariant] = variant;
        self.beautifiedAttributes[kMPExpProductVariant] = variant;
    }
}

- (double)shippingAmount {
    return [self.objectDictionary[kMPProductShipping] doubleValue];
}

- (void)setShippingAmount:(double)shippingAmount {
    self.objectDictionary[kMPProductShipping] = @(shippingAmount);
}

- (double)taxAmount {
    return [self.objectDictionary[kMPProductTax] doubleValue];
}

- (void)setTaxAmount:(double)taxAmount {
    self.objectDictionary[kMPProductTax] = @(taxAmount);
}

- (double)totalAmount {
    return [self.objectDictionary[kMPProductRevenue] doubleValue];
}

- (void)setTotalAmount:(double)totalAmount {
    self.objectDictionary[kMPProductRevenue] = @(totalAmount);
}

- (double)unitPrice {
    return [self.price doubleValue];
}

- (void)setUnitPrice:(double)unitPrice {
    self.price = @(unitPrice);
}

- (NSUInteger)position {
    return [self.objectDictionary[kMPProductPosition] integerValue];
}

- (void)setPosition:(NSUInteger)position {
    NSNumber *positionNumber = @(position);
    self.objectDictionary[kMPProductPosition] = positionNumber;
    self.beautifiedAttributes[kMPExpProductPosition] = positionNumber;
}

- (NSNumber *)quantity {
    return self.objectDictionary[kMPProductQuantity];
}

- (void)setQuantity:(NSNumber *)quantity {
    BOOL validQuantity = !MPIsNull(quantity) && [quantity isKindOfClass:[NSNumber class]];
    NSAssert(validQuantity, @"The 'quantity' variable is not valid.");

    if (validQuantity) {
        self.objectDictionary[kMPProductQuantity] = quantity;
        self.beautifiedAttributes[kMPExpProductQuantity] = quantity;
        [self calculateTotalAmount];
        
        if (self.objectDictionary[kMPProductAddedToCart]) {
            [self setTimeAddedToCart:[NSDate date]];
        }
    }
}

@end
