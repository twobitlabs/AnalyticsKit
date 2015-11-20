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

/**
 Note about timed events
 
 If the analytics provider supports timed events directly, their logic around event timing is used.
 If the analytics provider does not support timed events, event timing is keyed on `event`, ignoring properties
 (though the properties will be logged with the event). Successive calls to `logEvent:timed:YES` with the same
 event name will reset the start time of the event. Calling `endTimedEvent:withProperties:` will clear the start 
 time and log a new event, adding the lapsed time to the properties with the key "AnalyticsKitEventTimeSeconds".
 */

//Logging events
-(void)logScreen:(NSString *)screenName;
-(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict;
-(void)logScreen:(NSString *)screenName timed:(BOOL)timed;
-(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict timed:(BOOL)timed;
-(void)endTimedScreen:(NSString *)screenName withProperties:(NSDictionary *)dict;
-(void)logEvent:(NSString *)event;
-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value;
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict;
-(void)logEvent:(NSString *)event timed:(BOOL)timed;
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed;
-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict;
-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception;
-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error;

@optional

-(void) logSignUpWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
-(void) logLogInWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
-(void) logInviteWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
-(void) logStartCheckoutItem:(NSString*) item withProperties:(NSDictionary *)dict;
-(void) logPurchaseItem:(NSString*) item withProperties:(NSDictionary *)dict;
-(void) logShareWithMethod:(NSString*) method withType:(NSString*) type withProperties:(NSDictionary *)dict;

@end

@interface AnalyticsKit : NSObject

OBJC_EXPORT NSString* const AnalyticsKitEventTimeSeconds;

+(void)initialize;
+(void)initializeLoggers:(NSArray *)loggers;
+(NSArray *)loggers;
+(void)applicationWillEnterForeground;
+(void)applicationDidEnterBackground;
+(void)applicationWillTerminate;
+(void)uncaughtException:(NSException *)exception;

+(void)logScreen:(NSString *)screenName;
+(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict;
+(void)logScreen:(NSString *)screenName timed:(BOOL)timed;
+(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict timed:(BOOL)timed;
+(void)endTimedScreen:(NSString *)screenName withProperties:(NSDictionary *)dict;
+(void)logEvent:(NSString *)event;
+(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value;
+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict;
+(void)logEvent:(NSString *)event timed:(BOOL)timed;
+(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed;
+(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict;
+(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception;
+(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error;

+(void) logSignUpWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
+(void) logLogInWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
+(void) logInviteWithMethod:(NSString*) method withProperties:(NSDictionary *)dict;
+(void) logStartCheckoutItem:(NSString*) item withProperties:(NSDictionary *)dict;
+(void) logPurchaseItem:(NSString*) item withProperties:(NSDictionary *)dict;
+(void) logShareWithMethod:(NSString*) method withType:(NSString*) type withProperties:(NSDictionary *)dict;

@end
