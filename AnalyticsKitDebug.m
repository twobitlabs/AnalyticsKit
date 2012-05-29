//
//  AnalyticsKitDebug.m
//  TeamStream
//
//  Created by Susan Detwiler on 5/29/12.
//  Copyright (c) 2012 Bleacher Report. All rights reserved.
//

#import "AnalyticsKitDebug.h"

@implementation AnalyticsKitDebug

-(void)showDebugAlert:(NSString *)message{
    if (DEBUG == 1){
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"AnalyticsKit Error" 
                                                         message:message
                                                        delegate:self cancelButtonTitle:@"Ok" 
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{
    [self showDebugAlert:message];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{
    [self showDebugAlert:message];
}

@end
