//
//  CSComScore.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSTransmissionMode.h"

#define kComScoreTrackingDisablePreferenceKey @"comScore-TrackingDisabledPreferenceKey"

@class CSCensus;
@class CSCore;

@interface CSComScore : NSObject {

}

/**
 Returns the internal instance.
 */
+ (CSCore *)core;

/**
 Makes sure the internal instance is created
 */
+ (void)setAppContext;

/**
 Returns CSCensus instance.
 */
+ (CSCensus *)census;


/**
 Notify Application event Start
 */
+ (void)start;


/**
 Notify Application event Start with custom labels
 
 Parameters:
 
 - labels: A NSDictionary that contains the custom labels
 */
+ (void)startWithLabels:(NSDictionary *)labels;


/**
 Notify Application event View
 */
+ (void)view;

/**
 Notify Application event View with custom labels
 
 Parameters:
 
 - labels: A NSDictionary that contains the custom labels
 */
+ (void)viewWithLabels:(NSDictionary *)labels;

/**
 Notify Application event Hidden
 */
+ (void)hidden;

/**
 Notify Application event Hidden with custom labels
 
 Parameters:
 
 - labels: A NSDictionary that contains the custom labels
 */
+ (void)hiddenWithLabels:(NSDictionary *)labels;


/**
 Notify Application event Aggregate with custom labels
 
 Parameters:
 
 - labels: A NSDictionary that contains the custom labels
 */
+ (void)aggregateWithLabels:(NSDictionary *)labels;

/**
 Returns the pixel url
 */
+ (NSString *)pixelURL;

/**
 Sets a new pixel url
 
 Parameters:
 
 - pixelURL: A NSString that contains the new pixel url
 */
+ (NSString *)setPixelURL:(NSString *)pixelURL;

/**
 Returns the customer c2
 */
+ (NSString *)customerC2;

/**
 Sets a new customer c2
 
 Parameters:
 
 - customerC2: A NSString that contains the new customer c2
 */
+ (void)setCustomerC2:(NSString *)c2;

/**
 Returns the app name
 */
+ (NSString *)appName;

/**
 Sets a new app name
 
 Parameters:
 
 - appName: A NSString that contains the new app name
 */
+ (void)setAppName:(NSString *)appName;

/**
 Returns the current device model
 */
+ (NSString *)devModel;

/**
 Returns the time in that the current instance was created
 */
+ (long long)genesis;

+ (long long)previousGenesis;

/**
 Returns the dictionary with the custom labels
 */
+ (NSMutableDictionary *)labels;

/**
 Returns the publisher secret
 */
+ (NSString *)publisherSecret;

/**
 Sets a new publisher secret
 
 Parameters:
 
 - publisherSecret: A NSString that contains the new publisher secret
 */
+ (void)setPublisherSecret:(NSString *)publisherSecret;

/**
 Returns the visitor ID
 */
+ (NSString *)visitorID;

/**
 Sets a new publisher secret
 
 Parameters:
 
 - publisherSecret: A NSString that contains the new publisher secret
 */
+ (void)setVisitorID:(NSString *)visitorID;

/**
 Sends all the cached offline measurements if any
 */
+ (void)flushCache;

/**
 Sets a persitent custom label that will be sent in every measurement
 
 Parameters:
 
 - name: A String with the name of the label to set
 - value: A String with the value of the label to set
 */
+ (void)setLabel:(NSString *)name value:(NSString *)value;

/**
 Adds to the persistent custom labels dictionary all the labels from a dictionary
 
 Parameters:
 
 - labels: A Dictionary with labels
 */
+ (void)setLabels:(NSDictionary *)labels;

/**
 Returns the persistent labels dictionary
 */
+ (NSString *)label:(NSString *)labelName;


/**
 Sets a auto start label that will be sent in every measurement
 
 Parameters:
 
 - name: A String with the name of the label to set
 - value: A String with the value of the label to set
 */
+ (void)setAutoStartLabel:(NSString *)name value:(NSString *)value;

/**
 Adds to the auto start labels dictionary all the labels from a dictionary
 
 Parameters:
 
 - labels: A Dictionary with labels
 */
+ (void)setAutoStartLabels:(NSDictionary *)labels;

/**
 Returns the auto start labels dictionary
 */
+ (NSString *)autoStartLabel:(NSString *)labelName;

/**
 Returns if the keep alive is enabled
 */
+ (BOOL)isKeepAliveEnabled;

/**
 Allows to enable/disable the keep alive
 */
+ (void)setKeepAliveEnabled:(BOOL)enabled;

/**
 This mode will add use https for the automatically
 generated pixelURL
 
 Parameters:
 
 - publisherSecret: A BOOl indicating if secure is enabled.
 */
+ (void)setSecure:(BOOL)secure;

/**
 * Returns if the secure mode is enabled
 */
+ (BOOL)isSecure;

/**
 Enables or disables live events (GETs) dispatched one by one when connectivity is available
 */
+ (void)allowLiveTransmission:(CSTransmissionMode)mode;

/**
 Enables or disables automatic offline cache flushes (POSTS). The cache can always be manually
 flushed using the public api comScore.FlushOfflineCache()
 */
+ (void)allowOfflineTransmission:(CSTransmissionMode)mode;

/**
 Returns the live transmission mode
 */
+ (CSTransmissionMode)liveTransmissionMode;

/**
 Returns the offline transmission mode
 */
+ (CSTransmissionMode)offlineTransmissionMode;

/**
 Returns the cross publisher id
 */
+ (NSString *)crossPublisherId;

/**
 * Returns to specify the order in which labels will be present in the dispatched measurement.
 */
+ (NSArray *)measurementLabelOrder;

/**
 Disables auto update. This feature updates periodically the accumulated background times.
 */
+ (void)disableAutoUpdate;

/**
 Enables auto update. This feature updates periodically the accumulated background times.
 */
+ (void)enableAutoUpdate:(int)intervalInSeconds foregroundOnly:(BOOL)foregroundOnly;

/**
 Returns the number of cold starts.
 */
+ (int)coldStartCount;

/**
 Returns the cold start id
 */
+ (long long)coldStartId;

/**
 Returns the current application version
 */
+ (NSString *)currentVersion;

/**
 Returns the previous application version
 */
+ (long long)firstInstallId;

/**
 Returns the install id
 */
+ (long long)installId;

/**
 Returns the number of times the application was run
 */
+ (int)runsCount;

/**
 Returns is auto update is enabled. This feature updates periodically the accumulated background times.
 */
+ (BOOL)autoStartEnabled;

/**
 Informs that the application entered foreground.
 */
+ (void)onEnterForeground;

/**
 Informs that the application left foreground.
 */
+ (void)onExitForeground;

/**
 * Informs that user performed an interaction with application.
 */
+ (void)onUserInteraction;

/**
 * Informs that the application is providing some content to the user (playing music in the background, playing a movie etc.)
 */
+ (void)onUxActive;

/**
 * Informs that the application is no longer providing content to the user.
 */
+ (void)onUxInactive;

/**
 * Allows to specify the order in which labels will be present in the dispatched measurement.
 */
+ (void)setMeasurementLabelOrder:(NSArray *)ordering;

/**
 Accumulates the current timer registers, so the data won't be lost on crash.
 Triggers IO operations in a separate thread so please use it wisely.
 */
+ (void)update;

/**
 Returns true if the device is jailbroke
 */
+ (BOOL)isJailbroken;

/**
 Returns the current SDK version
 */
+ (NSString *)version;

/**
 Sets the maximum amount of measurements that can be cached.
 */
+ (void)setCacheMaxSize:(int)maxSize;

/**
 Returns the maximum amount of measurements that can be cached.
 */
+ (int)cacheMaxSize;

/**
 Sets the maximum amount of measurements can be cached in a single file.
 */
+ (void)setCacheMaxBatchSize:(int)maxBatchSize;

/**
 Returns the maximum amount of measurements can be cached in a single file.
 */
+ (int)cacheMaxBatchSize;

/**
 Sets the maximum amount flushes of cached measurements can be send in a row.
 */
+ (void)setCacheMaxFlushesInARow:(int)maxFlushesInARow;

/**
 Returns the maximum amount flushes of cached measurements can be send in a row.
 */
+ (int)cacheMaxFlushesInARow;

/**
 Sets the minimal time between cache flush retries, in case of failure.
 */
+ (void)setCacheMinutesToRetry:(int)minutesToRetry;

/**
 Returns the minimal time between cache flush retries, in case of failure.
 */
+ (int)cacheMinutesToRetry;

/**
 Sets the time after which the measurements in the cache should expire.
 */
+ (void)setCacheExpiryInDays:(int)expiricyInDays;

/**
 Returns the time after which the measurements in the cache should expire.
 */
+ (int)cacheExpiryInDays;

/**
 Returns the interval between automated cache flushes.
 */
+ (long)cacheFlushingInterval;

/**
 Sets the interval between automated cache flushes.
 */
+ (void)setCacheFlushingInterval:(long)seconds;

/**
 Enables error handling
 */
+ (void)setErrorHandlingEnabled:(BOOL)value;

/**
 Returns if error handling is enabled
 */
+ (BOOL)isErrorHandlingEnabled;

+ (void)setAutoStartEnabled:(BOOL)value;

/**
 Enable or disable the comScore log
 */
+ (void)setDebug:(BOOL)enable;

/** Blocks the thread until all previous tasks are finished
 *
 *  __Important:__ This call will block the thread. Use it only when necessary.
 */
+ (void)waitForTasks;

/**
 * Enables or disables tracking. When tracking is disabled, no measurement is sent and
 * no data is collected.
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 * Indicates if tracking is enabled. When tracking is disabled, no measurement is sent and
 * no data is collected.
 */
+ (BOOL)enabled;

/**
 * Sets the url for offline cache flushes.
 */
+ (void)setOfflineURL:(NSString *)value;


@end
