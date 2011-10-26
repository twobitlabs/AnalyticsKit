//
//  AnalyticsKit.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitTestFlightProvider.h"
#import "TestFlight.h"

@implementation AnalyticsKitTestFlightProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)testFlightKey {
    self = [super init];
    if (self) {
        [TestFlight takeOff:TESTFLIGHT_TEAM_TOKEN];
    }
    return self;
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}
-(void)uncaughtException:(NSException *)exception {}

-(void)logEvent:(NSString *)value {
    [TestFlight passCheckpoint:value];
}

-(void)logScreen:(NSString *)screenName {
    [TestFlight passCheckpoint:[@"Screen - " stringByAppendingString:screenName]];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {}
-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {}
-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}
-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}

@end
