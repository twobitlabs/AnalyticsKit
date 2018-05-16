#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MParticleUserNotification.h"

@protocol MPNotificationControllerDelegate;
NS_EXTENSION_UNAVAILABLE_IOS("")
@interface MPNotificationController : NSObject

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, readonly, nullable) NSString *initialRedactedUserNotificationString;
@property (nonatomic, weak, nullable) id<MPNotificationControllerDelegate> delegate;

+ (nullable NSData *)deviceToken;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (nullable NSDictionary *)dictionaryFromLocalNotification:(nonnull UILocalNotification *)notification;
#pragma clang diagnostic pop
+ (void)setDeviceToken:(nullable NSData *)devToken;
+ (int64_t)launchNotificationHash;
- (nonnull instancetype)initWithDelegate:(nonnull id<MPNotificationControllerDelegate>)delegate;
- (nonnull MParticleUserNotification *)newUserNotificationWithDictionary:(nonnull NSDictionary *)notificationDictionary actionIdentifier:(nullable NSString *)actionIdentifier state:(nullable NSString *)state;
#endif

@end

@protocol MPNotificationControllerDelegate <NSObject>
#if TARGET_OS_IOS == 1
- (void)receivedUserNotification:(nonnull MParticleUserNotification *)userNotification NS_EXTENSION_UNAVAILABLE_IOS("");
#endif
@end
