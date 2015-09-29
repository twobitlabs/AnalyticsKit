//
//  AnalyticsKitUnitTestProvider.m
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitUnitTestProvider.h"

@implementation AnalyticsKitUnitTestProvider

+ (AnalyticsKitUnitTestProvider *)setUp {
    AnalyticsKitUnitTestProvider *provider = [[AnalyticsKitUnitTestProvider alloc] init];
    provider.events = [NSMutableArray arrayWithCapacity:20];
    [AnalyticsKit initializeLoggers:@[provider]];
    return provider;
}

+ (AnalyticsKitUnitTestProvider *)unitTestProvider {
    AnalyticsKitUnitTestProvider *unitProvider = nil;
    NSArray *loggers = [AnalyticsKit loggers];
    for (AnalyticsKitUnitTestProvider *provider in loggers) {
        if ([provider isKindOfClass:[AnalyticsKitUnitTestProvider class]]) unitProvider = provider;
    }
    return unitProvider;
}

+ (void)clearEvents {
    // Remove the events stored in the unit test provider
    [[self unitTestProvider] clearEvents];
}

+ (void)tearDown {
    [self clearEvents];
    // Wipe out any loggers
    [AnalyticsKit initializeLoggers:[[NSArray alloc] init]];
}

- (void)clearEvents {
    [self setEvents:[NSMutableArray arrayWithCapacity:20]];
}

- (BOOL)hasEventLoggedWithName:(NSString *)eventName {
    return [self firstEventLoggedWithName:eventName] != nil;
}

- (AnalyticsKitEvent *)firstEventLoggedWithName:(NSString *)eventName {
    AnalyticsKitEvent *event = nil;
    NSArray *matchingEvents = [self eventsLoggedWithName:eventName];
    if ([matchingEvents count] > 0) event = matchingEvents[0];
    return event;
}

- (NSArray *)eventsLoggedWithName:(NSString *)eventName {
    NSMutableArray *matchingEvents = [NSMutableArray arrayWithCapacity:5];
    for (AnalyticsKitEvent *event in self.events) {
        if ([eventName isEqualToString:event.name]) [matchingEvents addObject:event];
    }
    return matchingEvents;
}

#pragma mark -
#pragma mark Lifecycle

-(void)applicationWillEnterForeground{}

-(void)applicationDidEnterBackground{}

-(void)applicationWillTerminate{}

-(void)uncaughtException:(NSException *)exception{}

#pragma mark -
#pragma mark Event Logging

-(void)logScreen:(NSString *)screenName{
    NSString *event = [@"Screen - " stringByAppendingString:screenName];
    [self logEvent:event withProperties:nil];
}

-(void)logEvent:(NSString *)event {
    [self logEvent:event withProperties:nil];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [self logEvent:event withProperties:@{key:value}];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [self.events addObject:[[AnalyticsKitEvent alloc] initEvent:event withProperties:dict]];
}

-(void)logEvent:(NSString *)event timed:(BOOL)timed{
    [self logEvent:event withProperties:nil];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    [self logEvent:event withProperties:dict];
}

-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{}

@end
