//
//  AnalyticsKitGoogleAnalyticsProvider.m
//  S2M
//
//  Created by François Benaiteau on 02/14//13.
//

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
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


@interface AnalyticsKitGoogleAnalyticsProvider () {
    id _tracker;
}

-(id)valueFromDictionnary:(NSDictionary*)dictionnary forKey:(NSString*)key;
@end


@implementation AnalyticsKitGoogleAnalyticsProvider

#if !__has_feature(objc_arc)
-(void)dealloc
{
    dispatch_release(timingQueue);
    [timedEvents release];
    [super dealloc];
}
#endif

-(id<AnalyticsKitProvider>)initWithTrackingID:(NSString *)trackingID
{
    self = [super init];
    if (self) {
        _tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingID];
        timedEvents = [[NSMutableDictionary alloc] init];
        timingQueue = dispatch_queue_create("analyticsKit.goolgeAnalytics.provider", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// Lifecycle
-(void)applicationWillEnterForeground{}

-(void)applicationDidEnterBackground{}

-(void)applicationWillTerminate{
    if ([_tracker respondsToSelector:@selector(close)]) {
    [_tracker close];
    }
}

-(void)uncaughtException:(NSException *)exception
{
    [_tracker send:[[GAIDictionaryBuilder
                    createExceptionWithDescription:[[exception userInfo] description]
                    withFatal:@(YES)] build]];
}


//Logging events
-(void)logScreen:(NSString *)screenName
{
    [_tracker set:kGAIScreenName
           value:screenName];
    
    [_tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

-(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:screenName];
    
    [_tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

-(void)logScreen:(NSString *)screenName timed:(BOOL)timed
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:screenName];
    
    [_tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

-(void)logScreen:(NSString *)screenName withProperties:(NSDictionary *)dict timed:(BOOL)timed
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:screenName];
    
    [_tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

-(void) endTimedScreen:(NSString *)screenName withProperties:(NSDictionary *)dict
{
    
}

-(void)logEvent:(NSString *)event
{
    [_tracker send:[[GAIDictionaryBuilder createEventWithCategory:nil
                                                          action:event
                                                           label:nil
                                                           value:nil] build]];
}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value
{
    [_tracker send:[[GAIDictionaryBuilder createEventWithCategory:key
                                                      action:event
                                                       label:value
                                                       value:nil] build]];
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict
{
    NSString* category = [self valueFromDictionnary:dict forKey:kCategory];
    NSString* label = [self valueFromDictionnary:dict forKey:kLabel];
    NSNumber* value = [self valueFromDictionnary:dict forKey:kValue];
    
    [_tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:event
                                                           label:label
                                                           value:value] build]];
}

-(void)logEvent:(NSString *)event timed:(BOOL)timed
{
    if (!timed) {
        [self logEvent:event];
    } else {
        dispatch_sync(timingQueue, ^{
                          timedEvents[event] = [NSDate date];
                      });
    }    
}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict timed:(BOOL)timed
{
    if (!timed) {
        [self logEvent:event withProperties:dict];
    } else {
        __block NSDictionary* properties = dict;
        dispatch_sync(timingQueue, ^{
            if (properties == nil) {
                properties = @{};
            }
            timedEvents[event] = @{kTime : [NSDate date],
                                   kProperties: properties};
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

    [_tracker send:[[GAIDictionaryBuilder createTimingWithCategory:category
                                                         interval:@(time)
                                                             name:event
                                                            label:label] build]];
#if !__has_feature(objc_arc)
    [properties release];
#endif

}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception
{
    // isFatal = NO, presume here, Exeption is not fatal.
    [_tracker send:[[GAIDictionaryBuilder
                    createExceptionWithDescription:message
                    withFatal:@(NO)] build]];

}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error
{
    // isFatal = NO, presume here, Exeption is not fatal.
    [_tracker send:[[GAIDictionaryBuilder
                    createExceptionWithDescription:message
                    withFatal:@(NO)] build]];
}

#pragma mark - Extra methods

-(void)enableDebug:(BOOL)enabled
{
    [[GAI sharedInstance] setDryRun:enabled];
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
