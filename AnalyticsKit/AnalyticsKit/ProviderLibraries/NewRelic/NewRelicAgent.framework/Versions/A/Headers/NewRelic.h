//  New Relic version 5.0.3
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


/*
 *  This document describes various APIs available to further customize New Relic's
 *  data collection.
 */

#import "NewRelicFeatureFlags.h"
#import "NRConstants.h"
#import "NRTimer.h"
#import "NRLogger.h"
#import "NewRelicCustomInteractionInterface.h"
#import "NRGCDOverride.h"

#ifdef __cplusplus
extern "C" {
#endif



@interface NewRelic : NSObject

/**************************************/
/** Initializing the New Relic agent **/
/**************************************/


#pragma mark - Helpers for trying out New Relic features

/*!
 * Throws a demo run-time exception named "NewRelicDemoException" to test 
 * New Relic Crash Reporting. 
 *
 * @param message the message attached to the exception
 *
 */

+ (void) crashNow:(NSString*)message;

/*!
 * Throws a demo run-time exception named "NewRelicDemoException" to test 
 * New Relic Crash Reporting. 
 *
 *
 */

+ (void) crashNow;


#pragma mark - Configuring the New Relic SDK

/*!
 Set this bit-wise flag to enable/disable  features.

 @param NRFeatureFlags the NR_OPTIONS bitwise-flag
 
 Note these flags must be set before calling -startWithApplicationToken:
      See NewRelicFeatureFlags.h for more flag details.

*/
+ (void) enableFeatures:(NRMAFeatureFlags)featureFlags;
+ (void) disableFeatures:(NRMAFeatureFlags)featureFlags;


/*! 

 @param BOOL enable or disable crash reporting

 @note call this method before +startWithApplicationToken.
       it will only be effective called before this method.

*/
+ (void) enableCrashReporting:(BOOL)enabled;

/*!
 Sets the version of the application reported to New Relic.

 Normally New Relic will use the CFBundleShortVersionString when reporting application version.
 Override the reported version by calling this method *before* calling startWithApplicationToken:.

 @param versionString The string to display as this application's version
 */
+ (void)setApplicationVersion:(NSString *)versionString;

/*!
 Returns the current anonymous Session Identifier string reported to New Relic.
 The SessionId changes each time your app comes to the foreground on the device.
 This value will be present in all events recorded in New Relic Insights.
 */
+ (NSString*) currentSessionId;


/*!
 Starts New Relic data collection.

 Call this at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method.
 You can find your App Token in the Settings tab of your mobile app on https://rpm.newrelic.com/

 Note that each app within New Relic has a unique app token, be sure to use the correct one.
 */
+ (void)startWithApplicationToken:(NSString*)appToken;


/*!
 Starts New Relic data collection and optionally reports data to New Relic over unencrypted HTTP.

 Call this at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method.
 You can find your App Token in the Settings tab of your mobile app on https://rpm.newrelic.com/

 Note that each app within New Relic has a unique app token, be sure to use the correct one.

 @param disableSSL If TRUE, data will be sent to New Relic unencrypted
 */
+ (void)startWithApplicationToken:(NSString*)appToken withoutSecurity:(BOOL)disableSSL;


#pragma mark - Custom instrumentation

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
 * + (NSString*) startInteractionFromMethodName:(NSString*)selectorName
 *                                  object:(id)object
 *
 * Method Deprecated.
 * see "+(NSString*)startInteractionWithName:(NSString*)interactionName" instead.
 *
 * NOTE:
 *  This method no longer has a function. Under the hood this method calls
 *  [NewRelic startInteractionFromMethodName:selectorName
 *                                     object:object
 *                             customizedName:nil]
 *  and customizedName is now a required parameter.
 *  this function will log an warning and return nil now.
 *
 ******************************************************************************/


+ (NSString*) startInteractionFromMethodName:(NSString*)selectorName object:(id)object __attribute__((deprecated));
#define NR_INTERACTION_START [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self]




/*******************************************************************************
 * + (NSString*) startInteractionFromMethodName:(NSString*)selectorName
 *                                  object:(id)object
 *                          customizedName:(NSString*)interactionName
 *
 * Method Deprecated.
 * see "+(NSString*)startInteractionWithName:(NSString*)interactionName" instead.
 *
 * NOTE:
 *  this method will function the same as +startInteractionWithName: if the
 *  parameter, interactionName, is passed. All other parameters are ignored.
 *  If interactionName is nil, a warning will be logged and nil will be returned.
 *  All other parameters are ignored. 
 *
 *******************************************************************************/


+ (NSString*) startInteractionFromMethodName:(NSString*)selectorName object:(id)object customizedName:(NSString*)interactionName __attribute__((deprecated));
#define NR_INTERACTION_START_WITH_NAME(name) [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self customizedName:name]




/*******************************************************************************
 * + (NSString*) startInteractionFromMethodName:(NSString*)selectorName
 *                                  object:(id)object
 *                          customizedName:(NSString*)interactionName 
 *                   invalidateActiveTrace:(BOOL)invalidate;
 *
 * Method Deprecated.
 * see "+(NSString*)startInteractionWithName:(NSString*)interactionName" instead.
 *
 * NOTE:
 *  this method will function the same as +startInteractionWithName: if the
 *  parameter, interactionName, is passed. All other parameters are ignored.
 *  If interactionName is nil, a warning will be logged and nil will be returned.
 *  All other parameters are ignored. 
 ******************************************************************************/
+ (NSString*) startInteractionFromMethodName:(NSString*)selectorName
                                 object:(id)object
                         customizedName:(NSString*)interactionName
                  cancelRunningTrace:(BOOL)cancel __attribute__((deprecated));

#define NR_INTERACTION_START_WITH_NAME_CANCEL(name,cancel) [NewRelic startInteractionFromMethodName:NSStringFromSelector(_cmd) object:self customizedName:name cancelRunningTrace:cancel]

/*******************************************************************************
 * + (NSString*) startInteractionWithName:(NSString*)interactionName;
 *
 * Parameters:
 *      NSString* interactionName:
 *          required parameter.
 *
 * Return Value:
 *      The return value is an interactionIdentifier that must be passed to stopCurrentInteraction:
 *      if stopCurrentInteraction: is called.
 *      it's not required to call stopCurrentInteraction: after calling start
 *      because startInteractionWithName: will eventually complete intelligently.
 * Discussion:
 *      This method will start an Interaction Trace.
 *      Using interactionName as the name
 *      The interaction will record all instrumented methods until a timeout
 *      occurs, or stopCurrentInteraction is called.
 *
 *      https://docs.newrelic.com/docs/mobile-monitoring/mobile-sdk-api/new-relic-mobile-sdk-api/working-ios-sdk-api#interactions
 *
 * Note:
 *     - NR_START_NAMED_INTERACTION(NSString* name) is a helper
 *       macro that will handle most cases.
 ******************************************************************************/
+ (NSString*) startInteractionWithName:(NSString*)interactionName;

#define NR_START_NAMED_INTERACTION(name) [NewRelic startInteractionWithName:name]
/*******************************************************************************
 *  + (void) stopCurrentInteraction(NSString*)InteractionIdentifier;
 *
 *  Parameters:
 *      NSString* InteractionIdentifier:
 *          the value returned by startInteractionWithName:
 *          It is required to pass this string to manually complete the Interaction Trace.
 *  Discussion:
 *      this method will stop the Interaction trace associated with the interactionIdentifier (returned
 *      by the startInteractionWithName: method). It's not necessary to call this method to
 *      complete an interaction trace (an interaction trace will intelligently complete on its own).
 *      However, use this method if you want a more discrete interaction period.
 *  
 *  Note:
 *      NR_INTERACTION_STOP(NSString* interactionIdentifier) is a helper macro for stopCurrentInteraction.
 *
 ******************************************************************************/
+ (void) stopCurrentInteraction:(NSString*)interactionIdentifier;
#define NR_INTERACTION_STOP(interactionIdentifier) [NewRelic stopCurrentInteraction:interactionIdentifier]

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
 *            creation of the NRTimer and the +startTraceMethod:... method call
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








#pragma mark - Recording custom metrics

/************************/
/**      Metrics       **/
/************************/

// Metrics hold the format "/Custom/${category}/${name}/[${valueUnit}|${countUnit}]"
// category             : a descriptive identifier to categorize the metric
// name                 : a recognizable name
// valueUnit (optional) : the units describing the value added to the metric
//                        (e.g.: seconds, percent) countUnit (optional) : the unit
//                        of the metric itself (e.g.:  calls, operations, views)
//  e.g.: /Custom/ViewLoadingPerformance/MyView[seconds|load]
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
 *      Avoid Using variable string in names and categories, such as GUIDs, to 
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
 *      Avoid Using variable string in names and categories, such as GUIDs, to
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
 * while there are a few predefined units please feel free to add your own by
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
 *      Sec. While there are a few predefined units please feel free to add
 *       your own by typecasting an NSString.
 *
 *  Note:
 *      Avoid Using variable string in names and categories, such as GUIDs, to
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
 *      This method adds on the last with the addition of setting the optional
 *      parameter countUnits.
 *
 *      NRMetricUnit is a redefinition of NSString.  The unit names may be mixed
 *      case and must consist strictly of alphabetical characters as well as
 *      the _, % and / symbols. Case is preserved. Recommendation: Use
 *      uncapitalized words, spelled out in full. For example, use second not
 *      Sec. While there are a few predefined units please feel free to add
 *       your own by typecasting an NSString.
 *
 *  Note:
 *      Avoid Using variable string in names and categories, such as GUIDs, to
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



#pragma mark - Recording custom network events

/*********************************/
/**      Network Requests       **/
/*********************************/

/*******************************************************************************
 * Manually record any transactional, HTTP-like network request that completes.
 *  Parameters:
 *      NSURL* URL:
 *          The URL of the request.
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
                        httpMethod:(NSString*)httpMethod
                         withTimer:(NRTimer *)timer
                   responseHeaders:(NSDictionary *)headers
                        statusCode:(NSInteger)httpStatusCode
                         bytesSent:(NSUInteger)bytesSent
                     bytesReceived:(NSUInteger)bytesReceived
                      responseData:(NSData *)responseData
                         andParams:(NSDictionary *)params;

+ (void)noticeNetworkRequestForURL:(NSURL*)url
                         withTimer:(NRTimer *)timer
                   responseHeaders:(NSDictionary *)headers
                        statusCode:(NSInteger)httpStatusCode
                         bytesSent:(NSUInteger)bytesSent
                     bytesReceived:(NSUInteger)bytesReceived
                      responseData:(NSData *)responseData
                         andParams:(NSDictionary *)params __attribute__((deprecated));



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
                        httpMethod:(NSString*)httpMethod
                         withTimer:(NRTimer *)timer
                    andFailureCode:(NSInteger)iOSFailureCode;


+ (void)noticeNetworkFailureForURL:(NSURL *)url
                         withTimer:(NRTimer *)timer
                    andFailureCode:(NSInteger)iOSFailureCode __attribute__((deprecated));



#pragma mark - Recording custom events

/*!
 Records a event.
 @param name a name for the event. This will be stored in the 'category' attribute of Mobile events in New Relic Insights.
 @param attributes A NSDictionary of attributes associated with the event. Attributes should have NSString keys and NSString or NSNumber values.
 @return YES if successfully added event, NO if failed with error in log.
 
 @note Events are transmitted at the end of the application session. Each event will include all global attributes defined at the end of the session.
   If a session runs for more than `maxEventBufferTime` seconds, events will be transmitted mid-session and include all global attributes defined at the time of transmission.
 */
+ (BOOL) recordEvent:(NSString*)name
          attributes:(NSDictionary*)attributes;


#pragma mark - Configuring event collection

/*!
 Change the maximum length of time before the SDK sends queued events to New Relic.
 
 @param seconds The number of seconds to wait before sending any events to New Relic.
 
 The default timeout before sending events is 600 seconds (10 minutes). If the user 
 keeps your app open for longer than that, any stored events will be transmitted and the timer resets. 
 
 @note events transmitted before the end of session will not have a `sessionDuration` attribute.
 */
+ (void) setMaxEventBufferTime:(unsigned int)seconds;


/*!
 Change the maximum number of events that will be stored in memory.
 
 @param size the maximum number of events to store in memory
 
 By default the SDK will store up to 1000 events in memory. If more events are
  recorded before `maxEventBufferTime` seconds elapse, events are sampled using 
  a Reservoir Sampling algorithm. http://en.wikipedia.org/wiki/Reservoir_sampling
 If `maxEventBufferTime` seconds elapse, the existing event buffer will be transmitted and then emptied.
 */
+ (void) setMaxEventPoolSize:(unsigned int)size;


#pragma mark - Tracking global attributes

/*!
 Records an attribute that will be added to all events in this app install.
 Attributes are maintained across sessions and endure until removed or modified.
 
  @param name The name of the attribute
  @param value The value associated with the attribute; either an NSString* or NSNumber*
  @return YES if successfully set attribute value, NO if failed with error in log.
 
  @note The SDK limits you to storing 64 named attributes. Adding more than 64 will fail and return NO.
 */

+ (BOOL) setAttribute:(NSString*)name
                value:(id) value;

/*!
 Increments the value of the named attribute by 1.
 
 @param name The name of the attribute
 @return YES if successfully modified attribute value, NO if failed with error in log.
 
 @note This method will create an attribute with value 1 if the attribute does not exist. 
 @note Calling incrementAttribute on an attribute with a NSString* value is an error and will not alter the value of the attribute.
 */
+ (BOOL) incrementAttribute:(NSString*)name;

/*!
 Increments the value of the named attribute by the supplied amount.
 
 @param name The name of the attribute
 @param amount Numeric value to add to the attribute
 @return YES if successfully modified attribute value, NO if failed with error in log.
 
 @note This method will create an attribute with value 'amount' if the attribute does not exist.
 @note Calling incrementAttribute on an attribute with a NSString* value is an error and will not alter the value of the attribute.
 */
+ (BOOL) incrementAttribute:(NSString*)name
                      value:(NSNumber*)amount;


/*!
 Removes the named attribute.
 
 @param name The name of the attribute to remove
 @return YES if successfully removed attribute, NO if failed with error in log.
 
 @note removing an attribute will remove it from all events that have been recorded but not yet sent to New Relic's server.
 */
+ (BOOL) removeAttribute:(NSString*)name;

/*!
 Removes all defined attributes.
 
 @return YES if successfully removed attributes, NO if failed with error in log.
 
 @note removing attributes will remove them from all events that have been recorded but not yet sent to New Relic's server.
 */
+ (BOOL) removeAllAttributes;



@end

// Deprecated class name, included for compatibility
@interface NewRelicAgent : NewRelic
@end

#ifdef __cplusplus
}
#endif
