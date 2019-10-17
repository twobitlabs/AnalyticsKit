#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    #import <UserNotifications/UserNotifications.h>
#endif

@class MPAppDelegateProxy;

@interface MPSurrogateAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, weak) MPAppDelegateProxy *appDelegateProxy;

- (BOOL)implementsSelector:(SEL)aSelector;

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options;

#if TARGET_OS_IOS == 1
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler;
- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity;
#endif

@end

