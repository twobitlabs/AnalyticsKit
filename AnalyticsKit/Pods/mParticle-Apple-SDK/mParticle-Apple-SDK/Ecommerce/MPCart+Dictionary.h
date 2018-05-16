@interface MPCart(Dictionary)

- (void)addProducts:(nonnull NSArray<MPProduct *> *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList;
- (nullable NSDictionary<NSString *, __kindof NSArray *> *)dictionaryRepresentation;
- (void)removeProducts:(nonnull NSArray<MPProduct *> *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList;

@end
