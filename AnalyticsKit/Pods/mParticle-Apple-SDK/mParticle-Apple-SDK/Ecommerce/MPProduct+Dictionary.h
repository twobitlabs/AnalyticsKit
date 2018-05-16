#import "MPProduct.h"

@interface MPProduct(Dictionary)

- (NSDictionary<NSString *, id> *)commerceDictionaryRepresentation;
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;
- (NSDictionary<NSString *, id> *)beautifiedDictionaryRepresentation;
- (void)setTimeAddedToCart:(NSDate *)date;
- (MPProduct *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSMutableDictionary<NSString *, id> *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary<NSString *, id> *)beautifiedAttributes;
- (NSMutableDictionary<NSString *, id> *)userDefinedAttributes;
- (void)setUserDefinedAttributes:(NSMutableDictionary<NSString *, id> *)userDefinedAttributes;

@end
