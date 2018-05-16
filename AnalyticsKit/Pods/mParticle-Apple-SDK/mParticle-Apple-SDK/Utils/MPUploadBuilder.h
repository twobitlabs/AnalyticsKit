#import <Foundation/Foundation.h>

@class MPMessage;
@class MPUpload;
@class MPSession;

@interface MPUploadBuilder : NSObject

@property (nonatomic, strong, readonly, nullable) NSNumber *sessionId;
@property (nonatomic, strong, readonly, nonnull) NSMutableArray<NSNumber *> *preparedMessageIds;

+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid messages:(nonnull NSArray<MPMessage *> *)messages uploadInterval:(NSTimeInterval)uploadInterval;
+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (nonnull instancetype)initWithMpid: (nonnull NSNumber *) mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (void)build:(void (^ _Nonnull)(MPUpload * _Nullable upload))completionHandler;
- (nonnull MPUploadBuilder *)withUserAttributes:(nonnull NSDictionary<NSString *, id> *)userAttributes deletedUserAttributes:(nullable NSSet<NSString *> *)deletedUserAttributes;
- (nonnull MPUploadBuilder *)withUserIdentities:(nonnull NSArray<NSDictionary<NSString *, id> *> *)userIdentities;

@end
