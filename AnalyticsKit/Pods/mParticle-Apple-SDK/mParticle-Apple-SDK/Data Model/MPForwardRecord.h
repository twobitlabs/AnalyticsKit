#import "MPEnums.h"
#import "MPIConstants.h"

@class MPKitFilter;
@class MPKitExecStatus;
@class MPBaseEvent;

@interface MPForwardRecord : NSObject

@property (nonatomic, unsafe_unretained) uint64_t forwardRecordId;
@property (nonatomic, strong, nonnull) NSMutableDictionary *dataDictionary;
@property (nonatomic, strong, nonnull) NSNumber *mpid;
@property (nonatomic, strong, nonnull) NSNumber *timestamp;

- (nonnull instancetype)initWithId:(int64_t)forwardRecordId data:(nonnull NSData *)data mpid:(nonnull NSNumber *)mpid;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus kitFilter:(nullable MPKitFilter *)kitFilter originalEvent:(nullable MPBaseEvent *)originalEvent;
- (nullable NSData *)dataRepresentation;

@end
