#import "MPBaseProjection.h"

@interface MPAttributeProjection : MPBaseProjection <NSCopying, NSSecureCoding>

@property (nonatomic, unsafe_unretained) MPDataType dataType;
@property (nonatomic, unsafe_unretained) BOOL required;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex;

@end
