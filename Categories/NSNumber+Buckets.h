//
//  NSNumber+Buckets.h
//  AnalyticsKit
//
//  Author: Jonathan Hersh (jon@her.sh)
//

#import <Foundation/Foundation.h>

@interface NSNumber (Buckets)

/*
 * Many analytics services (*cough* Localytics *cough) do not bucket your values for you,
 * so your reported numeric data can be awfully difficult to read.
 * These bucketing functions will read in a number and output a bucketed range as a string.
 * 
 * Example: A value of 47, with bucket size 25, will return the string "25-49".
 * A value of 10, with bucket size 15, will return the string "< 15".
 */
- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize;

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize 
                               maxBuckets:(NSUInteger)maxBuckets;

@end
