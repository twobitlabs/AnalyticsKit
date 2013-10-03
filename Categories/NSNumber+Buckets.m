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
        return [NSString stringWithFormat:@"< %i", bucketSize];

    NSUInteger multiple = intVal / bucketSize;

    if( multiple >= maxBuckets )
        return [NSString stringWithFormat:@">= %i", ( bucketSize * maxBuckets )];
    
    return [NSString stringWithFormat:@"%i - %i",
		    ( multiple * bucketSize ),
		    ( ( ( multiple + 1 ) * bucketSize ) - 1)];
}

@end
