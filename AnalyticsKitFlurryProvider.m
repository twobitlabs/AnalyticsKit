//
//  AnalyticsKitFlurryProvider.m
//  TeamStream
//
//  Created by Susan Detwiler on 11/10/11.
//  Copyright (c) 2011 Bleacher Report. All rights reserved.
//

#import "FlurryAnalytics.h"
#import "AnalyticsKitFlurryProvider.h"

@implementation AnalyticsKitFlurryProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        [FlurryAnalytics startSession:(NSString *)apiKey];
    }
    return self;
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {
    NSString *message = [NSString stringWithFormat:@"Crash on iOS %@", [[UIDevice currentDevice] systemVersion]];
    [FlurryAnalytics logError:@"Uncaught" message:message exception:exception];
}

-(void)logScreen:(NSString *)screenName {}

-(void)logEvent:(NSString *)value {
    [FlurryAnalytics logEvent:value];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [FlurryAnalytics logEvent:event withParameters:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [FlurryAnalytics logEvent:event withParameters:[NSDictionary dictionaryWithObject:value forKey:key]];
}


- (void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    [FlurryAnalytics logEvent:eventName timed:timed];
}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    [FlurryAnalytics logEvent:eventName withParameters:dict timed:timed];
    
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{
    // non-nil parameters will update the parameters
     [FlurryAnalytics endTimedEvent:eventName withParameters:dict];
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [FlurryAnalytics logError:name message:message exception:exception];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [FlurryAnalytics logError:name message:message error:error];

}

@end
