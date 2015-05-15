//
//  AnalyticsKitCrashlyticsProvider.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 10/23/13.
//  Copyright (c) 2013 Two Bit Labs. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "AnalyticsKitCrashlyticsProvider.h"
#import "AnalyticsKitEvent.h"
#import "AnalyticsKitTimedEventHelper.h"

@implementation AnalyticsKitCrashlyticsProvider

-(void)logScreen:(NSString *)screenName {
    CLSLog(@"screen: %@", screenName);
}

-(void)logEvent:(NSString *)event {
    CLSLog(@"event: %@", event);
    [self logEvent:event withProperties:nil];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    CLSLog(@"event: %@, key: %@, value: %@", event, key, value);
    [self logEvent:event withProperties:@{key: value}];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    CLSLog(@"event: %@, properties: %@", event, dict);
    [[Crashlytics sharedInstance] logEvent:event attributes:dict];
}

-(void)logEvent:(NSString *)event timed:(BOOL)timed {
    if (timed) {
        CLSLog(@"timed event started: %@", event);
        [AnalyticsKitTimedEventHelper startTimedEventWithName:event forProvider:self];
    } else {
        [self logEvent:event];
    }
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed {
    if (timed) {
        CLSLog(@"timed event started: %@ properties: %@", event, dict);
        [AnalyticsKitTimedEventHelper startTimedEventWithName:event properties:dict forProvider:self];
    } else {
        [self logEvent:event withProperties:dict];
    }
}

-(void)endTimedEvent:(NSString *)name withProperties:(NSDictionary *)dict {
    AnalyticsKitEvent *event = [AnalyticsKitTimedEventHelper endTimedEventNamed:name forProvider:self];
    if (event != nil) {
        [self logEvent:event.name withProperties:event.properties];
    }
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    CLSLog(@"error: %@ message: %@ exception: %@", name, message, exception);
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    CLSLog(@"error: %@ message: %@ exception: %@", name, message, error);
}

-(void)uncaughtException:(NSException *)exception{
    CLSLog(@"uncaught exception: %@", exception);
}

-(void)applicationDidEnterBackground {
    CLSLog(@"applicationDidEnterBackground");
}

-(void)applicationWillEnterForeground {
    CLSLog(@"applicationWillEnterForeground");
}

-(void)applicationWillTerminate {
    CLSLog(@"applicationWillTerminate");
}

@end
