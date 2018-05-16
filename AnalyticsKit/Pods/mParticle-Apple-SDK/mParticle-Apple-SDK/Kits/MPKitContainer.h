#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import "MPExtensionProtocol.h"
#import "MPKitProtocol.h"
#import "mParticle.h"

@class MPKitFilter;
@class MPKitExecStatus;
@class MPCommerceEvent;
@class MPEvent;
@class MPForwardQueueParameters;
@class MPKitConfiguration;

@interface MPKitContainer : NSObject

@property (nonatomic, copy) void (^ _Nonnull attributionCompletionHandler)(MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error);
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *, MPAttributionResult *> *attributionInfo;

+ (BOOL)registerKit:(nonnull id<MPExtensionKitProtocol>)kitRegister;
+ (nullable NSSet<id<MPExtensionKitProtocol>> *)registeredKits;
+ (nonnull MPKitContainer *)sharedInstance;

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry;
- (void)configureKits:(nullable NSArray<NSDictionary *> *)kitsConfiguration;
- (nullable NSArray<NSNumber *> *)supportedKits;

- (void)forwardCommerceEventCall:(nonnull MPCommerceEvent *)commerceEvent kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector event:(nullable MPEvent *)event messageType:(MPMessageType)messageType userInfo:(nullable NSDictionary *)userInfo kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributeKey:(nonnull NSString *)key value:(nullable id)value kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributes:(nonnull NSDictionary *)userAttributes kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, NSDictionary * _Nullable forwardAttributes, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector errorMessage:(nullable NSString *)errorMessage exception:(nullable NSException *)exception eventInfo:(nullable NSDictionary *)eventInfo kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardIdentitySDKCall:(nonnull SEL)selector kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (nullable NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(nonnull NSNumber *)kitCode;
- (BOOL)shouldDelayUpload: (NSTimeInterval) maxWaitTime;
@end
