//
//  AnalyticsKitAdjustIOProvider.m
//  S2M
//
//  Created by François Benaiteau on 10/29/13.
//

#import <Adjust/Adjust.h>
#import "AnalyticsKitAdjustIOProvider.h"

@implementation AnalyticsKitAdjustIOProvider

-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken productionEnvironmentEnabled:(BOOL)enabled {
    self = [super init];
    if (self) {
        NSString *environment = ADJEnvironmentSandbox;
        if (enabled) {
            environment = ADJEnvironmentProduction;
        }
        ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment];
        [Adjust appDidLaunch:adjustConfig];
    }
    return self;
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
    ADJEvent *event = [[ADJEvent alloc] initWithEventToken:value];
    [Adjust trackEvent:event];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:event];
    for (id key in dict) {
        id obj = [dict objectForKey:key];
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            [adjustEvent addPartnerParameter:key value:obj];
        }
    }
    [Adjust trackEvent:adjustEvent];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:event];
    [adjustEvent addPartnerParameter:key value:value];
    [Adjust trackEvent:adjustEvent];
}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}


@end
