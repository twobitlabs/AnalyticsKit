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

// Constants for timedEvents structure
static NSString* const kTime = @"time";
static NSString* const kProperties = @"properties";


@interface AnalyticsKitGoogleAnalyticsProvider ()

-(id)valueFromDictionnary:(NSDictionary*)dictionnary forKey:(NSString*)key;
@end


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
    NSString* category = [self valueFromDictionnary:dict forKey:kCategory];
    NSString* label = [self valueFromDictionnary:dict forKey:kLabel];
    NSNumber* value = [self valueFromDictionnary:dict forKey:kValue];
    
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
    if (!timed) {
        [self logEvent:event withProperties:dict];
    }else{
        dispatch_sync(timingQueue, ^{
            timedEvents[event] = @{kTime : [NSDate date],
                                   kProperties: dict};
        });
    }
    
}
-(void)endTimedEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    NSMutableDictionary* properties =  [[NSMutableDictionary alloc] initWithDictionary:dict];
    NSDate* startDate;
    id timeEvent = timedEvents[event];

    // merging properties from started event with given properties if necessary
    if ([timeEvent isKindOfClass:[NSDictionary class]]) {
        [properties addEntriesFromDictionary:timeEvent[kProperties]];
        startDate = timeEvent[kTime];
    }else{
        startDate = timeEvent;
    }
    
    NSString* category = [self valueFromDictionnary:properties forKey:kCategory];
    NSString* label = [self valueFromDictionnary:properties forKey:kLabel];

    __block NSTimeInterval time;
    dispatch_sync(timingQueue, ^{
        // calculating the elapsed time
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
#if !__has_feature(objc_arc)
    [properties release];
#endif

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

#pragma mark - Private methods

-(id)valueFromDictionnary:(NSDictionary*)dictionnary forKey:(NSString*)key
{
    if (dictionnary[key.lowercaseString]) {
        return dictionnary[key.lowercaseString];
    }

    if (dictionnary[key]) {
        return dictionnary[key];
    }
    return nil;
}
@end
