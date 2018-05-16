#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MPSegmentMembershipAction) {
    MPSegmentMembershipActionAdd = 1,
    MPSegmentMembershipActionDrop
};

@interface MPSegmentMembership : NSObject <NSCopying>

@property (nonatomic, unsafe_unretained) int64_t segmentId;
@property (nonatomic, unsafe_unretained) int64_t segmentMembershipId;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) MPSegmentMembershipAction action;

- (instancetype)initWithSegmentId:(int64_t)segmentId membershipDictionary:(NSDictionary *)membershipDictionary;
- (instancetype)initWithSegmentId:(int64_t)segmentId segmentMembershipId:(int64_t)segmentMembershipId timestamp:(NSTimeInterval)timestamp membershipAction:(MPSegmentMembershipAction)action __attribute__((objc_designated_initializer));

@end
