//
//  MPMediaTrack+Internal.m
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

#import "MPMediaTrack+Internal.h"
#import "MPIConstants.h"
#import "EventTypeName.h"

NSString *const MPMediaTrackChannelKey = @"chn";
NSString *const MPMediaTrackMetadataKey = @"mtd";
NSString *const MPMediaTrackTimedMetadataKey = @"tmtd";
NSString *const MPMediaTrackPlaybackPositionKey = @"plp";
NSString *const MPMediaTrackFormatKey = @"mtf";
NSString *const MPMediaTrackQualityKey = @"mtq";
NSString *const MPMediaTrackMediaInfoKey = @"mi";

@implementation MPMediaTrack (Internal)

- (NSDictionary *)dictionaryRepresentationWithEventName:(NSString *)eventName action:(NSString *)action {
    NSMutableDictionary *mediaTrackDictionary = [[NSMutableDictionary alloc] initWithCapacity:8];
    mediaTrackDictionary[MPMediaTrackChannelKey] = self.channel;
    mediaTrackDictionary[MPMediaTrackPlaybackPositionKey] = MPMilliseconds(self.playbackPosition);
    mediaTrackDictionary[MPMediaTrackFormatKey] = @(self.format);
    mediaTrackDictionary[MPMediaTrackQualityKey] = @(self.quality);
    mediaTrackDictionary[MPMediaTrackPlaybackRateKey] = @(self.playbackRate);
    mediaTrackDictionary[MPMediaTrackActionKey] = action;

    if (self.metadata) {
        mediaTrackDictionary[MPMediaTrackMetadataKey] = self.metadata;
    }
    
    if (self.timedMetadata) {
        mediaTrackDictionary[MPMediaTrackTimedMetadataKey] = self.timedMetadata;
    }
    
    NSString *eventType = [NSString stringWithCString:mParticle::EventTypeName::nameForEventType(mParticle::EventType::Media).c_str()
                                             encoding:NSUTF8StringEncoding];
    
    NSDictionary *mediaInfo = @{MPMediaTrackMediaInfoKey:mediaTrackDictionary,
                                kMPEventNameKey:eventName,
                                kMPEventTypeKey:eventType};
    
    return mediaInfo;
}

@end
