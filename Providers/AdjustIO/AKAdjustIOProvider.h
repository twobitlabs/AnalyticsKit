//
//  AKAdjustIOProvider.h
//  S2M
//
//  Created by François Benaiteau on 10/29/13.
//

#import "AnalyticsKit.h"

@interface AKAdjustIOProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken;
-(void)enableProductionEnvironment:(BOOL)enabled;
@end
