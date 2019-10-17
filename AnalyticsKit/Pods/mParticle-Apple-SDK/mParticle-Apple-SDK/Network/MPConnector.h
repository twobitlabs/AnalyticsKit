#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HTTPStatusCode) {
    HTTPStatusCodeSuccess = 200,
    HTTPStatusCodeCreated = 201,
    HTTPStatusCodeAccepted = 202,
    HTTPStatusCodeNoContent = 204,
    HTTPStatusCodeNotModified = 304,
    HTTPStatusCodeBadRequest = 400,
    HTTPStatusCodeUnauthorized = 401,
    HTTPStatusCodeForbidden = 403,
    HTTPStatusCodeNotFound = 404,
    HTTPStatusCodeTimeout = 408,
    HTTPStatusCodeTooManyRequests = 429,
    HTTPStatusCodeServerError = 500,
    HTTPStatusCodeNotImplemented = 501,
    HTTPStatusCodeBadGateway = 502,
    HTTPStatusCodeServiceUnavailable = 503,
    HTTPStatusCodeNetworkAuthenticationRequired = 511
};

@interface MPConnectorResponse : NSObject

@property (nonatomic, nullable) NSData *data;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic) NSTimeInterval downloadTime;
@property (nonatomic, nullable) NSHTTPURLResponse *httpResponse;

@end

@interface MPConnector : NSObject

- (nonnull MPConnectorResponse *)responseFromGetRequestToURL:(nonnull NSURL *)url;
- (nonnull MPConnectorResponse *)responseFromPostRequestToURL:(nonnull NSURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams;

@end
