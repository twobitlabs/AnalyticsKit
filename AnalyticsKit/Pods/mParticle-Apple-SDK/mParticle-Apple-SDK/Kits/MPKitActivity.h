#import <Foundation/Foundation.h>

@interface MPKitActivity : NSObject

- (BOOL)isKitActive:(nonnull NSNumber *)kitCode;
- (nullable id)kitInstance:(nonnull NSNumber *)kitCode;
- (void)kitInstance:(nonnull NSNumber *)kitCode withHandler:(void (^ _Nonnull)(id _Nullable kitInstance))handler;

@end
