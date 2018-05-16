#import "MPDataModelAbstract.h"

typedef NS_OPTIONS(NSUInteger, MPUserNotificationBehavior) {
    MPUserNotificationBehaviorReceived = 1 << 0,
    MPUserNotificationBehaviorRead = 1 << 2,
};

typedef NS_ENUM(NSInteger, MPUserNotificationMode) {
    MPUserNotificationModeAutoDetect = 0,
    MPUserNotificationModeRemote,
    MPUserNotificationModeLocal
};

typedef NS_ENUM(NSInteger, MPUserNotificationRunningMode) {
    MPUserNotificationRunningModeBackground = 1,
    MPUserNotificationRunningModeForeground
};

extern NSString * _Nonnull const kMPUserNotificationApsKey;
extern NSString * _Nonnull const kMPUserNotificationAlertKey;
extern NSString * _Nonnull const kMPUserNotificationBodyKey;
extern NSString * _Nonnull const kMPUserNotificationContentAvailableKey;
extern NSString * _Nonnull const kMPUserNotificationCategoryKey;

#if TARGET_OS_IOS == 1

NS_EXTENSION_UNAVAILABLE_IOS("")
@interface MParticleUserNotification : MPDataModelAbstract <NSCoding>

@property (nonatomic, strong, nullable) NSString *actionIdentifier;
@property (nonatomic, strong, nullable) NSString *actionTitle;
@property (nonatomic, strong, nullable) NSDictionary *deferredPayload;
@property (nonatomic, strong, nonnull) NSString *type;
@property (nonatomic, strong, readonly, nullable) NSString *categoryIdentifier;
@property (nonatomic, strong, readonly, nullable) NSDate *localAlertDate;
@property (nonatomic, strong, readonly, nullable) NSString *redactedUserNotificationString;
@property (nonatomic, strong, readonly, nonnull) NSDate *receiptTime;
@property (nonatomic, strong, readonly, nonnull) NSString *state;
@property (nonatomic, unsafe_unretained, readwrite) int64_t userNotificationId;
@property (nonatomic, unsafe_unretained, readwrite) MPUserNotificationBehavior behavior;
@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationMode mode;
@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationRunningMode runningMode;
@property (nonatomic, unsafe_unretained, readwrite) BOOL shouldPersist;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)notificationDictionary actionIdentifier:(nullable NSString *)actionIdentifier state:(nonnull NSString *)state behavior:(MPUserNotificationBehavior)behavior mode:(MPUserNotificationMode)mode runningMode:(MPUserNotificationRunningMode)runningMode;

@end

#endif
