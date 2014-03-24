//
//  AnalyticsKitAdjustIOProvider.m
//  S2M
//
//  Created by François Benaiteau on 10/29/13.
//

#import "Adjust.h"
#import "AnalyticsKitAdjustIOProvider.h"

@implementation AnalyticsKitAdjustIOProvider

-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken {
    self = [super init];
    if (self) {
        [Adjust appDidLaunch:appToken];
    }
    return self;
}

-(void)enableProductionEnvironment:(BOOL)enabled
{
    if (enabled) {
        [Adjust setEnvironment:AIEnvironmentProduction];
    }else{
        [Adjust setEnvironment:AIEnvironmentSandbox];
    }
}

#pragma mark - AnalyticsKitProvider Protocol

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {}

-(void)logScreen:(NSString *)screenName {
    [self logEvent:screenName];
}

-(void)logEvent:(NSString *)value {
    [Adjust trackEvent:value];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [Adjust trackEvent:event withParameters:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [Adjust trackEvent:event withParameters:@{key: value}];
}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}


@end
