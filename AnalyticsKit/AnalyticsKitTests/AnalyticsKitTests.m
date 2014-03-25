//
//  AnalyticsKitTests.m
//  AnalyticsKitTests
//
//  Created by Christopher Pickslay on 10/23/13.
//  Copyright (c) 2013 Two Bit Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AnalyticsKit.h"
#import "AnalyticsKitAdjustIOProvider.h"
#import "AnalyticsKitApsalarProvider.h"
#import "AnalyticsKitCrashlyticsProvider.h"
#import "AnalyticsKitDebugProvider.h"
#import "AnalyticsKitFlurryProvider.h"
#import "AnalyticsKitGoogleAnalyticsProvider.h"
#import "AnalyticsKitLocalyticsProvider.h"
#import "AnalyticsKitMixpanelProvider.h"
#import "AnalyticsKitNewRelicProvider.h"
#import "AnalyticsKitParseProvider.h"
#import "AnalyticsKitTestFlightProvider.h"
#import "AnalyticsKitUnitTestProvider.h"

@interface AnalyticsKitTests : XCTestCase

@end

@implementation AnalyticsKitTests

-(void)testExample {
    NSArray *providers = @[
                           [[AnalyticsKitAdjustIOProvider alloc] initWithAppToken:nil],
                           [[AnalyticsKitApsalarProvider alloc] initWithAPIKey:nil andSecret:nil andLaunchOptions:nil],
                           [AnalyticsKitCrashlyticsProvider new],
                           [AnalyticsKitDebugProvider new],
                           [[AnalyticsKitFlurryProvider alloc] initWithAPIKey:nil],
                           [[AnalyticsKitGoogleAnalyticsProvider alloc] initWithTrackingID:nil],
                           // Localytics validates the key when you initialize it, so it can't be empty or fake
//                           [[AnalyticsKitLocalyticsProvider alloc] initWithAPIKey:nil],
                           [[AnalyticsKitMixpanelProvider alloc] initWithAPIKey:nil],
                           [[AnalyticsKitNewRelicProvider alloc] initWithAPIKey:nil],
                           [[AnalyticsKitParseProvider alloc] initWithApplicationId:@"x" clientKey:@"y"],
                           [[AnalyticsKitTestFlightProvider alloc] initWithAPIKey:nil],
                           [AnalyticsKitUnitTestProvider new]
                           ];
    [AnalyticsKit initializeLoggers:providers];
    
    NSMutableArray *mocks = [NSMutableArray array];
    for (id provider in providers) {
        id mock = [OCMockObject partialMockForObject:provider];
        [mocks addObject:mock];
        [[mock expect] logEvent:@"foo"];
    }
    
    [AnalyticsKit logEvent:@"foo"];
    
    for (id mock in mocks) {
        [mock verify];
    }
}

@end
