//
//  AnalyticsKit.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"

@implementation AnalyticsKit

static NSArray *_loggers = nil;

+(void)initialize {
    _loggers = [NSArray array];
}

+(void)initializeLoggers:(NSArray *)loggers {
    _loggers = loggers;
}

+(void)applicationWillEnterForeground {
    INFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationWillEnterForeground];
    }    
}

+(void)applicationDidEnterBackground {
    INFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationDidEnterBackground];
    }        
}

+(void)applicationWillTerminate {
    INFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger applicationWillTerminate];
    }    
}

+(void)uncaughtException:(NSException *)exception {
    INFO(@"");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger uncaughtException:exception];
    }    
    
}

+(void)logScreen:(NSString *)screenName {
    INFO(@"%@", screenName);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logScreen:screenName];
    }
    
}

+(void)logEvent:(NSString *)event {
    INFO(@"%@", event);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event];
    }
}

+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    INFO(@"%@ withProperties: %@", event, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperties:dict];
    }    
}

+(void)logEvent:(NSString *)event withProperty:(NSString *)property andValue:(NSString *)value {
    INFO(@"%@ withProperty: %@ andValue: %@", event, property, value);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:event withProperty:property andValue:value];
    }
}

+(void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    INFO(@"%@ timed: %@", eventName, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName timed:timed];
    }
}

+(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    INFO(@"%@ withProperties: %@ timed: %@", eventName, dict, timed ? @"YES" : @"NO");
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logEvent:eventName withProperties:dict timed:timed];
    }
}

+(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{
    INFO(@"%@ withProperties: %@ ended", eventName, dict);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger endTimedEvent:eventName withProperties:dict];
    }
}

+(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    ERROR(@"%@: %@", name, message);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message exception:exception];
    }    
}

+(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    ERROR(@"%@: %@", name, message);
    for (id<AnalyticsKitProvider> logger in _loggers) {
        [logger logError:name message:message error:error];
    }
}


@end
