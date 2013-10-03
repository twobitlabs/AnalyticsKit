//
//  AnalyticsKitParseProvider.h
//
//  Created by Bradley David Bergeron on 10/02/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import <Parse-iOS-SDK/Parse.h>
#import "AnalyticsKitParseProvider.h"

@implementation AnalyticsKitParseProvider

-(id<AnalyticsKitProvider>)initWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    self = [super init];
    if (self) {
        [Parse setApplicationId:applicationId clientKey:clientKey];
    }
    return self;
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {
    [PFAnalytics trackEvent:@"Uncaught Exception"
                 dimensions:[NSDictionary dictionaryWithObject:[[UIDevice currentDevice]systemVersion] forKey:@"version"]];
}

-(void)logScreen:(NSString *)screenName {
    [PFAnalytics trackEvent:[@"Screen - " stringByAppendingString:screenName]];
}

-(void)logEvent:(NSString *)event {
    [PFAnalytics trackEvent:event];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [PFAnalytics trackEvent:event dimensions:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [self logEvent:event withProperties:[NSDictionary dictionaryWithObject:value forKey:key]];
}

- (void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [PFAnalytics trackEvent:name dimensions:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", exception, @"exception", nil]];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [PFAnalytics trackEvent:name dimensions:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", error, @"error", nil]];
}

@end
