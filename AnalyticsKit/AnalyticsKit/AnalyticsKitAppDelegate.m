//
//  AnalyticsKitAppDelegate.m
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 10/23/13.
//  Copyright (c) 2013 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitAppDelegate.h"

@implementation AnalyticsKitAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [AnalyticsKit initializeProviders:@[[AnalyticsKitDebugProvider new]]];
    [AnalyticsKit logEvent:@"App started"];
    return YES;
}
							
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [AnalyticsKit applicationWillEnterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [AnalyticsKit applicationDidEnterBackground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [AnalyticsKit applicationWillTerminate];
}


@end
