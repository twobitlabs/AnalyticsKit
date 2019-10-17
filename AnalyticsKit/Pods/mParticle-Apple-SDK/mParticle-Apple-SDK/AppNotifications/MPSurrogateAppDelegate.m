#import "MPSurrogateAppDelegate.h"
#import "MPAppDelegateProxy.h"
#import "MPNotificationController.h"
#import "MPAppNotificationHandler.h"
#import "MPStateMachine.h"
#import "MParticle.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;
@property (nonatomic, strong, readonly) MPAppNotificationHandler *appNotificationHandler;

@end

@interface MPSurrogateAppDelegate () {
    SEL applicationOpenURLOptionsSelector;
    NSArray *selectorArray;
}
@end

@implementation MPSurrogateAppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        applicationOpenURLOptionsSelector = @selector(application:openURL:options:);
        selectorArray = @[
                          [NSValue valueWithPointer:applicationOpenURLOptionsSelector]
#if TARGET_OS_IOS == 1
                          ,
                          [NSValue valueWithPointer:@selector(application:openURL:sourceApplication:annotation:)],
                          [NSValue valueWithPointer:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)],
                          [NSValue valueWithPointer:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)],
                          [NSValue valueWithPointer:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)],
                          [NSValue valueWithPointer:@selector(application:continueUserActivity:restorationHandler:)],
                          [NSValue valueWithPointer:@selector(application:didUpdateUserActivity:)],
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                          [NSValue valueWithPointer:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)],
                          [NSValue valueWithPointer:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]
#pragma clang diagnostic pop
#endif
                          ];
    }
    return self;
}

- (BOOL)implementsSelector:(SEL)aSelector {
    if (![selectorArray containsObject:[NSValue valueWithPointer:aSelector]]) {
        return NO;
    }
    
    if (aSelector == applicationOpenURLOptionsSelector && [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        return NO;
    }
    
    return YES;
}

#pragma mark UIApplicationDelegate
#if TARGET_OS_IOS == 1

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    [appNotificationHandler didReceiveRemoteNotification:userInfo];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    } else {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[MParticle sharedInstance].appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[MParticle sharedInstance].appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler {
    [[MParticle sharedInstance].appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)(void))completionHandler {
    [[MParticle sharedInstance].appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        if (@available(iOS 9.0, *)) {
            [originalAppDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
        }
    } else if ([originalAppDelegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)]) {
        [originalAppDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    } else {
        completionHandler();
    }
}
#pragma clang diagnostic pop


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[MParticle sharedInstance].appNotificationHandler openURL:url sourceApplication:sourceApplication annotation:annotation];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [originalAppDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
#pragma clang diagnostic pop
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[MParticle sharedInstance].appNotificationHandler continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        return [originalAppDelegate application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    
    return NO;
}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {
    [[MParticle sharedInstance].appNotificationHandler didUpdateUserActivity:userActivity];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application didUpdateUserActivity:userActivity];
    }
}

#endif

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    [[MParticle sharedInstance].appNotificationHandler openURL:url options:options];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        if (@available(iOS 9.0, *)) {
            return [originalAppDelegate application:app openURL:url options:options];
        }
    }
#if TARGET_OS_IOS == 1
    else if ([originalAppDelegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
        if (@available(iOS 9.0, *)) {
            NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
            id annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
            if (options && annotation) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                return [originalAppDelegate application:app openURL:url sourceApplication:sourceApplication annotation:annotation];
#pragma clang diagnostic pop
            }
        } else {
            // Fallback on earlier versions
        }
    }
#endif
    
    return NO;
}

@end
