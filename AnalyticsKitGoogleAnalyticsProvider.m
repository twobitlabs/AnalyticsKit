//
//  AnalyticsKitGoogleAnalyticsProvider.m
//  S2M
//
//  Created by François Benaiteau on 02/14//13.
//

#import "GAI.h"
#import "AnalyticsKitGoogleAnalyticsProvider.h"

static NSMutableDictionary *timedEvents;
static dispatch_queue_t timingQueue;

// Constants used to parsed dictionnary to match Google Analytics tracker properties
static NSString* const kCategory = @"Category";
static NSString* const kLabel = @"Label";
static NSString* const kAction = @"Action";
static NSString* const kValue = @"Value";

@implementation AnalyticsKitGoogleAnalyticsProvider

-(id<AnalyticsKitProvider>)initWithTrackingID:(NSString *)trackingID
{
    self = [super init];
    if (self) {
        [[GAI sharedInstance] trackerWithTrackingId:trackingID];
        timedEvents = [NSMutableDictionary dictionary];
        timingQueue = dispatch_queue_create("analyticsKit.goolgeAnalytics.provider", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// Lifecycle
-(void)applicationWillEnterForeground{}

-(void)applicationDidEnterBackground{}

-(void)applicationWillTerminate{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker close];
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
                        withAction:event
                         withLabel:nil
                         withValue:nil];
    
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendEventWithCategory:key
                        withAction:event
                         withLabel:value
                         withValue:nil];
    
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    NSString* category = nil;
    NSString* label = nil;
    NSNumber* value = nil;
    
    if (dict[kCategory]) {
        category = dict[kCategory];
    }
    if (dict[kCategory.lowercaseString]) {
        category = dict[kCategory.lowercaseString];
    }
    
    if (dict[kLabel]) {
        label = dict[kLabel];
    }
    if (dict[kLabel.lowercaseString]) {
        label = dict[kLabel.lowercaseString];
    }
    
    if (dict[kValue]) {
        value = dict[kValue];
    }
    if (dict[kValue.lowercaseString]) {
        value = dict[kValue.lowercaseString];
    }
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendEventWithCategory:category
                        withAction:event
                         withLabel:label
                         withValue:value];
    
    
}
-(void)logEvent:(NSString *)event timed:(BOOL)timed
{
    if (!timed) {
        [self logEvent:event];
    }else{
        
        dispatch_sync(timingQueue, ^{
                          timedEvents[event] = [NSDate date];
                      });
    }    
}
-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed
{
    if (timed) {
        
    }else{
        [self logEvent:event withProperties:dict];
    }
    
}
-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    NSString* category = nil;
    NSString* label = nil;
    
    if (dict[kCategory]) {
        category = dict[kCategory];
    }
    if (dict[kCategory.lowercaseString]) {
        category = dict[kCategory.lowercaseString];
    }
    
    if (dict[kLabel]) {
        label = dict[kLabel];
    }
    if (dict[kLabel.lowercaseString]) {
        label = dict[kLabel.lowercaseString];
    }

    __block NSTimeInterval time;
    dispatch_sync(timingQueue, ^{
        // calculating the elapsed time
        NSDate* startDate = timedEvents[event];
        NSDate* endDate = [NSDate date];
        time = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970;
        // removed time which will be logged
        [timedEvents removeObjectForKey:event];
    });

    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendTimingWithCategory:category
                          withValue:time
                           withName:event
                          withLabel:label];
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
