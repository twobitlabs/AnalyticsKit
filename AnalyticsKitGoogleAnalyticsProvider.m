//
//  AnalyticsKitGoogleAnalyticsProvider.m
//  S2M
//
//  Created by François Benaiteau on 02/14//13.
//

#import "GAI.h"
#import "AnalyticsKitGoogleAnalyticsProvider.h"

@implementation AnalyticsKitGoogleAnalyticsProvider

-(id<AnalyticsKitProvider>)initWithTrackingID:(NSString *)trackingID
{
    self = [super init];
    if (self) {
        [[GAI sharedInstance] trackerWithTrackingId:trackingID];
    }
    return self;
}

// Lifecycle
-(void)applicationWillEnterForeground{
    NSLog(@"Not implemented yet");
}

-(void)applicationDidEnterBackground{
    NSLog(@"Not implemented yet");
}

-(void)applicationWillTerminate{
    NSLog(@"Not implemented yet");
}

-(void)uncaughtException:(NSException *)exception
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendException:YES withNSException:exception];
}


//Logging events
-(void)logScreen:(NSString *)screenName
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:screenName];
}

-(void)logEvent:(NSString *)event
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendEventWithCategory:nil
                        withAction:nil
                         withLabel:event
                         withValue:nil];
    
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendEventWithCategory:nil
                        withAction:key
                         withLabel:event
                         withValue:nil];
    
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendEventWithCategory:nil
                        withAction:nil
                         withLabel:event
                         withValue:nil];
    

}
-(void)logEvent:(NSString *)event timed:(BOOL)timed
{
    NSLog(@"Not implemented yet");
}
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed
{
    NSLog(@"Not implemented yet");
}
-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    NSLog(@"Not implemented yet");
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendException:NO withNSException:exception];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendException:NO withNSError:error];

}

#pragma mark - Extra methods

-(void)enableDebug:(BOOL)enabled
{
    [GAI sharedInstance].debug = enabled;
}

-(void)enableHandleUncaughtExceptions:(BOOL)enabled
{
    [GAI sharedInstance].trackUncaughtExceptions = enabled;
}
@end
