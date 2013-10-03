//
//  AKAdjustIOProvider.m
//  S2M
//
//  Created by François Benaiteau on 10/29/13.
//

#import "AdjustIo.h"
#import "AKAdjustIOProvider.h"

@implementation AKAdjustIOProvider

-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken {
    self = [super init];
    if (self) {
        [AdjustIo appDidLaunch:appToken];
    }
    return self;
}

-(void)enableProductionEnvironment:(BOOL)enabled
{
    if (enabled) {
        [AdjustIo setEnvironment:AIEnvironmentProduction];
    }else{
        [AdjustIo setEnvironment:AIEnvironmentSandbox];
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
    [AdjustIo trackEvent:value];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [AdjustIo trackEvent:event withParameters:dict];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [AdjustIo trackEvent:event withParameters:@{key: value}];
}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}


@end
