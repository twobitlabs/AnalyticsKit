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

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _NEWRELIC_AGENT_LOGGING_
#define _NEWRELIC_AGENT_LOGGING_

/*************************************/
/**      SDK Internal Logging       **/
/*************************************/

/*******************************************************************************
 * The New Relic agent includes an internal logger called NRLogger to make your
 * life a touch easier when you want to know what's going on under the hood.
 * You can direct various levels of agent activity messages to the device
 * console through NSLog or to a file stored in the app's document directory.
 *
 * Please note that NRLogger does not send any data whatsoever to New Relic's
 * servers. You'll need to have access to the device/simulator console or dig
 * the file out yourself.
 *******************************************************************************/


/*******************************************************************************
 * Log levels used in the agent's internal logger
 *
 * When calling NRLogger setLogLevels: pass in a bitmask of the levels you want
 * enabled, ORed together e.g.
 *   [NRLogger setLogLevels:NRLogLevelError|NRLogLevelWarning|NRLogLevelInfo];
 *
 * NRLogLevelALL is a convenience definition.
 *
 * NRLogger's default log level is NRLogLevelError|NRLogLevelWarning
 *******************************************************************************/

typedef enum _NRLogLevels {
    NRLogLevelNone    = 0,
    NRLogLevelError   = 1 << 0,
    NRLogLevelWarning = 1 << 1,
    NRLogLevelInfo    = 1 << 2,
    NRLogLevelVerbose = 1 << 3,
    NRLogLevelALL     = 0xffff
} NRLogLevels;

typedef enum _NRLogTargets {
    NRLogTargetNone      = 0,
    NRLogTargetConsole   = 1 << 0,
    NRLogTargetFile      = 1 << 1
} NRLogTargets;

#define NRLogMessageLevelKey        @"level"
#define NRLogMessageFileKey         @"file"
#define NRLogMessageLineNumberKey   @"lineNumber"
#define NRLogMessageMethodKey       @"method"
#define NRLogMessageTimestampKey    @"timestamp"
#define NRLogMessageMessageKey      @"message"

/*******************************************************************************
 * Log targets used in the agent's internal logger
 *
 * When calling NRLogger setLogTargets: pass in a bitmask of the targets you
 * want enabled, ORed together e.g.
 *   [NRLogger setLogTargets:NRLogTargetConsole|NRLogTargetFile];
 *
 * NRLogTargetConsole uses NSLog() to output to the device console
 * NRLogTargetFile writes log messages to a file in JSON-format
 * NRLogTargetALL is a convenience definition.
 *
 *NRLogger's default target is NRLogTargetConsole
 *******************************************************************************/

@interface NRLogger : NSObject {
    unsigned int logLevels;
    unsigned int logTargets;
    NSFileHandle *logFile;
}

+ (void)log:(unsigned int)level
     inFile:(NSString *)file
     atLine:(unsigned int)line
   inMethod:(NSString *)method
withMessage:(NSString *)message;


/*!
 Configure the amount if information the New Relic agent outputs about it's internal operation.
 
 @param levels A single NRLogLevels constant, or a bitwise ORed combination of NRLogLevels
 
 Note: If you provide a single constant, e.g. NRLogLevelInfo, all higher priority info will also be output.
 If you provide a combination, e.g. NRLogLevelError | NRLogLevelInfo, only the levels explicitly requested will be output.
 */
+ (void)setLogLevels:(unsigned int)levels;

/*!
 Configure the output channels to which the New Relic agent logs internal operation data.

 @param targets a bitwise ORed combination of NRLogTargets constants

 NRLogTargetConsole will output messages using NSLog()
 NRLogTargetFile will write log messages to a file on the device or simulator. Use logFilePath to retrieve the log file location.
 */
+ (void)setLogTargets:(unsigned int)targets;

/*!
 @result the path of the file to which the New Relic agent is logging.

 The file contains comma-separated JSON blobs, each blob encapsulating one log message.
 */
+ (NSString *)logFilePath;

/*!
 Truncate the log file used by the New Relic agent for data logging.
 */
+ (void)clearLog;

@end


#define NRLOG(level, format, ...) \
    [NRLogger log:level inFile:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] atLine:__LINE__ inMethod:[NSString stringWithUTF8String:__func__] withMessage:[NSString stringWithFormat:format, ##__VA_ARGS__]]

#define NRLOG_ERROR(format, ...) NRLOG(NRLogLevelError, format, ##__VA_ARGS__)
#define NRLOG_WARNING(format, ...) NRLOG(NRLogLevelWarning, format, ##__VA_ARGS__)
#define NRLOG_INFO(format, ...) NRLOG(NRLogLevelInfo, format, ##__VA_ARGS__)
#define NRLOG_VERBOSE(format, ...) NRLOG(NRLogLevelVerbose, format, ##__VA_ARGS__)

#endif // _NEWRELIC_AGENT_LOGGING_

#ifdef __cplusplus
}
#endif
