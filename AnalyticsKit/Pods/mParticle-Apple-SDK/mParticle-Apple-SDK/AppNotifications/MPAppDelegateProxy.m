#import "MPAppDelegateProxy.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPSurrogateAppDelegate.h"
#import "MPILogger.h"

@interface MPAppDelegateProxy() {
    SEL applicationOpenURLOptionsSelector;
#if TARGET_OS_IOS == 1
    SEL applicationOpenURLSelector;
    SEL didFailToRegisterForRemoteNotificationSelector;
    SEL didReceiveLocalNotificationSelector;
    SEL didReceiveRemoteNotificationSelector;
    SEL didRegisterForRemoteNotificationSelector;
    SEL handleActionWithIdentifierForLocalNotificationSelector;
    SEL handleActionWithIdentifierForRemoteNotificationSelector;
    SEL continueUserActivityRestorationHandlerSelector;
    SEL didUpdateUserActivitySelector;
#endif
}

@end

@implementation MPAppDelegateProxy

- (instancetype)initWithOriginalAppDelegate:(id)originalAppDelegate {
    _originalAppDelegate = originalAppDelegate;

    applicationOpenURLOptionsSelector = @selector(application:openURL:options:);
#if TARGET_OS_IOS == 1
    applicationOpenURLSelector = @selector(application:openURL:sourceApplication:annotation:);
    didFailToRegisterForRemoteNotificationSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    didReceiveLocalNotificationSelector = @selector(application:didReceiveLocalNotification:);
    didReceiveRemoteNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    didRegisterForRemoteNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    handleActionWithIdentifierForLocalNotificationSelector = @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:);
    handleActionWithIdentifierForRemoteNotificationSelector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    continueUserActivityRestorationHandlerSelector = @selector(application:continueUserActivity:restorationHandler:);
    didUpdateUserActivitySelector = @selector(application:didUpdateUserActivity:);
#endif
    
    return self;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    BOOL conformsToProtocol = [self.surrogateAppDelegate conformsToProtocol:aProtocol];
    
    if (!conformsToProtocol) {
        conformsToProtocol = [_originalAppDelegate conformsToProtocol:aProtocol];
    }
    
    return conformsToProtocol;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:selector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:selector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(selector));
    }
    
    [anInvocation invokeWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:aSelector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:aSelector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(aSelector));
    }
    
    return target;
}

- (BOOL)isKindOfClass:(Class)aClass {
    BOOL isKindOfClass = [self.surrogateAppDelegate isKindOfClass:aClass];
    
    if (!isKindOfClass) {
        isKindOfClass = [_originalAppDelegate isKindOfClass:aClass];
    }
    
    return isKindOfClass;
}

- (BOOL)isMemberOfClass:(Class)aClass {
    BOOL isMemberOfClass = [self.surrogateAppDelegate isMemberOfClass:aClass];
    
    if (!isMemberOfClass) {
        isMemberOfClass = [_originalAppDelegate isMemberOfClass:aClass];
    }
    
    return isMemberOfClass;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [[_originalAppDelegate class] instanceMethodSignatureForSelector:selector];
    if (!signature) {
        signature = [self.surrogateAppDelegate methodSignatureForSelector:selector];
        
        if (!signature) {
            signature = [_originalAppDelegate methodSignatureForSelector:selector];
        }
    }
    
    return signature;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector;
    if ([_originalAppDelegate respondsToSelector:aSelector]) {
        respondsToSelector = YES;
    } else {
        respondsToSelector = (aSelector == applicationOpenURLOptionsSelector && [[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
#if TARGET_OS_IOS == 1
                             ||
                             (aSelector == applicationOpenURLSelector) ||
                             (aSelector == didFailToRegisterForRemoteNotificationSelector) ||
                             (aSelector == didReceiveLocalNotificationSelector) ||
                             (aSelector == didReceiveRemoteNotificationSelector) ||
                             (aSelector == didRegisterForRemoteNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForLocalNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForRemoteNotificationSelector) ||
                             (aSelector == continueUserActivityRestorationHandlerSelector) ||
                             (aSelector == didUpdateUserActivitySelector);
#else
                             ;
#endif
    }
    
    return respondsToSelector;
}

#pragma mark Public accessors
- (MPSurrogateAppDelegate *)surrogateAppDelegate {
    if (_surrogateAppDelegate) {
        return _surrogateAppDelegate;
    }
    
    _surrogateAppDelegate = [[MPSurrogateAppDelegate alloc] init];
    _surrogateAppDelegate.appDelegateProxy = self;
    
    return _surrogateAppDelegate;
}

@end
