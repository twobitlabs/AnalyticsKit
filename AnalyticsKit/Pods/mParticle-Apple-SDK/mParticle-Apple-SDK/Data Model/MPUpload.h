#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"

@class MPSession;

@interface MPUpload : MPDataModelAbstract <NSCopying, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSData *uploadData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, strong, nullable) NSNumber *sessionId;
@property (nonatomic, unsafe_unretained) int64_t uploadId;


- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId uploadDictionary:(nonnull NSDictionary *)uploadDictionary;
- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId uploadId:(int64_t)uploadId UUID:(nonnull NSString *)uuid uploadData:(nonnull NSData *)uploadData timestamp:(NSTimeInterval)timestamp;

@end
