#ifndef mParticle_Apple_SDK_MPKitProtocol_h
#define mParticle_Apple_SDK_MPKitProtocol_h

#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@class MPCommerceEvent;
@class MPBaseEvent;
@class MPEvent;
@class MPKitExecStatus;
@class MPUserSegments;
@class MPKitAPI;
@class MPConsentState;
@class FilteredMParticleUser;
@class FilteredMPIdentityApiRequest;

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    @class UNUserNotificationCenter;
    @class UNNotification;
    @class UNNotificationResponse;
#endif


@protocol MPKitProtocol <NSObject>
#pragma mark - Required methods
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration;

+ (nonnull NSNumber *)kitCode;

#pragma mark - Optional methods
@optional

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, strong, nullable, readonly) id providerKitInstance;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

#pragma mark Kit lifecycle
- (void)start;
- (void)deinit;

#pragma mark Application
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler;
- (nonnull MPKitExecStatus *)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity;
- (nonnull MPKitExecStatus *)didBecomeActive;
- (nonnull MPKitExecStatus *)failedToRegisterForUserNotifications:(nullable NSError *)error;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nonnull NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)setDeviceToken:(nonnull NSData *)deviceToken;

#if TARGET_OS_IOS == 1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (nonnull MPKitExecStatus *)didRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings;
#pragma clang diagnostic pop
#endif

#pragma mark User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification API_AVAILABLE(ios(10.0));
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0));
#endif

#pragma mark Location tracking
#if TARGET_OS_IOS == 1
- (nonnull MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;
- (nonnull MPKitExecStatus *)endLocationTracking;
- (nonnull MPKitExecStatus *)setLocation:(nonnull CLLocation *)location;
#endif

#pragma mark Session management
- (nonnull MPKitExecStatus *)beginSession;
- (nonnull MPKitExecStatus *)endSession;

#pragma mark User attributes and identities
- (nonnull MPKitExecStatus *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nonnull id)value;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nonnull NSArray *)values;
- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;
- (nonnull MPKitExecStatus *)setUserTag:(nonnull NSString *)tag;

- (nonnull MPKitExecStatus *)onIncrementUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onRemoveUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onSetUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onSetUserTag:(nonnull FilteredMParticleUser *)user;

- (nonnull MPKitExecStatus *)onIdentifyComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onLoginComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onLogoutComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onModifyComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;

#pragma mark Consent state
- (nonnull MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state;

#pragma mark e-Commerce
- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent __attribute__ ((deprecated));
- (nonnull MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(nonnull MPEvent *)event;

#pragma mark Events
- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event;
- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event __attribute__ ((deprecated));
- (nonnull MPKitExecStatus *)logInstall;
- (nonnull MPKitExecStatus *)logout;
- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logUpdate;

#pragma mark Timed events
- (nonnull MPKitExecStatus *)beginTimedEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)endTimedEvent:(nonnull MPEvent *)event;

#pragma mark Errors and exceptions
- (nonnull MPKitExecStatus *)leaveBreadcrumb:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logError:(nullable NSString *)message eventInfo:(nullable NSDictionary *)eventInfo;
- (nonnull MPKitExecStatus *)logException:(nonnull NSException *)exception;

#pragma mark Assorted
- (nonnull MPKitExecStatus *)setKitAttribute:(nonnull NSString *)key value:(nullable id)value;
- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut;
- (nullable NSString *)surveyURLWithUserAttributes:(nonnull NSDictionary *)userAttributes;
- (BOOL) shouldDelayMParticleUpload;
@end

#endif
