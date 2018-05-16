#import <Foundation/Foundation.h>

@interface NSDictionary(MPCaseInsensitive)

- (nullable NSString *)caseInsensitiveKey:(nonnull NSString *)key;
- (nullable id)valueForCaseInsensitiveKey:(nonnull NSString *)key;
- (nonnull NSDictionary<NSString *, NSString *> *)transformValuesToString;

@end
