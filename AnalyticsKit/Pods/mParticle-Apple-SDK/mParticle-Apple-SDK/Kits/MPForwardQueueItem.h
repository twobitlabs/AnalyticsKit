#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import "MPKitProtocol.h"

@class MPBaseEvent;
@class MPCommerceEvent;
@class MPKitFilter;
@class MPKitExecStatus;
@class MPForwardQueueParameters;

typedef NS_ENUM(NSUInteger, MPQueueItemType) {
    MPQueueItemTypeEvent = 0,
    MPQueueItemTypeEcommerce,
    MPQueueItemTypeGeneralPurpose
};

@interface MPForwardQueueItem : NSObject

@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *commerceEvent;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *event;
@property (nonatomic, unsafe_unretained, readonly) MPMessageType messageType;
@property (nonatomic, unsafe_unretained, readonly) MPQueueItemType queueItemType;
@property (nonatomic, unsafe_unretained, readonly, nullable) SEL selector;
@property (nonatomic, strong, readonly, nullable) MPForwardQueueParameters *queueParameters;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent;
- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPBaseEvent *)event messageType:(MPMessageType)messageType;
- (nullable instancetype)initWithSelector:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType;

@end
