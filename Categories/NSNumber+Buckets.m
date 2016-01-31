//
//  NSNumber+Buckets.m
//  AnalyticsKit
//
//  Author: Jonathan Hersh (jon@her.sh)
//

#import "NSNumber+Buckets.h"

@implementation NSNumber (Buckets)

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize {
    return [self bucketStringWithBucketSize:bucketSize
                                 maxBuckets:10];
}

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize 
                               maxBuckets:(NSUInteger)maxBuckets {
						 
    NSUInteger intVal = [self unsignedIntegerValue];

    if( intVal < bucketSize )
        return [NSString stringWithFormat:@"< %lu", (unsigned long)bucketSize];

    NSUInteger multiple = intVal / bucketSize;

    if( multiple >= maxBuckets )
        return [NSString stringWithFormat:@">= %lu", (unsigned long)( bucketSize * maxBuckets )];
    
    return [NSString stringWithFormat:@"%lu - %lu",
		    (unsigned long)( multiple * bucketSize ),
		    (unsigned long)( ( ( multiple + 1 ) * bucketSize ) - 1)];
}

@end
