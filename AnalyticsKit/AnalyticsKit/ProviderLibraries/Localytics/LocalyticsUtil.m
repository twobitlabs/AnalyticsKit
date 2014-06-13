//
//  LocalyticsUtil.m
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.

#import "LocalyticsUtil.h"

static BOOL isLoggingEnabled = NO;
static BOOL isAdvertisingIdentifierEnabled = YES;

@implementation LocalyticsUtil

/*!
 @method logMessage
 @abstract Logs a message with (localytics) prepended to it.
 @param message The message to log
 */
+ (void)logMessage:(NSString *)message
{
	NSLog(@"\n(localytics) %@", message);
}

+ (void)setLoggingEnabled:(BOOL)enabled
{
    isLoggingEnabled = enabled;
}

+ (BOOL)loggingEnabled
{
    return isLoggingEnabled;
}

+ (void)setAdvertisingIdentifierEnabled:(BOOL)enabled
{
	isAdvertisingIdentifierEnabled = enabled;
}

+ (BOOL)advertisingIdentifierEnabled
{
	return isAdvertisingIdentifierEnabled;
}

+ (NSString *)valueFromQueryStringKey:(NSString *)queryStringKey url:(NSURL *)url
{
    if (!queryStringKey.length || !url.query)
        return nil;
	
    NSArray *urlComponents = [url.query componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *keyValuePairComponents = [keyValuePair componentsSeparatedByString:@"="];
        if ([[keyValuePairComponents objectAtIndex:0] isEqualToString:queryStringKey])
        {
            if(keyValuePairComponents.count == 2)
                return [[keyValuePairComponents objectAtIndex:1]
                        stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return nil;
}

@end
