#import <Foundation/Foundation.h>

@class MPSegment;

/**
 This class is returned as response from a user segments call. It contains segment ids, expiration, and a flag indicating whether it is expired.
 */
@interface MPUserSegments : NSObject <NSCopying>

/**
 The list of user segment ids
 */
@property (nonatomic, strong, readonly, nullable) NSArray<MPSegment *> *segmentsIds;

/**
 Contains the date the user segment will expire. If nil, it means the user segment doesn't expire
 */
@property (nonatomic, strong, readonly, nullable) NSDate *expiration;

/**
 Flag indicating whether the user segment is expired or not
 */
@property (nonatomic, readonly) BOOL expired;

/**
 Returns a string with a comma separated list of user segment ids. The same user segment ids in the segmentsIds property
 */
- (nullable NSString *)commaSeparatedSegments;

@end

/**
 User Segments callback handler.
 
 @param userSegments An array of MPUserSegment objects
 @param error Contains nil or an error object
 */
typedef void(^MPUserSegmentsHandler)(MPUserSegments * _Nullable userSegments, NSError * _Nullable error);

