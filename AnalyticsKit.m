//
//  AnalyticsKit.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"

@implementation AnalyticsKit

NSString* const AnalyticsKitEventTimeSeconds = @"AnalyticsKitEventTimeSeconds";

static NSArray *_loggers = nil;

+(void)initialize {
    _loggers = [[NSArray alloc] init];
}

+(void)initializeLoggers:(NSArray *)loggers {
    #if !__has_feature(objc_arc)
    [loggers retain];
    [_loggers release];
    #endif
    _loggers = loggers;
}

+(NSArray *)loggers {
    return _loggers;
}

+(void)applicationWillEnterForeground {
    AKINFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationWillEnterForeground];
    }    
}

+(void)applicationDidEnterBackground {
    AKINFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationDidEnterBackground];
    }        
}

+(void)applicationWillTerminate {
    AKINFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationWillTerminate];
    }    
}

+(void)uncaughtException:(NSException *)exception {
    AKINFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger uncaughtException:exception];
    }    
    
}

+(void)logScreen:(NSString *)screenName {
    AKINFO(@"%@", screenName);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName];
    }
}

+(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@", screenName, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName withProperties:dict];
    }
}

+(void)logScreen:(NSString *)screenName timed:(BOOL)timed
{
    AKINFO(@"%@ timed: %@", screenName, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName timed:timed];
    }
}

+(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict timed:(BOOL)timed
{
    AKINFO(@"%@ withProperties: %@ timed: %@", screenName, dict, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName withProperties:dict timed:timed];
    }
}

+(void)endTimedScreen:(NSString *)screenName withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", screenName, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger endTimedScreen:screenName withProperties:dict];
    }
}

+(void)logEvent:(NSString *)event {
    AKINFO(@"%@", event);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event];
    }
}

+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    AKINFO(@"%@ withProperties: %@", event, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperties:dict];
    }    
}

+(void)logEvent:(NSString *)event withProperty:(NSString *)property andValue:(NSString *)value {
    if (property == nil) property = @"nil";
    if (value == nil) value = @"nil";
    AKINFO(@"%@ withProperty: %@ andValue: %@", event, property, value);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperty:property andValue:value];
    }
}

+(void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    AKINFO(@"%@ timed: %@", eventName, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName timed:timed];
    }
}

+(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    AKINFO(@"%@ withProperties: %@ timed: %@", eventName, dict, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName withProperties:dict timed:timed];
    }
}

+(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{
    AKINFO(@"%@ withProperties: %@ ended", eventName, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger endTimedEvent:eventName withProperties:dict];
    }
}

+(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    AKERROR(@"%@: %@", name, message);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message exception:exception];
    }    
}

+(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    AKERROR(@"%@: %@", name, message);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message error:error];
    }
}

+(void) logSignUpWithMethod:(NSString*) method withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"SignUp", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logSignUpWithMethod:withProperties:)])
        {
            [logger logSignUpWithMethod:method withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"method"] = method;
            
            [logger logEvent:@"SignUp" withProperties:properties];
        }
    }
}

+(void) logLogInWithMethod:(NSString*) method withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"LogIn", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logLogInWithMethod:withProperties:)])
        {
            [logger logLogInWithMethod:method withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"method"] = method;
            
            [logger logEvent:@"LogIn" withProperties:properties];
        }
    }
}

+(void) logInviteWithMethod:(NSString*) method withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"Invite", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logInviteWithMethod:withProperties:)])
        {
            [logger logInviteWithMethod:method withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"method"] = method;
            
            [logger logEvent:@"Invite" withProperties:properties];
        }
    }
}

+(void) logStartCheckoutItem:(NSString*) item withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"StartCheckout", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logLogInWithMethod:withProperties:)])
        {
            [logger logLogInWithMethod:item withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"item"] = item;
            
            [logger logEvent:@"StartCheckout" withProperties:properties];
        }
    }
}

+(void) logPurchaseItem:(NSString*) item withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"Purchase", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logPurchaseItem:withProperties:)])
        {
            [logger logPurchaseItem:item withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"item"] = item;
            
            [logger logEvent:@"Purchase" withProperties:properties];
        }
    }
}

+(void) logShareWithMethod:(NSString*) method withType:(NSString*) type withProperties:(NSDictionary *)dict
{
    AKINFO(@"%@ withProperties: %@ ended", @"Share", dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        if ([logger respondsToSelector:@selector(logShareWithMethod:withType:withProperties:)])
        {
            [logger logShareWithMethod:method withType:type withProperties:dict];
        }
        else
        {
            NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:dict];
            properties[@"method"] = method;
            properties[@"type"] = type;
            
            [logger logEvent:@"Share" withProperties:properties];
        }
    }
}


@end
