//
//  AnalyticsKitApsalarProvider.m
//  TeamStream
//
//  Created by Susan Detwiler on 1/26/12.
//  Copyright (c) 2012 Bleacher Report. All rights reserved.
//

#import "AnalyticsKitApsalarProvider.h"
#import "Apsalar.h"

@implementation AnalyticsKitApsalarProvider

@synthesize apiKey = _apiKey;
@synthesize secret = _secret;

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey andSecret:(NSString *)apsalarSecret andLaunchOptions:(NSDictionary *)options{
    self = [super init];
    if (self) {
        [Apsalar startSession:apiKey withKey:apsalarSecret andLaunchOptions:options];
        self.apiKey = apiKey;
        self.secret = apsalarSecret;
    }
    return self;
}

#pragma mark -
#pragma mark Lifecycle

-(void)applicationWillEnterForeground{
    [Apsalar reStartSession:self.apiKey withKey:self.secret];
}

-(void)applicationDidEnterBackground{
    [Apsalar endSession];
}

-(void)applicationWillTerminate {
    [Apsalar endSession];
    self.apiKey = nil;
    self.secret = nil;
}

-(void)uncaughtException:(NSException *)exception{
    NSString *message = [NSString stringWithFormat:@"Crash on iOS %@", [[UIDevice currentDevice] systemVersion]];
    [self logError:@"Uncaught Exception" message:message exception:exception];
}

#pragma mark -
#pragma mark Event Logging

-(void)logScreen:(NSString *)screenName{
    [Apsalar event:[@"Screen - " stringByAppendingString:screenName]];
}

-(void)logEvent:(NSString *)value {
    [Apsalar event:value];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [Apsalar eventWithArgs: event, key, value, nil];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [Apsalar event:event withArgs:dict];
}

//Apsalar doesn't do timed events, so just log as a regular event
-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    [Apsalar event:eventName];
}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    [Apsalar event:eventName withArgs:dict];
}

//this is a no-op as Apsalar doesn't do timed events
-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{
    [Apsalar event:@"Exceptions" withArgs:[NSDictionary dictionaryWithObjectsAndKeys:
                                           name, @"name",
                                           message, @"message",        
                                           [exception name], @"ename",
                                           [exception reason], @"reason",
                                           [exception userInfo], @"userInfo",
                                           nil]];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{
    [Apsalar event:@"Errors" withArgs:[NSDictionary dictionaryWithObjectsAndKeys:
                                       name, @"name",
                                       message, @"message",        
                                       [error localizedDescription], @"description",
                                       [NSString stringWithFormat:@"%d", [error code]], @"code",
                                       [error domain], @"domain",
                                       [[error userInfo] description], @"userInfo",
                                       nil]];
}


@end
