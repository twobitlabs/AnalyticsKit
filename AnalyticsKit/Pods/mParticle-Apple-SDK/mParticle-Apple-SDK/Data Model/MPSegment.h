#import "MPDataModelAbstract.h"

@class MPSegmentMembership;

extern NSString *const kMPSegmentListKey;

@interface MPSegment : MPDataModelAbstract <NSCopying>

@property (nonatomic, strong) NSNumber *segmentId;
@property (nonatomic, strong) NSArray *endpointIds;
@property (nonatomic, strong, readonly) NSDate *expiration;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<MPSegmentMembership *> *memberships;
@property (nonatomic, unsafe_unretained, readonly) BOOL expired;

- (instancetype)initWithSegmentId:(NSNumber *)segmentId UUID:(NSString *)uuid name:(NSString *)name memberships:(NSArray<MPSegmentMembership *> *)memberships endpointIds:(NSArray *)endpointIds;
- (instancetype)initWithDictionary:(NSDictionary *)segmentDictionary;

@end
