//
//  MPMediaMetadataTVR.h
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

#import "MPMediaMetadataBase.h"

/**
 This is a convenience class to be used in conjuction with MPMediaTrack. When setting the MPMediaTrack.metadata property.
 You can pass an instance of a dictionary with your own key/value pairs, or you can pass an instance of 
 MPMediaMetadataTVR, which internally builds a dictionary for you with the values passed to the setters. Additionally 
 you can set/get your own arbritary key/value pairs using the subscripting operator [] as you would have done with an
 instance of NSMutableDictionary.
 */
@interface MPMediaMetadataTVR : MPMediaMetadataBase <NSCopying>

/**
 Identifier to add model used by the station.
 0 – Default: Crediting is based on ad model break-out from the ID3 tag
 1 – Linear: Content will have the same linear ads
 2 – Dynamic: Content will have ads dynamically served and not the same as linear ads
 */
@property (nonatomic, unsafe_unretained) NSUInteger adModel;

/**
 Returns an array with all keys in the dictionary
 @returns An array with all dictionary keys
 */
- (NSArray *)allKeys;

/**
 Number of entries in the dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (id)objectForKeyedSubscript:(NSString *const)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end
