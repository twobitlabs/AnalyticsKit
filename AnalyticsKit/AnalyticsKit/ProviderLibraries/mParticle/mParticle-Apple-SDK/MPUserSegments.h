//
//  MPUserSegments.h
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

