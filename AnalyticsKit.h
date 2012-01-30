//
//  AnalyticsKit.h
//  AnalyticsKit
//
//  Created by Christopher Pickslay on 9/8/11.
//  Copyright (c) 2011 Two Bit Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark Macros - Logging

#define AKLOG(fmt, ...) NSLog(@"%s:%d (%s): " fmt, __FILE__, __LINE__, __func__, ## __VA_ARGS__)
#ifdef DEBUG
#define AKINFO(fmt, ...) AKLOG(fmt, ## __VA_ARGS__)
#else
// do nothing
#define AKINFO(fmt, ...) 
#endif

#define AKERROR(fmt, ...) AKLOG(fmt, ## __VA_ARGS__)

@protocol AnalyticsKitProvider <NSObject>

// Lifecycle
-(void)applicationWillEnterForeground;
-(void)applicationDidEnterBackground;
-(void)applicationWillTerminate;
-(void)uncaughtException:(NSException *)exception;

//Logging events
-(void)logScreen:(NSString *)screenName;
-(void)logEvent:(NSString *)value;
-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value;
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict;
-(void)logEvent:(NSString *)eventName timed:(BOOL)timed;
-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed;
-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict;
-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception;
-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error;


@end

@interface AnalyticsKit : NSObject

+(void)initializeLoggers:(NSArray *)loggers;

+(void)applicationWillEnterForeground;
+(void)applicationDidEnterBackground;
+(void)applicationWillTerminate;
+(void)uncaughtException:(NSException *)exception;

+(void)logScreen:(NSString *)screenName;
+(void)logEvent:(NSString *)value;
+(void)logEvent:(NSString *)key withProperty:(NSString *)property andValue:(NSString *)value;
+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict;
+(void)logEvent:(NSString *)eventName timed:(BOOL)timed;
+(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed;
+(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict;
+(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception;
+(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error;

@end
