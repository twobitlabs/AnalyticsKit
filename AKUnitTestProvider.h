//
//  AKUnitTestProvider.h
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnalyticsKit.h"
#import "AKEvent.h"

@interface AKUnitTestProvider : NSObject<AnalyticsKitProvider>

@property(nonatomic,strong)NSMutableArray *events;

+ (AKUnitTestProvider *)setUp;
+ (void)tearDown;
+ (AKUnitTestProvider *)unitTestProvider; // setup must be called first, returns the instance
+ (void)clearEvents; // also called by tearDown; does same thing as instance method

- (void)clearEvents;
- (BOOL)hasEventLoggedWithName:(NSString *)eventName;
- (AKEvent *)firstEventLoggedWithName:(NSString *)eventName;
- (NSArray *)eventsLoggedWithName:(NSString *)eventName;

@end
