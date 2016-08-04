//
//  MPMediaTrack.m
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

#import "MPMediaTrack.h"
#import "MPMediaMetadataBase.h"
#import "MPMediaMetadataDigitalAudio.h"
#import "MPMediaMetadataDPR.h"
#import "MPMediaMetadataOCR.h"
#import "MPMediaMetadataTVR.h"
#import "MPIConstants.h"

@implementation MPMediaTrack

- (instancetype)initWithChannel:(NSString *)channel {
    NSAssert(channel != nil && channel.length > 0 && (NSNull *)channel != [NSNull null], @"channel cannot be nil or empty.");
    
    self = [super init];
    if (!self ||  MPIsNull(channel)) {
        return nil;
    }
    
    _channel = channel;
    _playbackPosition = 0.0;
    _playbackRate = 0.0;
    _playing = NO;
    _format = MPMediaTrackFormatUnknown;
    _quality = MPMediaTrackQualityUnknown;
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Media Track\n Channel: %@\n Playback Position: %.2f\n Metadata: %@\n Timed metadata: %@\n Playing: %@\n Playback rate: %.2f\n", self.channel, self.playbackPosition, self.metadata, self.timedMetadata, (_playing ? @"YES" : @"NO"), self.playbackRate];
}

- (BOOL)isEqual:(MPMediaTrack *)object {
    BOOL isEqual = [_channel isEqualToString:object.channel];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMediaTrack *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject.metadata = [_metadata copy];
        copyObject.timedMetadata = [_timedMetadata copy];
        copyObject->_channel = [_channel copy];
        copyObject.playbackPosition = _playbackPosition;
        copyObject.playbackRate = _playbackRate;
        copyObject.playing = _playing;
        copyObject.format = _format;
        copyObject.quality = _quality;
    }
    
    return copyObject;
}

- (void)setPlaying:(BOOL)playing {
    if (_playing == playing) {
        return;
    }
    
    _playing = playing;
}

#pragma mark Public accessors
- (id)id3 {
    return _timedMetadata;
}

- (void)setId3:(id)id3 {
    self.timedMetadata = id3;
}

- (void)setPlaybackRate:(double)playbackRate {
    if (_playbackRate == playbackRate) {
        return;
    }
    
    [self willChangeValueForKey:@"playbackRate"];
    [self willChangeValueForKey:@"playing"];
    
    _playbackRate = playbackRate;
    _playing = playbackRate != 0.0;
    
    [self didChangeValueForKey:@"playing"];
    [self didChangeValueForKey:@"playbackRate"];
}

- (void)setMetadata:(id)metadata {
    if ([metadata isKindOfClass:[MPMediaMetadataBase class]]) {
        [self willChangeValueForKey:@"metadata"];
        _metadata = [metadata dictionaryRepresentation];
        [self didChangeValueForKey:@"metadata"];
    } else if ([metadata isKindOfClass:[NSDictionary class]]) {
        [self willChangeValueForKey:@"metadata"];
        _metadata = metadata;
        [self didChangeValueForKey:@"metadata"];
    }
}

- (void)setTimedMetadata:(id)timedMetadata {
    if ([timedMetadata isKindOfClass:[NSString class]]) {
        [self willChangeValueForKey:@"timedMetadata"];
        _timedMetadata = (NSString *)timedMetadata;
        [self didChangeValueForKey:@"timedMetadata"];
    } else if ([timedMetadata isKindOfClass:[NSDictionary class]]) {
        [self willChangeValueForKey:@"timedMetadata"];
        _timedMetadata = ((NSDictionary *)timedMetadata)[@"info"];
        [self didChangeValueForKey:@"timedMetadata"];
    }
}

@end
