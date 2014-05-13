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



/*!
 NRMAFeatureFlags
 
 These flags are used to indentify new relic features.
 
 - NewRelicNSURLSessionInstrumentation
    disabled by default. Flag for Instrumentation of NSURLSessions. 
    Currently only instruments network activity dispatched with
    NSURLSessionDataTasks and NSURLSessionUploadTasks.

 */

typedef NS_OPTIONS(unsigned long long, NRMAFeatureFlags){
    NRFeatureFlag_NSURLSessionInstrumentation = 1 << 4,
    NRFeatureFlag_AllFeatures                 = ~0
};