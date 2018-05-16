#import "MPEvent.h"
#import "MPIConstants.h"

@interface MPEvent(Internal)

@property (nonatomic, strong, nullable) NSDate *timestamp;

- (void)beginTiming;
- (nullable NSDictionary *)breadcrumbDictionaryRepresentation;
- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation;
- (void)endTiming;
- (nullable NSDictionary *)screenDictionaryRepresentation;

@end
