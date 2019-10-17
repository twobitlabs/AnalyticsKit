#import "MPEnums.h"
#import "MPNetworkCommunication.h"

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
    #import <CoreLocation/CoreLocation.h>

    @class MParticleUserNotification;
#endif

@class MPSession;
@class MPMessage;
@class MPNetworkPerformance;
@class MPNotificationController;
@class MPBaseEvent;
@class MPEvent;
@class MPCommerceEvent;
@class MPConsentState;

@protocol MPBackendControllerDelegate;

typedef NS_ENUM(NSUInteger, MPProfileChange) {
    MPProfileChangeSignup = 1,
    MPProfileChangeLogin,
    MPProfileChangeLogout,
    MPProfileChangeUpdate,
    MPProfileChangeDelete
};

typedef NS_ENUM(NSUInteger, MPExecStatus) {
    MPExecStatusSuccess = 0,
    MPExecStatusFail,
    MPExecStatusMissingParam,
    MPExecStatusDisabledRemotely,
    MPExecStatusEnabledRemotely,
    MPExecStatusOptOut,
    MPExecStatusDataBeingFetched,
    MPExecStatusInvalidDataType,
    MPExecStatusDataBeingUploaded,
    MPExecStatusServerBusy,
    MPExecStatusItemNotFound,
    MPExecStatusDisabledInSettings,
    MPExecStatusNoConnectivity
};

extern const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold;
extern const NSInteger kNilAttributeValue;
extern const NSInteger kEmptyAttributeValue;
extern const NSInteger kExceededAttributeCountLimit;
extern const NSInteger kExceededAttributeValueMaximumLength;
extern const NSInteger kExceededAttributeKeyMaximumLength;
extern const NSInteger kInvalidDataType;
extern const NSTimeInterval kMPMaximumKitWaitTimeSeconds;
extern const NSInteger kInvalidKey;

@interface MPBackendController : NSObject



#if TARGET_OS_IOS == 1
@property (nonatomic, strong, nonnull) MPNotificationController *notificationController;
#endif

@property (nonatomic, weak, nullable) id<MPBackendControllerDelegate> delegate;
@property (nonatomic, strong, nullable) NSMutableSet<MPEvent *> *eventSet;
@property (nonatomic, strong, nullable) MPNetworkCommunication *networkCommunication;
@property (nonatomic, strong, nullable) MPSession *session;
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, unsafe_unretained) NSTimeInterval uploadInterval;

- (nonnull instancetype)initWithDelegate:(nonnull id<MPBackendControllerDelegate>)delegate;
- (void)beginSession;
- (void)endSession;
- (void)beginSessionWithIsManual:(BOOL)isManual date:(nonnull NSDate *)date;
- (void)endSessionWithIsManual:(BOOL)isManual;
- (void)beginTimedEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
+ (BOOL)checkAttribute:(nonnull NSDictionary *)attributesDictionary key:(nonnull NSString *)key value:(nonnull id)value error:(out NSError *__autoreleasing _Nullable * _Nullable)error;
- (nullable MPEvent *)eventWithName:(nonnull NSString *)eventName;
- (nullable NSString *)execStatusDescription:(MPExecStatus)execStatus;
- (MPExecStatus)fetchSegments:(NSTimeInterval)timeout endpointId:(nullable NSString *)endpointId completionHandler:(void (^ _Nonnull)(NSArray * _Nullable segments, NSTimeInterval elapsedTime, NSError * _Nullable error))completionHandler;
- (nullable NSNumber *)incrementSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nullable NSNumber *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (void)leaveBreadcrumb:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logError:(nullable NSString *)message exception:(nullable NSException *)exception topmostContext:(nullable id)topmostContext eventInfo:(nullable NSDictionary *)eventInfo completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus))completionHandler;
- (void)logBaseEvent:(nonnull MPBaseEvent *)event completionHandler:(void (^ _Nonnull)(MPBaseEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(MPCommerceEvent * _Nonnull commerceEvent, MPExecStatus execStatus))completionHandler;
- (void)logNetworkPerformanceMeasurement:(nonnull MPNetworkPerformance *)networkPerformance completionHandler:(void (^ _Nullable)(MPNetworkPerformance * _Nonnull networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)logScreen:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^ _Nonnull)(BOOL optOut, MPExecStatus execStatus))completionHandler;
- (MPExecStatus)setSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key value:(nonnull id)value;
- (void)setUserAttribute:(nonnull NSString *)key value:(nullable id)value timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler;
- (void)removeUserAttribute:(nonnull NSString *)key timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nullable key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nonnull)(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler;
- (void)startWithKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *_Nullable)consentState completionHandler:(dispatch_block_t _Nonnull)completionHandler;
- (void)saveMessage:(nonnull MPMessage *)message updateSession:(BOOL)updateSession;
- (void)skipNextUpload;
- (MPExecStatus)waitForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;
- (nonnull NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(nonnull NSNumber *)userId;
- (nonnull NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(nonnull NSNumber *)userId;

#if TARGET_OS_IOS == 1
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;
- (MPExecStatus)endLocationTracking;
- (void)handleDeviceTokenNotification:(nonnull NSNotification *)notification;
- (void)logUserNotification:(nonnull MParticleUserNotification *)userNotification;
#endif

@end

@protocol MPBackendControllerDelegate <NSObject>
- (void)forwardLogInstall;
- (void)forwardLogUpdate;
- (void)sessionDidBegin:(nonnull MPSession *)session;
- (void)sessionDidEnd:(nonnull MPSession *)session;
@end
