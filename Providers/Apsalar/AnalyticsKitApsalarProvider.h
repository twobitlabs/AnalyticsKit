//
//  AnalyticsKitApsalarProvider.h
//  TeamStream
//
//  Created by Susan Detwiler on 1/26/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKit.h"

@interface AnalyticsKitApsalarProvider : NSObject <AnalyticsKitProvider>

@property(retain)NSString *apiKey;
@property(retain)NSString *secret;

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey andSecret:(NSString *)apsalarSecret andLaunchOptions:(NSDictionary *)options;

@end
