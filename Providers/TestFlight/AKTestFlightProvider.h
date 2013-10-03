//
//  AKTestFlightProvider.h
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AKTestFlightProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)testFlightKey;

@end
