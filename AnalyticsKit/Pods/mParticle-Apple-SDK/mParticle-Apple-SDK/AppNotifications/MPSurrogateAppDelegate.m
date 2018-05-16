#import "MPSurrogateAppDelegate.h"
#import "MPAppDelegateProxy.h"
#import "MPNotificationController.h"
#import "MPAppNotificationHandler.h"

@implementation MPSurrogateAppDelegate

#pragma mark UIApplicationDelegate
#if TARGET_OS_IOS == 1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSDictionary *userInfo;
#if !defined(MPARTICLE_APP_EXTENSIONS)
    userInfo = [MPNotificationController dictionaryFromLocalNotification:notification];
#endif
    if (userInfo) {
        [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:nil userNotificationMode:MPUserNotificationModeLocal];
    }
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveLocalNotification:notification];
    }
}
#pragma clang diagnostic pop

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:nil userNotificationMode:MPUserNotificationModeRemote];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveRemoteNotification:userInfo];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    [appNotificationHandler receivedUserNotification:userInfo actionIdentifier:nil userNotificationMode:MPUserNotificationModeAutoDetect];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    } else if ([_appDelegateProxy.originalAppDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)] && appNotificationHandler.runningMode == MPUserNotificationRunningModeForeground) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveRemoteNotification:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);
    } else {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[MPAppNotificationHandler sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[MPAppNotificationHandler sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application didRegisterUserNotificationSettings:notificationSettings];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    NSDictionary *userInfo;
#if !defined(MPARTICLE_APP_EXTENSIONS)
    userInfo = [MPNotificationController dictionaryFromLocalNotification:notification];
#endif
    if (userInfo) {
        [[MPAppNotificationHandler sharedInstance] receivedUserNotification:userInfo actionIdentifier:identifier userNotificationMode:MPUserNotificationModeLocal];
    }
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler {
    [[MPAppNotificationHandler sharedInstance] handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)())completionHandler {
    [[MPAppNotificationHandler sharedInstance] handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo];
    
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
    [[MPAppNotificationHandler sharedInstance] openURL:url sourceApplication:sourceApplication annotation:annotation];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [originalAppDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
#pragma clang diagnostic pop
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler {
    [[MPAppNotificationHandler sharedInstance] continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        return [originalAppDelegate application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    
    return NO;
}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {
    [[MPAppNotificationHandler sharedInstance] didUpdateUserActivity:userActivity];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application didUpdateUserActivity:userActivity];
    }
}
#endif

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    [[MPAppNotificationHandler sharedInstance] openURL:url options:options];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        if (@available(iOS 9.0, *)) {
            return [originalAppDelegate application:app openURL:url options:options];
        }
    }
#if TARGET_OS_IOS == 1
    else if ([originalAppDelegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
        if (@available(iOS 9.0, *)) {
            NSString *sourceApplication = &UIApplicationOpenURLOptionsSourceApplicationKey != NULL ? options[UIApplicationOpenURLOptionsSourceApplicationKey] : options[@"UIApplicationOpenURLOptionsSourceApplicationKey"];
            id annotation = &UIApplicationOpenURLOptionsAnnotationKey != NULL ? options[UIApplicationOpenURLOptionsAnnotationKey] : options[@"UIApplicationOpenURLOptionsAnnotationKey"];

            return [originalAppDelegate application:app openURL:url sourceApplication:sourceApplication annotation:annotation];
        } else {
            // Fallback on earlier versions
        }
    }
#endif
    
    return NO;
}

@end
