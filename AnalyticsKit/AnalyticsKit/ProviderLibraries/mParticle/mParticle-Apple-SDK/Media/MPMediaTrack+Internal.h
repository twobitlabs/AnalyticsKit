//
//  MPMediaTrack+Internal.h
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

typedef NS_ENUM(NSUInteger, MPMediaAction) {
    MPMediaActionPlay = 1,
    MPMediaActionStop,
    MPMediaActionPlaybackPosition,
    MPMediaActionMetadata
};

extern NSString *const MPMediaTrackChannelKey;
extern NSString *const MPMediaTrackMetadataKey;
extern NSString *const MPMediaTrackTimedMetadataKey;
extern NSString *const MPMediaTrackPlaybackPositionKey;
extern NSString *const MPMediaTrackFormatKey;
extern NSString *const MPMediaTrackQualityKey;
extern NSString *const MPMediaTrackMediaInfoKey;

@interface MPMediaTrack(Internal)

- (NSDictionary *)dictionaryRepresentationWithEventName:(NSString *)eventName action:(NSString *)action;

@end
