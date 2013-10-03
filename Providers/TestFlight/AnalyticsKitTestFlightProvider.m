//
//  AnalyticsKit.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitTestFlightProvider.h"
#import "TestFlight.h"
#import <UIKit/UIKit.h>

@implementation AnalyticsKitTestFlightProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)testFlightKey {
    self = [super init];
    if (self) {
        #ifdef DEBUG
            #if (!TARGET_IPHONE_SIMULATOR)
                // Since Apple no longer allows UDID, TestFlight recommends sending it only in DEBUG builds
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
                #pragma clang diagnostic pop
                [TestFlight setDeviceIdentifier:deviceId];
            #endif
        #endif
        [TestFlight takeOff:testFlightKey];
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

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}
-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}
-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {}
-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {}

@end
