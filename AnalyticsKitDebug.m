//
//  AnalyticsKitDebug.m
//  TeamStream
//
//  Created by Susan Detwiler on 5/29/12.
//  Copyright (c) 2012 Bleacher Report. All rights reserved.
//

#import "AnalyticsKitDebug.h"

@implementation AnalyticsKitDebug

#pragma mark -
#pragma mark Lifecycle

-(void)applicationWillEnterForeground{}

-(void)applicationDidEnterBackground{}

-(void)applicationWillTerminate{}

-(void)uncaughtException:(NSException *)exception{}

#pragma mark -
#pragma mark Event Logging

-(void)logScreen:(NSString *)screenName{}

-(void)logEvent:(NSString *)value {}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)showDebugAlert:(NSString *)message{
    if (DEBUG == 1){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"AnalyticsKit Received Error" 
                                                             message:message
                                                            delegate:self cancelButtonTitle:@"Ok" 
                                                   otherButtonTitles:nil] autorelease];
            [alert show];
        }];
    }
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{
    [self showDebugAlert:message];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{
    [self showDebugAlert:message];
}

@end
