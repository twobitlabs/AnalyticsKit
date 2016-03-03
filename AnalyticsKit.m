//
//  AnalyticsKit.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"
#import <os/trace.h>

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
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging screen with name");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName];
    }
    
}

+(void)logEvent:(NSString *)event {
    AKINFO(@"%@", event);
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging event");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event];
    }
}

+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    AKINFO(@"%@ withProperties: %@", event, dict);
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging event with properties");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperties:dict];
    }    
}

+(void)logEvent:(NSString *)event withProperty:(NSString *)property andValue:(NSString *)value {
    if (property == nil) property = @"nil";
    if (value == nil) value = @"nil";
    AKINFO(@"%@ withProperty: %@ andValue: %@", event, property, value);
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging event with property and value");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperty:property andValue:value];
    }
}

+(void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    AKINFO(@"%@ timed: %@", eventName, timed ? @"YES" : @"NO");
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging timed event");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName timed:timed];
    }
}

+(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    AKINFO(@"%@ withProperties: %@ timed: %@", eventName, dict, timed ? @"YES" : @"NO");
    // os_trace_error per #20
    os_trace("#AnalyticsKit logging timed event with properties");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName withProperties:dict timed:timed];
    }
}

+(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{
    AKINFO(@"%@ withProperties: %@ ended", eventName, dict);
    // os_trace_error per #20
    os_trace("#AnalyticsKit ending timed event with properties");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger endTimedEvent:eventName withProperties:dict];
    }
}

+(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    AKERROR(@"%@: %@", name, message);

    // os_trace_error per #20
    // os_trace_fault may be a better fit.
    os_trace_error("#AnalyticsKit #Critical exception logged");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message exception:exception];
    }    
}

+(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    AKERROR(@"%@: %@", name, message);
    
    // os_trace_error per #20
    os_trace_error("#AnalyticsKit #Error logged: %ld", (unsigned long)[error code]);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message error:error];
    }
}


@end
