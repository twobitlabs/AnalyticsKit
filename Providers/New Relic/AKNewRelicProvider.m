//
//  AKNewRelicProvider.m
//
//
//  Created by Zac Shenker on 26/03/13.
//  Copyright (c) 2013 Collusion. All rights reserved.
//

#import <NewRelicAgent/NewRelicAgent.h>
#import "AKNewRelicProvider.h"

@implementation AKNewRelicProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        [NewRelicAgent startWithApplicationToken:apiKey];
    }
    return self;
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {}

-(void)logScreen:(NSString *)screenName {}

-(void)logEvent:(NSString *)event {}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {}

- (void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}

@end
