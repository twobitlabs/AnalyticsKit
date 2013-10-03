//
//  AnalyticsKitParseProvider.h
//
//  Created by Bradley David Bergeron on 10/02/2013.
//  Copyright (c) 2013 Bradley David Bergeron. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AnalyticsKitParseProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

@end

