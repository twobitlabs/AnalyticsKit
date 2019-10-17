#import "MPBaseProjection.h"
#import "MPEnums.h"

@class MPAttributeProjection;

typedef NS_ENUM(NSUInteger, MPProjectionBehaviorSelector) {
    MPProjectionBehaviorSelectorForEach = 0,
    MPProjectionBehaviorSelectorLast
};

@interface MPProjectionMatch : NSObject <NSCopying, NSSecureCoding>
@property (nonatomic, strong, nullable) NSString *attributeKey;
@property (nonatomic, strong, nullable) NSArray<NSString *> *attributeValues;
@end

@interface MPEventProjection : MPBaseProjection <NSCopying, NSSecureCoding>

@property (nonatomic, strong, nullable) NSArray<MPProjectionMatch *> *projectionMatches;
@property (nonatomic, strong, nullable) NSArray<MPAttributeProjection *> *attributeProjections;
@property (nonatomic, unsafe_unretained) MPProjectionBehaviorSelector behaviorSelector;
@property (nonatomic, unsafe_unretained) MPEventType eventType;
@property (nonatomic, unsafe_unretained) MPMessageType messageType;
@property (nonatomic, unsafe_unretained) MPMessageType outboundMessageType;
@property (nonatomic, unsafe_unretained) NSUInteger maxCustomParameters;
@property (nonatomic, unsafe_unretained) BOOL appendAsIs;
@property (nonatomic, unsafe_unretained) BOOL isDefault;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration;

@end
