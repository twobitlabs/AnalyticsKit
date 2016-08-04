//
//  MPDateFormatter.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPDateFormatter.h"
#import "MPIConstants.h"

static NSDateFormatter *dateFormatterRFC3339;
static NSDateFormatter *dateFormatterRFC1123; // HTTP-date
static NSDateFormatter *dateFormatterRFC850;

@implementation MPDateFormatter

+ (void)initialize {
    dateFormatterRFC3339 = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatterRFC3339 setLocale:enUSPOSIXLocale];
    [dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    [dateFormatterRFC3339 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    dateFormatterRFC1123 = [[NSDateFormatter alloc] init];
    dateFormatterRFC1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatterRFC1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    dateFormatterRFC1123.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss z";
    
    dateFormatterRFC850 = [[NSDateFormatter alloc] init];
    dateFormatterRFC850.locale = dateFormatterRFC1123.locale;
    dateFormatterRFC850.timeZone = dateFormatterRFC1123.timeZone;
    dateFormatterRFC850.dateFormat = @"EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z";
}

#pragma mark Public static methods
+ (NSDate *)dateFromString:(NSString *)dateString {
    if (MPIsNull(dateString)) {
        return nil;
    }
    
    NSDate *date = [dateFormatterRFC3339 dateFromString:dateString];
    if (date) {
        return date;
    }
    
    date = [dateFormatterRFC1123 dateFromString:dateString];
    if (date) {
        return date;
    }
    
    date = [dateFormatterRFC850 dateFromString:dateString];
    
    return date;
}

+ (NSDate *)dateFromStringRFC3339:(NSString *)dateString {
    if (MPIsNull(dateString)) {
        return nil;
    }
    
    NSDate *date = [dateFormatterRFC3339 dateFromString:dateString];
    return date;
}

+ (NSDate *)dateFromStringRFC1123:(NSString *)dateString {
    if (MPIsNull(dateString)) {
        return nil;
    }
    
    NSDate *date = [dateFormatterRFC1123 dateFromString:dateString];
    return date;
}

+ (NSString *)stringFromDateRFC1123:(NSDate *)date {
    if (MPIsNull(date)) {
        return nil;
    }
    
    NSString *dateString = [dateFormatterRFC1123 stringFromDate:date];
    return dateString;
}

+ (NSString *)stringFromDateRFC3339:(NSDate *)date {
    if (MPIsNull(date)) {
        return nil;
    }
    
    NSString *dateString = [dateFormatterRFC3339 stringFromDate:date];
    return dateString;
}

@end
