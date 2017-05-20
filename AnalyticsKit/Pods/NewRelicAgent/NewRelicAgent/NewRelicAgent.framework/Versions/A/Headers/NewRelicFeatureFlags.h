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

/*!
 NRMAFeatureFlags
 
 These flags are used to identify New Relic features.

- NRFeatureFlag_InteractionTracing
   Enable (default) or disable interaction tracing.

- NRFeatureFlag_SwiftInteractionTracing
   Disabled by default. Beware: enabling this feature may cause your swift application to crash.
   please read https://docs.newrelic.com/docs/mobile-monitoring/new-relic-mobile/getting-started/enabling-interaction-tracing-swift
   before enabling this feature.

- NRFeatureFlag_CrashReporting 
   Enabled by default. Enable or disable New Relic's crash reporter.

- NRFeatureFlag_NSURLSessionInstrumentation
   Enable (default) flag for instrumentation of NSURLSessions.
   Currently only instruments network activity dispatched with
   NSURLSessionDataTasks and NSURLSessionUploadTasks.

- NRFeatureFlag_HttpResponseBodyCapture
   Enable (default) or disable HTTP response body capture for HTTP errors. 
   New Relic only captures the response bodies of HTTP errors.

- NRFeatureFlag_DefaultInteractions
   Enabled by default. This flag is used to only disable the default Interactions
   New Relic will trace. Default interactions are started when a view controller is displayed
   and are titled "Displayed <ViewControllerName>". This flag is associated with
   NRFeatureFlag_InteractionTracing, but acts as a subset of functionality on that feature.

- NRFeatureFlag_ExperimentalNetworkingInstrumentation
   Disabled by default. Enables experimental networking instrumentation. This
   feature may decrease the stability of applications.
*/



typedef NS_OPTIONS(unsigned long long, NRMAFeatureFlags){
    NRFeatureFlag_InteractionTracing                    = 1 << 1,
    NRFeatureFlag_SwiftInteractionTracing               = 1 << 2, //disabled by default
    NRFeatureFlag_CrashReporting                        = 1 << 3,
    NRFeatureFlag_NSURLSessionInstrumentation           = 1 << 4,
    NRFeatureFlag_HttpResponseBodyCapture               = 1 << 5,
    NRFeatureFlag_GestureInstrumentation                = 1 << 6,
    NRFeatureFlag_WebViewInstrumentation                = 1 << 7,
    NRFeatureFlag_DefaultInteractions                   = 1 << 12,
    NRFeatureFlag_ExperimentalNetworkingInstrumentation = 1 << 13, //disabled by default
    NRFeatureFlag_AllFeatures                           = ~0ULL //in 32-bit land the alignment is 4bytes
};
