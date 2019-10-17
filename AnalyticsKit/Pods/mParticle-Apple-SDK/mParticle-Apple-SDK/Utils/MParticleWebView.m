#import "MParticleWebView.h"
#import "MPILogger.h"
#import "mParticle.h"

static NSString *webViewUserAgent = nil;

@interface  MParticleWebView ()
@property (nonatomic, assign) CGRect frame;
@property (nonatomic) NSString *customUserAgent;
@end

@implementation MParticleWebView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)string {
    if (![string isEqualToString:@"navigator.userAgent"]) {
        MPILogError(@"Unimplemented call to evaluate js");
        return nil;
    }
    return webViewUserAgent;
}

+ (void)setCustomUserAgent:(NSString *)userAgent {
    webViewUserAgent = userAgent;
}

@end
