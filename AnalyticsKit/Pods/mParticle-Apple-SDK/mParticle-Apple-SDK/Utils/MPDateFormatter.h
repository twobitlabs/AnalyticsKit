#import <Foundation/Foundation.h>

@interface MPDateFormatter : NSObject

+ (nullable NSDate *)dateFromString:(nonnull NSString *)dateString;
+ (nullable NSDate *)dateFromStringRFC1123:(nonnull NSString *)dateString;
+ (nullable NSDate *)dateFromStringRFC3339:(nonnull NSString *)dateString;
+ (nullable NSString *)stringFromDateRFC1123:(nonnull NSDate *)date;
+ (nullable NSString *)stringFromDateRFC3339:(nonnull NSDate *)date;

@end
