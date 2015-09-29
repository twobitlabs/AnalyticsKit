//
//  AnalyticsKitLocalyticsProvider.m
//  AnalyticsKit
//
//  Created by Todd Huss on 10/17/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitLocalyticsProvider.h"
#import "Localytics.h"

@implementation AnalyticsKitLocalyticsProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)localyticsKey {
    self = [super init];
    if (self) {
        [Localytics integrate:localyticsKey];
        [Localytics openSession];
    }
    return self;
}

-(void)applicationWillEnterForeground {
    [Localytics openSession];
    [Localytics upload];
}

-(void)applicationDidEnterBackground {
    [Localytics closeSession];
    [Localytics upload];
}

-(void)applicationWillTerminate { 
    [Localytics closeSession];
    [Localytics upload];
}

-(void)uncaughtException:(NSException *)exception {
    [Localytics tagEvent:@"Uncaught Exceptions" attributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
          [exception name], @"ename",
          [exception reason], @"reason",
          [exception userInfo], @"userInfo",
      nil]];

}

-(void)logScreen:(NSString *)screenName {    
    [Localytics tagScreen:screenName];
}

-(void)logEvent:(NSString *)event {
    [Localytics tagEvent:event];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [Localytics tagEvent:event attributes:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [Localytics tagEvent:event attributes:[NSDictionary dictionaryWithObject:value forKey:key]];
}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed {
    [self logEvent:eventName];
}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed {
    [self logEvent:eventName withProperties:dict];
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict {}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [Localytics tagEvent:@"Exceptions" attributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        message, @"message",        
        [exception name], @"ename",
        [exception reason], @"reason",
        [exception userInfo], @"userInfo",
      nil]];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [Localytics tagEvent:@"Errors" attributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
          name, @"name",
          message, @"message",        
          [error localizedDescription], @"description",
          [NSString stringWithFormat:@"%ld", (long)[error code]], @"code",
          [error domain], @"domain",
          [[error userInfo] description], @"userInfo",
      nil]];
}

@end
