//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2014 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>
#import "NRConstants.h"

#ifdef __cplusplus
extern "C" {
#endif

@interface NRCustomMetrics : NSObject



/* Here's the Style:
 * Metric format: /Custom/{$category}/{$name}[{$valueUnit}|{$countUnit}]
 */


//set the metric name and it's category
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category;

//add a value to be recorded
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value;

// adds a unit for the value
/*
 * while there are a few pre-defined units please feel free to add your own by
 * typecasting an NSString.
 *
 * The unit names may be mixed case and may consist strictly of alphabetical
 * characters as well as the _, % and / symbols.Case is preserved.
 * Recommendation: Use uncapitalized words, spelled out in full.
 * For example, use second not Sec.
 */

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit*)valueUnits;

//adds count units default is just "sample"
// The count is the number of times the particular metric is recorded
// so the countUnits could be considered the units of the metric itself.
+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit *)valueUnits
                   countUnits:(NRMetricUnit *)countUnits;


@end

#ifdef __cplusplus
}
#endif
