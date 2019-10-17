#import "MPEnums.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEventInstruction.h"

typedef NS_ENUM(NSInteger, MPCommerceEventKind) {
    MPCommerceEventKindUnknown = 0,
    MPCommerceEventKindProduct = 1,
    MPCommerceEventKindPromotion,
    MPCommerceEventKindImpression
};


@interface MPCommerceEvent(Dictionary)

- (instancetype)initWithAction:(MPCommerceEventAction)action;
- (NSString *)actionNameForAction:(MPCommerceEventAction)action;
- (MPCommerceEventAction)actionWithName:(NSString *)actionName;
- (void)addProducts:(NSArray<MPProduct *> *)products;
- (NSDictionary *)dictionaryRepresentation;
- (NSArray<MPCommerceEventInstruction *> *)expandedInstructions;
- (NSArray<MPProduct *> *const)addedProducts;
- (MPCommerceEventKind)kind;
- (void)removeProducts:(NSArray<MPProduct *> *)products;
- (NSArray<MPProduct *> *const)removedProducts;
- (void)resetLatestProducts;
- (NSMutableDictionary *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary *)beautifiedAttributes;
- (void)setImpressions:(NSDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)impressions;
- (void)setProducts:(NSArray<MPProduct *> *)products;
- (NSMutableDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)copyImpressionsMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSDate *)timestamp;
- (void)setTimestamp:(NSDate *)timestamp;

@end
