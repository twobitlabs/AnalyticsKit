//
//  AKLocalyitcsProvider.h
//  AnalyticsKit
//
//  Created by Todd Huss on 10/17/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AKLocalyitcsProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)localyticsKey;

@end
