//
//  AnalyticsKitUnitTestProvider.h
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnalyticsKitEvent.h"

@interface AnalyticsKitUnitTestProvider : NSObject<AnalyticsKitProvider>

@property(nonatomic,strong)NSMutableArray *events;

+ (AnalyticsKitUnitTestProvider *)setUp;
+ (void)clearEvents; // also called by tearDown
+ (void)tearDown;

- (BOOL)hasEventLoggedWithName:(NSString *)eventName;
- (AnalyticsKitEvent *)firstEventLoggedWithName:(NSString *)eventName;
- (NSArray *)eventsLoggedWithName:(NSString *)eventName;

@end
