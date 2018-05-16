#import "MPSegmentMembership.h"

NSString *const kMPSegmentMembershipTimestampKey = @"ct";
NSString *const kMPSegmentMembershipActionKey = @"a";
NSString *const kMPSegmentMembershipAdd = @"add";
NSString *const kMPSegmentMembershipDrop = @"drop";

@implementation MPSegmentMembership

- (instancetype)init {
    return [self initWithSegmentId:0 segmentMembershipId:0 timestamp:[[NSDate date] timeIntervalSince1970] membershipAction:MPSegmentMembershipActionAdd];
}

- (instancetype)initWithSegmentId:(int64_t)segmentId segmentMembershipId:(int64_t)segmentMembershipId timestamp:(NSTimeInterval)timestamp membershipAction:(MPSegmentMembershipAction)action {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _segmentId = segmentId;
    _segmentMembershipId = segmentMembershipId;
    _timestamp = timestamp;
    _action = action;
    
    return self;
}

- (instancetype)initWithSegmentId:(int64_t)segmentId membershipDictionary:(NSDictionary *)membershipDictionary {
    MPSegmentMembershipAction action;
    if ([membershipDictionary[kMPSegmentMembershipActionKey] isEqualToString:kMPSegmentMembershipAdd]) {
        action = MPSegmentMembershipActionAdd;
    } else {
        action = MPSegmentMembershipActionDrop;
    }
    
    NSTimeInterval timestamp = [membershipDictionary[kMPSegmentMembershipTimestampKey] doubleValue] / 1000.0;
    
    return [self initWithSegmentId:segmentId
               segmentMembershipId:0
                         timestamp:timestamp
                  membershipAction:action];
}

- (NSString *)description {
    NSString *actionString = self.action == MPSegmentMembershipActionAdd ? kMPSegmentMembershipAdd : kMPSegmentMembershipDrop;
    return [NSString stringWithFormat:@"  MPSegmentMembership Timestamp: %.4f Action: %@", self.timestamp, actionString];
}

- (BOOL)isEqual:(MPSegmentMembership *)object {
    BOOL isEqual = _segmentMembershipId == object.segmentMembershipId &&
                   _timestamp == object.timestamp &&
                   _action == object.action;
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPSegmentMembership *copyObject = [[MPSegmentMembership alloc] initWithSegmentId:_segmentId
                                                                 segmentMembershipId:_segmentMembershipId
                                                                           timestamp:_timestamp
                                                                    membershipAction:_action];
    
    return copyObject;
}

@end
