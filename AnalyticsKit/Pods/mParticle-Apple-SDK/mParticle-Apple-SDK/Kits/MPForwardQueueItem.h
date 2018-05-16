#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import "MPKitProtocol.h"

@class MPEvent;
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
@property (nonatomic, strong, readonly, nullable) MPEvent *event;
@property (nonatomic, copy, readonly, nullable) void (^commerceEventCompletionHandler)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus);
@property (nonatomic, copy, readonly, nullable) void (^eventCompletionHandler)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus);
@property (nonatomic, copy, readonly, nullable) void (^generalPurposeCompletionHandler)(_Nonnull id<MPKitProtocol> kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus);
@property (nonatomic, unsafe_unretained, readonly) MPMessageType messageType;
@property (nonatomic, unsafe_unretained, readonly) MPQueueItemType queueItemType;
@property (nonatomic, unsafe_unretained, readonly, nullable) SEL selector;
@property (nonatomic, strong, readonly, nullable) MPForwardQueueParameters *queueParameters;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler;
- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPEvent *)event messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler;
- (nullable instancetype)initWithSelector:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler;

@end
