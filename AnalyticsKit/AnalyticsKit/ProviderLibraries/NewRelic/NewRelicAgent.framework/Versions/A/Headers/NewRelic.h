//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2013 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//


/*
 *  This document describes various APIs available to further customize New Relic
 *  data consumption. Using these APIs should provide a way to gain insight into
 *  un-instrumented methods and interactions.
 *
 */

#import "NRConstants.h"
#import "NRTimer.h"
#import "NRLogger.h"
#import "NRGCDOverride.h"
#import "NewRelicFeatureFlags.h"

#ifdef __cplusplus
extern "C" {
#endif

@interface NewRelic : NSObject

/**************************************/
/** Initializing the New Relic agent **/
/**************************************/


/*!
 Set this bit-wise flag to enable/disable  features.

 @param NRMAFeatureFlag the NR_OPTIONS bitwise-flag 
 
 Note these flags must be set before calling -startWithApplicationToken:
      See NewRelicFeatureFlags.h for more flag details.

*/

+ (void) enableFeatures:(NRMAFeatureFlags)featureFlags;

+ (void) disableFeatures:(NRMAFeatureFlags)featureFlags;
/*!
 Sets the version of the application reported to New Relic.

 Normally New Relic will use the CFBundleShortVersionString when reporting application version.
 Override the reported version by calling this method *before* calling startWithApplicationToken:.

 @param versionString The string to display as this application's version
 */
+ (void)setApplicationVersion:(NSString *)versionString;

/*!
 Starts the New Relic agent.

 Call this at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method.
 You can find your App Token in the Settings tab of your mobile app on https://rpm.newrelic.com/

 Note that each app within New Relic has a unique app token, be sure to use the correct one.
 */
+ (void)startWithApplicationToken:(NSString*)appToken;


/*!
 Starts the New Relic agent and optionally reports data to New Relic over unencrypted HTTP.

 Call this at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method.
 You can find your App Token in the Settings tab of your mobile app on https://rpm.newrelic.com/

 Note that each app within New Relic has a unique app token, be sure to use the correct one.

 @param disableSSL If TRUE, data will be sent to New Relic unencrypted
 */
+ (void)startWithApplicationToken:(NSString*)appToken withoutSecurity:(BOOL)disableSSL;


/*!
 Create and start a timer object.

 When using our API to track your own data:
 1) Call createAndStartTimer to retrieve a new, running timer object immediately before beginning whatever work you are tracking.
 2) Call [theTimer stopTimer] immediately after the work is complete.
 3) Pass your timer object into the NewRelic API when recording your data.

 Note that all public NewRelic notice... and record... API methods will stop the timer objects you pass in to them.
 */
+ (NRTimer *)createAndStartTimer;


/************************/
/** Interaction Traces **/
/************************/

/*******************************************************************************
 * + (void) startInteractionFromMethodName:(NSString*)selectorName 
 *                                  object:(id)object
 *
 * Parameters:
 *      NSString *selectorNamed:
 *          should be the selector of the surrounding method.
 *          cannot be nil.
 *      id object:
 *          the object/Class that executes the selector.
 *          cannot be nil;
 *
 * Discussion:
 *      This method will start an Interaction Trace if one is not already 
 *      running (otherwise nothing will happen) using [object class] + "#" + 
 *      selectorNamed as the name. The interaction will record all instrumented
 *      methods until a timeout occures
 *      TODO: link to Interaction Traces document
 *
 *
 * Note:
 *     - NR_INTERACTION_START is a helper macro that will handle most cases.
 *
 ******************************************************************************/


+ (void) startInteractionFromMethodName:(NSString*)selectorName object:(id)object;
#define NR_INTERACTION_START [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self]




/*******************************************************************************
* + (void) startInteractionFromMethodName:(NSString*)selectorName
*                                  object:(id)object
*                          customizedName:(NSString*)interactionName
*
* Parameters:
*      NSString *selectorNamed:
*          should be the selector of the surrounding method.
*          cannot be nil.
*      id object:
*          the object/Class that executes the selector.
*          cannot be nil;
*      NSString* interactionName:
*          setting this parameter will override the default
*          [object class] + "#" + selectorNamed default name.
*
* Discussion:
*      This method will start an Interaction Trace if one is not already
*      running (otherwise nothing will happen) using interactionName as the
*      name, with [object class] + "#" + selectorNamed default if
*      interactionNamed == nil. The interaction will record all instrumented
*      methods until a timeout occures.
*      TODO: link to Interaction Traces document
*
*
* Note:
*     - NR_INTERACTION_START(NSString* name) is a helper macro that will
*       handle most cases.
*
********************************************************************************/


+ (void) startInteractionFromMethodName:(NSString*)selectorName object:(id)object customizedName:(NSString*)interactionName;
#define NR_INTERACTION_START_WITH_NAME(name) [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self customizedName:name]




/*******************************************************************************
 * + (void) startInteractionFromMethodName:(NSString*)selectorName
 *                                  object:(id)object
 *                          customizedName:(NSString*)interactionName 
 *                   invalidateActiveTrace:(BOOL)invalidate;
 *
 * Parameters:
 *      NSString *selectorNamed:
 *          should be the selector of the surrounding method.
 *          cannot be nil.
 *      id object:
 *          the object/Class that executes the selector.
 *          cannot be nil;
 *      NSString* interactionName:
 *          setting this parameter will override the default [object class] +
 *          "#" + selectorNamed default name.
 *      BOOL invalidate:
 *          setting this to YES will stop the currently running Interaction 
 *          Trace. NO is the default behaivor.
 *
 * Discussion:
 *      This method will start an Interaction Trace. If the invalidate flag is 
 *      set, it will stop the currently running Interaction Trace.
 *      Using interactionName as the name, with [object class] + "#" +
 *      selectorNamed default if interactionNamed == nil.
 *      The interaction will record all instrumented methods until a timeout 
 *      occures.
 *      TODO: link to Interaction Traces document
 *
 * Note:
 *     - NR_INTERACTION_START(NSString* name, BOOL invalidate) is a helper 
 *       macro that will handle most cases.
 ******************************************************************************/
+ (void) startInteractionFromMethodName:(NSString*)selectorName
                                 object:(id)object
                         customizedName:(NSString*)interactionName
                  cancelRunningTrace:(BOOL)cancel;

#define NR_INTERACTION_START_WITH_NAME_CANCEL(name,cancel) [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self customizedName:name cancelRunningTrace:cancel]




/************************/
/**   Method Tracing   **/
/************************/



/*******************************************************************************
 *
 *  + (void) startTracingMethod:(SEL)selector
 *                        object:(id)object
 *                         timer:(NRTimer*)timer
 *
 *  Parameters: 
 *      SEL selector:
 *          should be the selector of the surrounding method
 *          used to name the Trace element
 *      id object:
 *          should be the "self" reference of the surrounding method
 *      NRTimer* timer:
 *          should be an NRTimer initialized just prior to calling this method
 *          and later passed to +endTracingMethodWithTimer:
 *
 *  Discussion:
 *      This method adds a new method trace to the currently running 
 *      Interaction Trace. If no interaction trace is running, nothing will
 *      happen. This method should be called at the beginning of
 *      the method you wish to instrument. The timer parameter is a New Relic 
 *      defined object that only needs to be created just prior to calling this
 *      method and must stay in memory until it is passed to the
 *      +endTracingMethodWithTimer: method call at the end of the custom 
 *      instrumented method.
 *
 *      Note:
 *          - NR_TRACE_METHOD_START is a helper macro that handles the
 *            creation of tue NRTimer and the +startTraceMethod:... method call
 *            Please observer that this should be called in tandem with 
 *            NR_ARC_TRACE_METHOD_STOP or NR_NONARC_TRACE_METHOD_STOP 
 *            see +endTracingMethodWithTimer: for more details.

 ******************************************************************************/

+ (void) startTracingMethod:(SEL)selector
                     object:(id)object
                      timer:(NRTimer*)timer
                   category:(enum NRTraceType)category;

#define NR_TRACE_METHOD_START(traceCategory)  NRTimer *__nr__trace__timer = [[NRTimer alloc] init]; [NewRelic startTracingMethod:_cmd object:self timer:__nr__trace__timer category:traceCategory];



/*******************************************************************************
 *
 *  + (void) endTracingMethodWithTimer:(NRTimer*)timer
 *
 *  Parameters:
 *      NRTimer* timer:
 *          this should be the timer that was passed to 
 *          +startTracingMethod:object:timer: at the beginning of the method
 *          you wish to instrument.
 *
 *  Discussion:
 *      This method should be called at the end of any method you instrument
 *      with +startTracingMethod:object:timer:. Failure to do some will result
 *      in an unhealthy timeout of the running Interaction Trace. If no 
 *      Interaction Trace is running, this method will do nothing.
 *  
 *  Note: 
 *      - NR_ARC_TRACE_METHOD_STOP and NR_NONARC_TRACE_METHOD_STOP are helper
 *        macros designed to be used in tandem with NR_TRACE_METHOD_START.
 *        the only difference between the two is NR_NONARC_TRACE_METHOD_STOP 
 *        cleans up the NRTimer created with NR_TRACE_METHOD_START;
 *
 ******************************************************************************/

+ (void) endTracingMethodWithTimer:(NRTimer*)timer;

#define NR_TRACE_METHOD_STOP   [NewRelic endTracingMethodWithTimer:__nr__trace__timer]; __nr__trace__timer = nil;
#define NR_NONARC_TRACE_METHOD_STOP   [NewRelic endTracingMethodWithTimer:__nr__trace__timer]; [__nr__trace__timer release];__nr__trace__timer = nil;










/************************/
/**      Metrics       **/
/************************/

// Metrics hold the format "/Custom/${category}/${name}/[${valueUnit}|${countUnit}]"
// category             : a descriptive identifier to categorize the metric
// name                 : a recognizable name
// valueUnit (optional) : the units describing the value added to the metric
//                        (eg. seconds, percent) countUnit (optional) : the unit
//                        of the metric itself (eg.  calls, operations, views)
//  eg. /Custom/ViewLoadingPerformance/MyView[seconds|load]
//      this metric would represent the the load time of MyView in seconds.
//      The unit of the value passed is seconds, and each metric recorded
//      represents a view 'load'.
//
//      /Custom/Usage/PageViews[|count]
//      this metric represents page views. It has no value unit, but each metric
//      represents a count.
//
//      /Custom/Performance/DBWrites[bytes/second]
//      this one doesn't have a count unit but the value units are bytes/second
//
//  Some common units are provided in NRConstants.h
//
//  metrics are all accumulated and stored with: total, min, max, count, and
//  sum of squares.
//
// More details @ http://docs.newrelic.com/docs/plugin-dev/metric-units-reference




/*******************************************************************************
 *
 *  + (void)recordMetricsWithName:(NSString*)name
 *                       category:(NSString*)category;
 *
 *  Parameters:
 *      NSString* name: 
 *          The metrics name.
 *      NSString* category:
 *          A descriptive category.
 *
 *  Discussion:
 *      This method will record a metric without units and a value of 1
 *
 *  Note:
 *      Avoid Using variable string in names and categories, such as guids, to 
 *      avoid metric grouping issues.
*       More details @ http://docs.newrelic.com/docs/features/metric-grouping-issues
 *
 *
 ******************************************************************************/

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category;

/*******************************************************************************
 *
 *  + (void)recordMetricsWithName:(NSString*)name
 *                       category:(NSString*)category
 *                          value:(NSNumber*)value;
 *
 *  Parameters:
 *      NSString* name:
 *          The metrics name.
 *      NSString* category:
 *          A descriptive category.
 *      NSNumber* value:
 *          The value you wish to record. This value will be handled as a double
 *
 *  Discussion:
 *      This method will record a metric without units
 *  Note:
 *      Avoid Using variable string in names and categories, such as guids, to
 *      avoid metric grouping issues.
 *       More details @ http://docs.newrelic.com/docs/features/metric-grouping-issues
 *
 *
 ******************************************************************************/


+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value;

// adds a unit for the value
/*
 * while there are a few pre-defined units please feel free to add your own by
 * typecasting an NSString.
 *
 * The unit names may be mixed case and may consist strictly of alphabetical
 * characters as well as the _, % and / symbols. Case is preserved.
 * Recommendation: Use uncapitalized words, spelled out in full.
 * For example, use second not Sec.
 */

/*******************************************************************************
 *
 *  + (void)recordMetricsWithName:(NSString*)name
 *                       category:(NSString*)category
 *                          value:(NSNumber*)value
 *                     valueUnits:(NRMetricUnit*)valueUnits;
 *
 *  Parameters:
 *      NSString* name:
 *          The metrics name.
 *      NSString* category:
 *          A descriptive category.
 *      NSNumber* value:
 *          The value you wish to record. This value will be handled as a double
 *      NRMetricUnit* valueUnits:
 *          Represents the units of value.
 *
 *  Discussion:
 *      This method adds on the last with the addition of setting the value
 *      Units. 
 *
 *      NRMetricUnit is a redefinition of NSString.  The unit names may be mixed
 *      case and must consist strictly of alphabetical characters as well as
 *      the _, % and / symbols. Case is preserved. Recommendation: Use 
 *      uncapitalized words, spelled out in full. For example, use second not
 *      Sec. While there are a few pre-defined units please feel free to add
 *       your own by typecasting an NSString.
 *
 *  Note:
 *      Avoid Using variable string in names and categories, such as guids, to
 *      avoid metric grouping issues.
 *       More details @ http://docs.newrelic.com/docs/features/metric-grouping-issues
 *
 *
 ******************************************************************************/


+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit*)valueUnits;

// adds count units default is just "sample"
// The count is the number of times the particular metric is recorded
// so the countUnits could be considered the units of the metric itself.

/*******************************************************************************
 *
 *  + (void)recordMetricsWithName:(NSString*)name
 *                       category:(NSString*)category
 *                          value:(NSNumber*)value
 *                     valueUnits:(NRMetricUnit*)valueUnits
 *                     countUnits:(NRMetricUnit*)countUnits;
 *
 *  Parameters:
 *      NSString* name:
 *          The metrics name.
 *      NSString* category:
 *          A descriptive category.
 *      NSNumber* value:
 *          Must be greater than 0 or else nothing is recorded. The value you 
 *          wish to record. This value will be handled as a double.
 *      NRMetricUnit* valueUnits:
 *          Optional: Represents the units of value.
 *      NRMetricUnit* countUnits:
 *          Optional: represents the units of the metric.
 *
 *  Discussion:
 *      This method adds on the last with the addition of setting the opptional
 *      parameter countUnits.
 *
 *      NRMetricUnit is a redefinition of NSString.  The unit names may be mixed
 *      case and must consist strictly of alphabetical characters as well as
 *      the _, % and / symbols. Case is preserved. Recommendation: Use
 *      uncapitalized words, spelled out in full. For example, use second not
 *      Sec. While there are a few pre-defined units please feel free to add
 *       your own by typecasting an NSString.
 *
 *  Note:
 *      Avoid Using variable string in names and categories, such as guids, to
 *      avoid metric grouping issues.
 *       More details @ http://docs.newrelic.com/docs/features/metric-grouping-issues
 *
 *
 ******************************************************************************/

+ (void) recordMetricWithName:(NSString *)name
                     category:(NSString *)category
                        value:(NSNumber *)value
                   valueUnits:(NRMetricUnit *)valueUnits
                   countUnits:(NRMetricUnit *)countUnits;




/*********************************/
/**      Network Requests       **/
/*********************************/

/*******************************************************************************
 * Manually record any transactional, HTTP-like network request that completes.
 *  Parameters:
 *      NSURL* url:
 *          The url of the request.
 *      NRTimer* timer:
 *          A timer that captures the start and end of the request.
 *      NSDictionary* headers:
 *          A dictionary of the headers returned in the server response.
 *      NSInteger httpStatusCode:
 *          The status code of the HTTP response.
 *      NSUInteger bytesSent:
 *          The number of bytes sent in the request body.
 *      NSUInteger bytesReceived:
 *          The number of bytes received in the response body.
 *      NSData* responseData:
 *          The response body data returned by the server.
 *          Used when recording a traced server error.
 *      NSDictionary* params:
 *          Unused.
 *
 * New Relic will track the URL, response time, status code, and data send/received.
 * If the response headers dictionary contains a X-NewRelic-AppData header, New Relic
 * will track the association between the mobile app and the web server and
 * display the correlation and the server vs. network vs. queue time in the New Relic UI.
 *
 * If the HTTP status code indicates an error (400 and above) New Relic will also
 * track this request as a server error, optionally capturing the response type
 * and encoding from the headers dictionary and the response body data as a
 * server error in the New Relic UI.
 *******************************************************************************/
+ (void)noticeNetworkRequestForURL:(NSURL*)url
                         withTimer:(NRTimer *)timer
                   responseHeaders:(NSDictionary *)headers
                        statusCode:(NSInteger)httpStatusCode
                         bytesSent:(NSUInteger)bytesSent
                     bytesReceived:(NSUInteger)bytesReceived
                      responseData:(NSData *)responseData
                         andParams:(NSDictionary *)params;


/*******************************************************************************
 * Manually record a failed transactional network request.
 *
 * Failed requests are requests that fail to receive a complete response from
 * the server due to, e.g., TCP timeouts, SSL failures, connection closures, etc.
 * 
 * Refer to the NRNetworkFailureCode enum for failure type symbolic names.
 * The failure codes you pass into this method should correlate to Apple's documented
 * NSURLConnection failure codes:
 * http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html#//apple_ref/doc/uid/TP40003793-CH3g-SW40
 *******************************************************************************/
+ (void)noticeNetworkFailureForURL:(NSURL *)url
                         withTimer:(NRTimer *)timer
                    andFailureCode:(NSInteger)iOSFailureCode;



@end

// Deprecated class name, included for compatibility
@interface NewRelicAgent : NewRelic
@end

#ifdef __cplusplus
}
#endif
