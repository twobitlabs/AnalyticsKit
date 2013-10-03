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
    [[Mixpanel sharedInstance] track:event];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [[Mixpanel sharedInstance] track:event properties:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [[Mixpanel sharedInstance]  track:event properties:[NSDictionary dictionaryWithObject:value forKey:key]];
}

- (void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    [self logEvent:eventName];
}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    [self logEvent:eventName withProperties:dict];
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

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
      [NSString stringWithFormat:@"%d", [error code]], @"code",
      [error domain], @"domain",
      [[error userInfo] description], @"userInfo",
      nil]];
}

@end
