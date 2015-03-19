//
//  AnalyticsKitNewRelicProvider.h
//  
//
//  Created by Zac Shenker on 26/03/2013.
//  Copyright (c) 2013 Collusion. All rights reserved.
//

#import <NewRelicAgent/NewRelic.h>
#import "AnalyticsKit.h"

@interface AnalyticsKitNewRelicProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey;
-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey crashReporting:(BOOL)crashReporting;
-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey crashReporting:(BOOL)crashReporting disableFeatures:(NRMAFeatureFlags)featuresToDisable;

@end

