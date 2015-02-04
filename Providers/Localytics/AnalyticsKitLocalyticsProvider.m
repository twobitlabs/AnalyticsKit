//
//  AnalyticsKitLocalyticsProvider.m
//  AnalyticsKit
//
//  Created by Todd Huss on 10/17/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitLocalyticsProvider.h"
#import "LocalyticsSession.h"

@implementation AnalyticsKitLocalyticsProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)localyticsKey {
    self = [super init];
    if (self) {
        [[LocalyticsSession sharedLocalyticsSession] startSession:localyticsKey];
    }
    return self;
}

-(void)applicationWillEnterForeground {
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

-(void)applicationDidEnterBackground {
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

-(void)applicationWillTerminate { 
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

-(void)uncaughtException:(NSException *)exception {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Uncaught Exceptions" attributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
          [exception name], @"ename",
          [exception reason], @"reason",
          [exception userInfo], @"userInfo",
      nil]];

}

-(void)logScreen:(NSString *)screenName {    
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:screenName];
}

-(void)logEvent:(NSString *)event {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:event];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:event attributes:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:event attributes:[NSDictionary dictionaryWithObject:value forKey:key]];
}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed {
    [self logEvent:eventName];
}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed {
    [self logEvent:eventName withProperties:dict];
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict {}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Exceptions" attributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        message, @"message",        
        [exception name], @"ename",
        [exception reason], @"reason",
        [exception userInfo], @"userInfo",
      nil]];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Errors" attributes:
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
