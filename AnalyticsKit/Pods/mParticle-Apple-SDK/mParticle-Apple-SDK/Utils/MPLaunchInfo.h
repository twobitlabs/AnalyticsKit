#import <Foundation/Foundation.h>

@interface MPLaunchInfo : NSObject

@property (nonatomic, strong, readonly, nonnull) NSURL *url;
@property (nonatomic, strong, readonly, nullable) NSString *sourceApplication;
@property (nonatomic, strong, readonly, nullable) NSString *annotation;
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSString *, id> *options;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull instancetype)initWithURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;

@end
