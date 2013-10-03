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

/**
 Google Analytics mapping:
 event is mapped to Google Analytics 'Action' field
*/

/**
 @param event: mapped to Google Analytics 'Action' field
 @param dict: only the following keys will be reported: category, label, value. Support Camelcase or Uppercase keys
 Example:
    dict = @{@"category": @"my category",
            @"label": @"description of event",
            @"value": 100}

 */
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict;
@end

