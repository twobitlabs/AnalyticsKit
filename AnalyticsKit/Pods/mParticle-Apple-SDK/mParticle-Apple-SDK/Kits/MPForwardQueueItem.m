#import "MPForwardQueueItem.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPKitFilter.h"
#import "MPKitExecStatus.h"
#import "MPForwardQueueParameters.h"

@implementation MPForwardQueueItem

@synthesize queueItemType = _queueItemType;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent {
    self = [super init];
    if (!self || !commerceEvent) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEcommerce;
    _commerceEvent = commerceEvent;
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPBaseEvent *)event messageType:(MPMessageType)messageType {
    self = [super init];
    if (!self || !selector || !event) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEvent;
    _selector = selector;
    _event = event;
    _messageType = messageType;
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType {
    self = [super init];
    if (!self || !selector) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeGeneralPurpose;
    _selector = selector;
    _queueParameters = parameters;
    _messageType = messageType;
    
    return self;
}

@end
