//
//  LocalyticsUtil.h
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.

#import <Foundation/Foundation.h>

#define LOCALYTICS_LOGGING_ENABLED [LocalyticsUtil loggingEnabled]
#define LocalyticsLog(message, ...)if([LocalyticsUtil loggingEnabled]) \
[LocalyticsUtil logMessage:[NSString stringWithFormat:@"%s:\n + " message "\n\n", __PRETTY_FUNCTION__, ##__VA_ARGS__]]

@interface LocalyticsUtil : NSObject

+ (void)logMessage:(NSString *)message;
+ (void)setLoggingEnabled:(BOOL)enabled;
+ (BOOL)loggingEnabled;
+ (void)setAdvertisingIdentifierEnabled:(BOOL)enabled;
+ (BOOL)advertisingIdentifierEnabled;
+ (NSString *)valueFromQueryStringKey:(NSString *)queryStringKey url:(NSURL *)url;

@end
