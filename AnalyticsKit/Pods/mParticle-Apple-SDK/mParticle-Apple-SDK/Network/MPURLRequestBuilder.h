#import <Foundation/Foundation.h>

@interface MPURLRequestBuilder : NSObject

@property (nonatomic, strong, nonnull) NSString *httpMethod;
@property (nonatomic, strong, nullable) NSData *postData;
@property (nonatomic, strong, nonnull) NSURL *url;

+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull NSURL *)url;
+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull NSURL *)url message:(nullable NSString *)message httpMethod:(nullable NSString *)httpMethod;
+ (NSTimeInterval)requestTimeout;
+ (void)tryToCaptureUserAgent;
- (nonnull instancetype)initWithURL:(nonnull NSURL *)url;
- (nonnull MPURLRequestBuilder *)withHeaderData:(nullable NSData *)headerData;
- (nonnull MPURLRequestBuilder *)withHttpMethod:(nonnull NSString *)httpMethod;
- (nonnull MPURLRequestBuilder *)withPostData:(nullable NSData *)postData;
- (nonnull NSMutableURLRequest *)build;

@end
