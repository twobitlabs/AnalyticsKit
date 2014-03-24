//
//  AnalyticsKitTimedEventHelper.h
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 3/21/14.
//  Copyright (c) 2014 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"
#import "AnalyticsKitEvent.h"

@interface AnalyticsKitTimedEventHelper : NSObject

+(void)startTimedEventWithName:(NSString *)name forProvider:(id<AnalyticsKitProvider>)provider;
+(void)startTimedEventWithName:(NSString *)name properties:(NSDictionary *)properties forProvider:(id<AnalyticsKitProvider>)provider;
+(AnalyticsKitEvent *)endTimedEventNamed:(NSString *)name forProvider:(id<AnalyticsKitProvider>)provider;

@end
