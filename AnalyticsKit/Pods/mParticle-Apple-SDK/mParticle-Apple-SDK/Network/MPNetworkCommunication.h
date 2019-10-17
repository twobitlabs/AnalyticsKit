#import <Foundation/Foundation.h>

@class MPSession;
@class MPUpload;
@class MPSegment;
@class MPIdentityApiRequest;
@class MPIdentityHTTPSuccessResponse;
@class MPIdentityHTTPBaseSuccessResponse;
@class MPIdentityHTTPModifySuccessResponse;
@class MPConnector;

extern NSString * _Nonnull const kMPURLScheme;
extern NSString * _Nonnull const kMPURLHost;
extern NSString * _Nonnull const kMPURLHostConfig;

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegments
};

typedef void(^ _Nonnull MPSegmentResponseHandler)(BOOL success, NSArray<MPSegment *> * _Nullable segments, NSTimeInterval elapsedTime, NSError * _Nullable error);
typedef void(^ _Nonnull MPUploadsCompletionHandler)(void);

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void(^ _Nonnull MPConfigCompletionHandler)(BOOL success);

@interface MPNetworkCommunication : NSObject

- (MPConnector *_Nonnull)makeConnector;
- (void)requestConfig:(nullable MPConnector *)connector withCompletionHandler:(MPConfigCompletionHandler)completionHandler;
- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler;
- (void)upload:(nonnull NSArray<MPUpload *> *)uploads completionHandler:(MPUploadsCompletionHandler)completionHandler;

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue;

@end
