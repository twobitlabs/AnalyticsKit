#import <Foundation/Foundation.h>

@interface MPKitActivity : NSObject

- (BOOL)isKitActive:(nonnull NSNumber *)integrationId;
- (nullable id)kitInstance:(nonnull NSNumber *)integrationId;
- (void)kitInstance:(nonnull NSNumber *)integrationId withHandler:(void (^ _Nonnull)(id _Nullable kitInstance))handler;

@end
