//
//  AnalyticsKitGoogleAnalyticsProvider.h
//  S2M
//
//  Created by François Benaiteau on 02/14//13.
//


#import "AnalyticsKit.h"

@interface AnalyticsKitGoogleAnalyticsProvider : NSObject<AnalyticsKitProvider>

-(id<AnalyticsKitProvider>)initWithTrackingID:(NSString *)trackingID;
-(void)enableDebug:(BOOL)enabled;
@end

