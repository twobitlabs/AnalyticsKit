#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPResponseConfig : NSObject <NSSecureCoding>

@property (nonatomic, copy, nonnull, readonly) NSDictionary *configuration;

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration;
- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration dataReceivedFromServer:(BOOL)dataReceivedFromServer;

+ (nullable MPResponseConfig *)restore;

#if TARGET_OS_IOS == 1
- (void)configureLocationTracking:(nonnull NSDictionary *)locationDictionary;
- (void)configurePushNotifications:(nonnull NSDictionary *)pushNotificationDictionary;
#endif

@end
