@interface MPPromotion(Dictionary)

- (NSDictionary<NSString *, NSString *> *)dictionaryRepresentation;
- (NSDictionary<NSString *, NSString *> *)beautifiedDictionaryRepresentation;
- (MPPromotion *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSMutableDictionary<NSString *, NSString *> *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary<NSString *, NSString *> *)beautifiedAttributes;

@end


@interface MPPromotionContainer(Dictionary)

- (NSString *)actionNameForAction:(MPPromotionAction)action;
- (MPPromotionAction)actionWithName:(NSString *)actionName;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)beautifiedDictionaryRepresentation;
- (void)setPromotions:(NSArray *)promotions;
- (MPPromotionContainer *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;

@end
