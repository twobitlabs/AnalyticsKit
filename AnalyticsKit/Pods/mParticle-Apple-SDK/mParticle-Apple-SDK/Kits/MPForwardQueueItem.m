#import "MPForwardQueueItem.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPKitFilter.h"
#import "MPKitExecStatus.h"
#import "MPForwardQueueParameters.h"

@implementation MPForwardQueueItem

@synthesize queueItemType = _queueItemType;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !commerceEvent || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEcommerce;
    _commerceEvent = commerceEvent;
    _commerceEventCompletionHandler = [completionHandler copy];
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPEvent *)event messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !selector || !event || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEvent;
    _selector = selector;
    _event = event;
    _messageType = messageType;
    _eventCompletionHandler = [completionHandler copy];
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !selector || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeGeneralPurpose;
    _selector = selector;
    _generalPurposeCompletionHandler = [completionHandler copy];
    _queueParameters = parameters;
    _messageType = messageType;
    
    return self;
}

@end
