//
//  AnalyticsKitMixpanelProvider.m
//
//
//  Created by Zac Shenker on 5/11/12.
//  Copyright (c) 2012 Collusion. All rights reserved.
//

#import "Mixpanel.h"
#import "AnalyticsKitMixpanelProvider.h"

@implementation AnalyticsKitMixpanelProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        [Mixpanel sharedInstanceWithToken:apiKey];
    }
    return self;
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {
    [[Mixpanel sharedInstance]track:@"Uncaught Exceptions" properties:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [exception name], @"ename",
      [exception reason], @"reason",
      [exception userInfo], @"userInfo",
      nil]];
}

-(void)logScreen:(NSString *)screenName {
    [[Mixpanel sharedInstance] track:[@"Screen - " stringByAppendingString:screenName]];
}

-(void)logEvent:(NSString *)event {
    [self logEvent:event withProperties:nil timed:NO];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [self logEvent:event withProperties:dict timed:NO];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [self logEvent:event withProperties:[NSDictionary dictionaryWithObject:value forKey:key]];
}

- (void)logEvent:(NSString *)eventName timed:(BOOL)timed {
    [self logEvent:eventName withProperties:nil timed:timed];
}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed {
    if (timed) {
        [[Mixpanel sharedInstance] timeEvent:eventName];
    } else {
        [[Mixpanel sharedInstance] track:eventName properties:dict];
    }
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict {
    // Mixpanel documentation: timeEvent followed by a track with the same event name would record the duration
    [[Mixpanel sharedInstance] track:eventName properties:dict];
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [[Mixpanel sharedInstance] track:@"Exceptions" properties:
     [NSDictionary dictionaryWithObjectsAndKeys:
      name, @"name",
      message, @"message",
      [exception name], @"ename",
      [exception reason], @"reason",
      [exception userInfo], @"userInfo",
      nil]];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [[Mixpanel sharedInstance] track:@"Errors" properties:
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
