//
//  AnalyticsKitDebug.m
//  TeamStream
//
//  Created by Susan Detwiler on 5/29/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitDebugProvider.h"

@interface AnalyticsKitDebugProvider()

@property(nonatomic,weak)UIAlertView *alert;

@end

@implementation AnalyticsKitDebugProvider

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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AnalyticsKit Received Error"
                                                             message:message
                                                            delegate:nil cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            #if !__has_feature(objc_arc)
            [alert autorelease];
            #else
            if (self.alert) [alert dismissWithClickedButtonIndex:0 animated:NO];
            self.alert = alert;
            #endif
            [alert show];
        }];
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{
    NSString *detail = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", name, message, exception];
    [self showDebugAlert:detail];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{
    NSString *detail = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", name, message, error];    
    [self showDebugAlert:detail];
}

@end
