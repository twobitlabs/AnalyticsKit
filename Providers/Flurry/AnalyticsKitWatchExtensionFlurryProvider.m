//
//  AnalyticsKitWatchExtensionFlurryProvider.m
//  TeamStream
//
//  Created by Jeremy Medford on 5/11/15.
//  Copyright (c) 2015 Bleacher Report. All rights reserved.
//

#import "Flurry.h"
#import "FlurryWatch.h"
#import "AnalyticsKitWatchExtensionFlurryProvider.h"

@implementation AnalyticsKitWatchExtensionFlurryProvider

-(id<AnalyticsKitProvider>)init {
    self = [super init];
    if (self) {}
    return self;
}

// Lifecycle
-(void)applicationWillEnterForeground{}
-(void)applicationDidEnterBackground{}
-(void)applicationWillTerminate{}
-(void)uncaughtException:(NSException *)exception{}


//Logging events
-(void)logScreen:(NSString *)screenName{}

-(void)logEvent:(NSString *)event {
    [FlurryWatch logWatchEvent:(NSString *) event];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [FlurryWatch logWatchEvent:event withParameters:[NSDictionary dictionaryWithObject:value forKey:key]];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [FlurryWatch logWatchEvent:(NSString *) event withParameters:(NSDictionary *) dict];
}

-(void)logEvent:(NSString *)event timed:(BOOL)timed{}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{}

@end
