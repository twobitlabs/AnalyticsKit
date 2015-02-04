//
//  AnalyticsKitNewRelicProvider.h
//  
//
//  Created by Zac Shenker on 26/03/2013.
//  Copyright (c) 2013 Collusion. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AnalyticsKitNewRelicProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey;
-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey crashReporting:(BOOL)crashReporting;

@end

