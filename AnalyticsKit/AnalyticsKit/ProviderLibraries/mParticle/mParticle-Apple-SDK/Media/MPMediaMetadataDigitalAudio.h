//
//  MPMediaMetadataDigitalAudio.h
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

typedef NS_ENUM(NSUInteger, MPMediaStationType) {
    /** Custom station built per user */
    MPMediaStationTypeCustomStation = 0,
    /** OTA streaming station with same ad load */
    MPMediaStationTypeOTASameAdLoad,
    /** OTA station with different ad load */
    MPMediaStationTypeOTADifferentAdLoad,
    /** eRadio or online station */
    MPMediaStationTypeERadio,
    /** On Demand Audio (Podcasting) */
    MPMediaStationTypeOnDemand
};

/**
 This is a convenience class to be used in conjuction with MPMediaTrack. When setting the MPMediaTrack.metadata
 property you can pass an instance of a dictionary with your own key/value pairs, or you can pass an instance of
 MPMediaMetadataOCR, which internally builds a dictionary for you with the values passed to the setters.
 Additionally you can set/get your own arbritary key/value pairs using the subscripting operator [] as you would
 have done with an instance of NSMutableDictionary.
 */
@interface MPMediaMetadataDigitalAudio : MPMediaMetadataBase <NSCopying>

/**
 Station identifier. Should include Call letters and Band
 */
@property (nonatomic, strong, nonnull) NSString *assetId;

/**
 Source of the data. Set as "cms" for Digital Audio
 */
@property (nonatomic, strong, readonly, nonnull) NSString *dataSource;

/**
 Name of the provider
 */
@property (nonatomic, strong, nullable) NSString *provider;

/**
 Station type.
 @see MPMediaStationType
 */
@property (nonatomic, unsafe_unretained) MPMediaStationType stationType;

/**
 Type of content. Set as "radio" for Digital Audio
 */
@property (nonatomic, strong, readonly, nonnull) NSString *type;

/**
 Designated initialiser.
 @param assetId Station identifier. Should include Call letters and Band
 @param provider Name of the provider
 @param stationType Station type (see MPMediaStationType)
 @returns An instance of MPMediaMetadataDigitalAudio, or nil if it could not be created
 */
- (nonnull instancetype)initWithAssetId:(nullable NSString *)assetId provider:(nullable NSString *)provider stationType:(MPMediaStationType)stationType __attribute__((objc_designated_initializer));

/**
 Returns an array with all keys in the dictionary
 @returns An array with all dictionary keys
 */
- (nullable NSArray *)allKeys;

/**
 Number of entries in the dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nonnull id)obj forKeyedSubscript:(nonnull NSString *)key;

@end
