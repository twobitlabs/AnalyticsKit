#import <Foundation/Foundation.h>
#import "MPExtensionProtocol.h"
#import "MPKitProtocol.h"
#import "mParticle.h"

@class MPKitFilter;
@class MPKitExecStatus;
@class MPCommerceEvent;
@class MPBaseEvent;
@class MPForwardQueueParameters;
@class MPKitConfiguration;

@interface MPKitContainer : NSObject

@property (nonatomic, copy) void (^ _Nonnull attributionCompletionHandler)(MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error);
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *, MPAttributionResult *> *attributionInfo;
@property (nonatomic, strong, nonnull) NSArray<NSDictionary *> *originalConfig;

+ (BOOL)registerKit:(nonnull id<MPExtensionKitProtocol>)kitRegister;
+ (nullable NSSet<id<MPExtensionKitProtocol>> *)registeredKits;

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry;
- (void)configureKits:(nullable NSArray<NSDictionary *> *)kitsConfiguration;
- (nullable NSArray<NSNumber *> *)supportedKits;
- (void)initializeKits;
- (void)forwardCommerceEventCall:(nonnull MPCommerceEvent *)commerceEvent;
- (void)forwardSDKCall:(nonnull SEL)selector event:(nullable MPBaseEvent *)event parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType userInfo:(nullable NSDictionary *)userInfo;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributeKey:(nonnull NSString *)key value:(nullable id)value kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributes:(nonnull NSDictionary *)userAttributes kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, NSDictionary * _Nullable forwardAttributes, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector consentState:(nullable MPConsentState *)state kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPConsentState * _Nullable filteredConsentState, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (void)forwardIdentitySDKCall:(nonnull SEL)selector kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler;
- (nullable NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(nonnull NSNumber *)integrationId;
- (BOOL)shouldDelayUpload: (NSTimeInterval) maxWaitTime;
@end
