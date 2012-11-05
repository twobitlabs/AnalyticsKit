//
//  AnalyticsKitMixpanelProvider.h
//  
//
//  Created by Zac Shenker on 5/11/2012.
//  Copyright (c) 2012 Collusion. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AnalyticsKitMixpanelProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey;

@end

