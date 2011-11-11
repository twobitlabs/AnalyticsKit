//
//  AnalyticsKitFlurryProvider.h
//  TeamStream
//
//  Created by Susan Detwiler on 11/10/11.
//  Copyright (c) 2011 Bleacher Report. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AnalyticsKitFlurryProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey;

@end

