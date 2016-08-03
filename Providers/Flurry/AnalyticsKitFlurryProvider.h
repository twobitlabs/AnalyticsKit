//
//  AnalyticsKitFlurryProvider.h
//  TeamStream
//
//  Created by Susan Detwiler on 11/10/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

@interface AnalyticsKitFlurryProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey;

@end

