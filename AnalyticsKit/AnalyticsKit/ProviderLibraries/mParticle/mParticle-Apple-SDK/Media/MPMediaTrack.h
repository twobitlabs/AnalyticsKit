//
//  MPMediaTrack.h
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

#import "MPEnums.h"

typedef NS_ENUM(NSUInteger, MPMediaTrackFormat) {
    /** Unknown media track format */
    MPMediaTrackFormatUnknown = 0,
    /** Audio media track */
    MPMediaTrackFormatAudio,
    /** Video media track */
    MPMediaTrackFormatVideo
};

typedef NS_ENUM(NSUInteger, MPMediaTrackQuality) {
    /** Unknown media track quality */
    MPMediaTrackQualityUnknown = 0,
    /** Low media track quality */
    MPMediaTrackQualityLow,
    /** Standard definition media track quality */
    MPMediaTrackQualityStandardDefinition,
    /** Medium definition media track quality */
    MPMediaTrackQualityMediumDefinition,
    /** High definition media track quality */
    MPMediaTrackQualityHighDefinition,
    /** Ultra high definition media track quality */
    MPMediaTrackQualityUltraHighDefinition
};


@interface MPMediaTrack : NSObject <NSCopying>

/**
 Contains HLS timed metadata used to log information. Internally this property is exactly the same as timedMetadata.
 This parameter accepts a NSString or a NSDictionary containing the "info" key with a corresponding value
 */
@property (nonatomic, strong, nullable) id id3;

/**
 Contains CMS metadata used to log information. This parameter accepts a NSDictionary
 or an instance of one of the MPMediaMetadata (Digital Audio, DPR, OCR, or TVR) classes.
 */
@property (nonatomic, strong, nullable) id metadata;

/**
 Contains HLS timed metadata used to log information (ID3). This parameter accepts a NSString or
 a NSDictionary containing the "info" key with a corresponding value.
 */
@property (nonatomic, strong, nullable) id timedMetadata;

/**
 Channel name of the media track. During initialization channel must be a valid string. It cannot be
 nil, NULL, NSNull, or empty string.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *channel;

/**
 Current playback position.
 */
@property (nonatomic, unsafe_unretained) Float64 playbackPosition;

/**
 Current playback rate
  0.0 = stop
  1.0 = playback at natural rate
 -1.5 = reverse playback at 1.5 the natural rate
 The value indicated the playback speed and the sign indicates which is the playback direction.
 */
@property (nonatomic, unsafe_unretained) double playbackRate;

/**
 Flag indicating whether the media track is currently playing or not. This
 flag gets set when you call the beginPlaying: method and
 gets reset when you call the endPlaying: method.
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL playing;

/**
 Specifies the media format between audio and video.
 @see MPMediaTrackFormat
 */
@property (nonatomic, unsafe_unretained) MPMediaTrackFormat format;

/**
 Specifies the quality of the media being consumed.
 @see MPMediaTrackQuality
 */
@property (nonatomic, unsafe_unretained) MPMediaTrackQuality quality;

/**
 Designated initializer.
 @param channel The media track channel
 @returns An instance of MPMediaTrack, or nil if the object could not be created or an invalid channel name was passed as parameter
 */
- (nullable instancetype)initWithChannel:(nonnull NSString *)channel;

@end
