#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPNotificationController : NSObject

#if TARGET_OS_IOS == 1
+ (nullable NSData *)deviceToken;
+ (void)setDeviceToken:(nullable NSData *)devToken;
#endif

@end
