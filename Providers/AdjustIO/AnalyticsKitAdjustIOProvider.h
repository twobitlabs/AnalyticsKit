//
//  AnalyticsKitAdjustIOProvider.h
//  S2M
//
//  Created by François Benaiteau on 10/29/13.
//

@interface AnalyticsKitAdjustIOProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken productionEnvironmentEnabled:(BOOL)enabled;
@end

