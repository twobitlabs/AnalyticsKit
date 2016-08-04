//
//  AnalyticsKitTimedEventHelper.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 3/21/14.
//  Copyright (c) 2014 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitTimedEventHelper.h"

@implementation AnalyticsKitTimedEventHelper

static NSMutableDictionary *events;

+(void)initialize {
    events = [NSMutableDictionary dictionary];
}

+(void)startTimedEventWithName:(NSString *)name forProvider:(id<AnalyticsKitProvider>)provider {
    [self startTimedEventWithName:name properties:nil forProvider:provider];
}

+(void)startTimedEventWithName:(NSString *)name properties:(NSDictionary *)properties forProvider:(id<AnalyticsKitProvider, NSObject>)provider {
    if (name != nil) {
        NSString *providerClass = NSStringFromClass([provider class]);
        NSMutableDictionary *providerDict = events[providerClass];
        if (providerDict == nil) {
            providerDict = [NSMutableDictionary dictionary];
            events[providerClass] = providerDict;
        }
        
        AnalyticsKitEvent *event = providerDict[name];
        if (event == nil) {
            event = [[AnalyticsKitEvent alloc] initWithEvent:name];
            providerDict[name] = event;
        }
        if (properties != nil) {
            event.properties = properties;
        }
        event.startTime = [NSDate date];
    }
}

+(AnalyticsKitEvent *)endTimedEventNamed:(NSString *)name forProvider:(id<AnalyticsKitProvider, NSObject>)provider {
    AnalyticsKitEvent *event = nil;
    if (name != nil) {
        NSString *providerClass = NSStringFromClass([provider class]);
        NSMutableDictionary *providerDict = events[providerClass];
        if (providerDict != nil) {
            event = providerDict[name];
            [providerDict removeObjectForKey:name];
        }
        if (event != nil) {
            NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:event.startTime];
            [event setProperty:@(elapsedTime) forKey:@"AnalyticsKitEventTimeSeconds"];
        }
    }
    return event;
}

@end
