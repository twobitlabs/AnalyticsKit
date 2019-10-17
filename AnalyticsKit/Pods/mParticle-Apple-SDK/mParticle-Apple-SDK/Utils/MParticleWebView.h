#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface MParticleWebView : NSObject

- (instancetype)initWithFrame:(CGRect)frame;
- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)string;
+ (void)setCustomUserAgent:(NSString *)userAgent;

@end

NS_ASSUME_NONNULL_END
