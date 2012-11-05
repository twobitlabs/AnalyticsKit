//
//  AnalyticsKitFlurryProvider.m
//  TeamStream
//
//  Created by Susan Detwiler on 11/10/11.
//  Copyright (c) 2011 Bleacher Report. All rights reserved.
//

#import "Flurry.h"
#import "AnalyticsKitFlurryProvider.h"

@implementation AnalyticsKitFlurryProvider

-(id<AnalyticsKitProvider>)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        [Flurry startSession:apiKey];
    }
    return self;
}

-(void)runInMainThread:(void (^)(void))block{
    //Flurry requires calls to be made from main thread
    if ([NSThread isMainThread]){
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

-(void)applicationWillEnterForeground {}
-(void)applicationDidEnterBackground {}
-(void)applicationWillTerminate {}

-(void)uncaughtException:(NSException *)exception {
    NSString *message = [NSString stringWithFormat:@"Crash on iOS %@", [[UIDevice currentDevice] systemVersion]];
    [Flurry logError:@"Uncaught" message:message exception:exception];
}

-(void)logScreen:(NSString *)screenName {
    [self runInMainThread:^{
        [Flurry logEvent:[@"Screen - " stringByAppendingString:screenName]];
    }];
}

-(void)logEvent:(NSString *)value {
    [self runInMainThread:^{
        [Flurry logEvent:value];
    }];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    [self runInMainThread:^{
        [Flurry logEvent:event withParameters:dict];
    }];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {
    [self runInMainThread:^{
        [Flurry logEvent:event withParameters:[NSDictionary dictionaryWithObject:value forKey:key]];
    }];
}

- (void)logEvent:(NSString *)eventName timed:(BOOL)timed{
    [self runInMainThread:^{
        [Flurry logEvent:eventName timed:timed];
    }];
}

- (void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{
    [self runInMainThread:^{
        [Flurry logEvent:eventName withParameters:dict timed:timed];
        
    }];
}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{
    [self runInMainThread:^{
        // non-nil parameters will update the parameters
        [Flurry endTimedEvent:eventName withParameters:dict];
     }];
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception {
    [self runInMainThread:^{
        [Flurry logError:name message:message exception:exception];
    }];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error {
    [self runInMainThread:^{
        [Flurry logError:name message:message error:error];
    }];
}

@end
