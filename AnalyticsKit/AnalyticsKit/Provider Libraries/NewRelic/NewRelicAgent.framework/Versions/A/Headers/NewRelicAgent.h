//
//  NewRelicAgent.h
//  NewRelicAgent
//
//  Copyright (c) 2013 New Relic. All rights reserved.
//

#ifndef _NEWRELIC_AGENT_
#define _NEWRELIC_AGENT_

#import <CoreLocation/CoreLocation.h>

@interface NewRelicAgent : NSObject

/*
 Bootstraps the New Relic agent with an application delegate.
 
 Call this at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method.
 You can find your App Token in the Settings tab of your mobile app on rpm.newrelic.com. 
 
 Note that each app within New Relic has a distinct app token, be sure to use the correct one.
 */
+ (void)startWithApplicationToken:(NSString*)appToken;

/*
 Use this variant to disable SSL for all communication between the agent and New Relic's servers.
 Note that this can improve network response times, especially on a cellular network, but
 it exposes information about your app's operation to listeners on wifi networks.
 New Relic recommends that you not disable SSL.
 */
+ (void)startWithApplicationToken:(NSString*)appToken withoutSecurity:(BOOL)disableSSL;

/*
 If you use Location services you can improve mobile app geographical reporting,
 call this method from your locationManager:didUpdateLocations: delegate method
 when you receive a location update.
 */
+ (void)setDeviceLocation:(CLLocation *)location;


@end

#endif


#ifndef _NEWRELIC_AGENT_LOGGING_
#define _NEWRELIC_AGENT_LOGGING_

/*  The New Relic agent includes an internal logger called NRLogger to make your life a touch easier
    when you want to know what's going on under the hood. You can direct various levels of agent 
    activity messages to the device console through NSLog or to a file stored in the app's document
    directory.

    Please note that NRLogger does not send any data whatsoever to New Relic's servers. You'll need
    to have access to the device/simulator console or dig the file out yourself.
 */


/*
 Log levels used in the agent's internal logger
 
 When calling NRLogger setLogLevels: pass in a bitmask of the levels you want enabled, ORed together
 e.g. [NRLogger setLogLevels:NRLogLevelError|NRLogLevelWarning|NRLogLevelInfo];
 
 NRLogLevelALL is a convenience definition.
 
 NRLogger's default log level is NRLogLevelError|NRLogLevelWarning
 */
typedef enum _NRLogLevels {
    NRLogLevelNone    = 0,
    NRLogLevelError   = 1 << 0,
    NRLogLevelWarning = 1 << 1,
    NRLogLevelInfo    = 1 << 2,
    NRLogLevelVerbose = 1 << 3,
    NRLogLevelALL     = 0xffff
} NRLogLevels;

/*
 Log targets used in the agent's internal logger

 When calling NRLogger setLogTargets: pass in a bitmask of the targets you want enabled, ORed together
 e.g. [NRLogger setLogTargets:NRLogTargetConsole|NRLogTargetFile];
 
 NRLogTargetConsole uses NSLog() to output to the device console
 NRLogTargetFile writes log messages to a file in JSON-format
 NRLogTargetALL is a convenience definition.
 

 NRLogger's default target is NRLogTargetConsole

 */
typedef enum _NRLogTargets {
    NRLogTargetNone      = 0,
    NRLogTargetConsole   = 1 << 0,
    NRLogTargetFile      = 1 << 1,
    NRLogTargetALL       = 0xffff
} NRLogTargets;


@interface NRLogger

/*
 Configuration for the New Relic Agent's internal logging facilities.

 Call these at the beginning of your UIApplicationDelegate's application:didFinishLaunchingWithOptions: method:
 
 [NRLogger setLogLevels:NRLogLevelError|NRLogLevelWarning|NRLogLevelInfo];
 [NRLogger setLogTargets:NRLogTargetConsole|NRLogTargetFile];
 
 */
+ (void)setLogLevels:(NSUInteger)levels;
+ (void)setLogTargets:(NSUInteger)targets;

/*
 Returns the path of the file to which the agent is logging. 
 The file contains comma-separated JSON blobs, each blob encapsulating one log message.
 */
+ (NSString *)logFilePath;

/*
 Clears stored log data:
   Truncates the log file used by the agent
 */
+ (void)clearLog;

@end


#endif