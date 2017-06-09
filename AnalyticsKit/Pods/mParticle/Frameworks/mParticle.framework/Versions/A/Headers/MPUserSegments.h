//
//  MPUserSegments.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

/**
 This class is returned as response from a user segments call. It contains segment ids, expiration, and a flag indicating whether it is expired.
 */
@interface MPUserSegments : NSObject <NSCopying>

/**
 The list of user segment ids
 */
@property (nonatomic, strong, readonly) NSArray *segmentsIds;

/**
 Contains the date the user segment will expire. If nil, it means the user segment doesn't expire
 */
@property (nonatomic, strong, readonly) NSDate *expiration;

/**
 Flag indicating whether the user segment is expired or not
 */
@property (nonatomic, readonly) BOOL expired;

/**
 Returns a string with a comma separated list of user segment ids. The same user segment ids in the segmentsIds property
 */
- (NSString *)commaSeparatedSegments;

@end

/**
 User Segments callback handler.
 
 @param userSegments An array of MPUserSegment objects
 @param error Contains nil or an error object
 */
typedef void(^MPUserSegmentsHandler)(MPUserSegments *userSegments, NSError *error);

