#import <Foundation/Foundation.h>

@class MPSession;
@class MPUpload;
@class MPSegment;
@class MPIdentityApiRequest;
@class MPIdentityHTTPSuccessResponse;
@class MPIdentityHTTPBaseSuccessResponse;
@class MPIdentityHTTPModifySuccessResponse;

extern NSString * _Nonnull const kMPURLScheme;
extern NSString * _Nonnull const kMPURLHost;
extern NSString * _Nonnull const kMPURLHostConfig;

typedef NS_ENUM(NSInteger, MPNetworkResponseAction) {
    MPNetworkResponseActionNone = 0,
    MPNetworkResponseActionDeleteBatch,
    MPNetworkResponseActionThrottle
};

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegments
};

typedef void(^ _Nonnull MPSegmentResponseHandler)(BOOL success, NSArray<MPSegment *> * _Nullable segments, NSTimeInterval elapsedTime, NSError * _Nullable error);
typedef void(^ _Nonnull MPUploadsCompletionHandler)(BOOL success, MPUpload * _Nullable upload, NSDictionary * _Nullable responseDictionary, BOOL finished);

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);

@interface MPNetworkCommunication : NSObject

@property (nonatomic, unsafe_unretained, readonly) BOOL inUse;
@property (nonatomic, unsafe_unretained, readonly) BOOL retrievingSegments;

- (void)requestConfig:(void(^ _Nonnull)(BOOL success, NSDictionary * _Nullable configurationDictionary, NSString * _Nullable eTag))completionHandler;
- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler;
- (void)upload:(nonnull NSArray<MPUpload *> *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler;

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue;

@end
