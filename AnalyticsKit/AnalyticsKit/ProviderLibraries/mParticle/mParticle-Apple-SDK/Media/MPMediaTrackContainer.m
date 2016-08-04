//
//  MPMediaTrackContainer.m
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

#import "MPMediaTrackContainer.h"
#import "MPMediaTrack.h"

@interface MPMediaTrackContainer() {
    NSMutableSet<MPMediaTrack *> *trackSet;
    __weak MPMediaTrack *mostRecentMediaTrack;
}

@end


@implementation MPMediaTrackContainer

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (capacity < 1) {
        capacity = 1;
    }
    trackSet = [[NSMutableSet alloc] initWithCapacity:capacity];
    
    return self;
}

#pragma mark Public accessors
- (NSUInteger)count {
    return trackSet.count;
}
    
#pragma mark Public methods
- (void)addTrack:(MPMediaTrack *)mediaTrack {
    if (!mediaTrack) {
        return;
    }
    
    [trackSet addObject:mediaTrack];
    mostRecentMediaTrack = mediaTrack;
}

- (NSArray<MPMediaTrack *> *)allMediaTracks {
    NSArray *allMediaTracks = [trackSet allObjects];
    if (allMediaTracks.count == 0) {
        allMediaTracks = nil;
    }
    
    return allMediaTracks;
}

- (BOOL)containsTrack:(MPMediaTrack *)mediaTrack {
    if (!mediaTrack) {
        return NO;
    }
    
    BOOL containsTrack = [self trackWithChannel:mediaTrack.channel] != nil;
    return containsTrack;
}

- (BOOL)containsTrackWithChannel:(NSString *)channel {
    BOOL containsTrack = [self trackWithChannel:channel] != nil;
    return containsTrack;
}

- (void)pruneMediaTracks {
    if (mostRecentMediaTrack == nil || trackSet.count == 0) {
        return;
    }
    
    NSMutableSet *pruneTracks = [[NSMutableSet alloc] initWithCapacity:trackSet.count];
    for (MPMediaTrack *mediaTrack in trackSet) {
        if ([mediaTrack isEqual:mostRecentMediaTrack]) {
            continue;
        }
        
        [pruneTracks addObject:mediaTrack];
    }
    
    if (pruneTracks.count > 0) {
        [trackSet minusSet:pruneTracks];
    }
}

- (MPMediaTrack *)trackWithChannel:(NSString *)channel {
    if (!channel) {
        return nil;
    }
    
    MPMediaTrack *foundMediaTrack = nil;
    for (MPMediaTrack *mediaTrack in trackSet) {
        if ([mediaTrack.channel isEqualToString:channel]) {
            foundMediaTrack = mediaTrack;
            mostRecentMediaTrack = mediaTrack;
            break;
        }
    }
    
    return foundMediaTrack;
}

- (void)removeTrack:(MPMediaTrack *)mediaTrack {
    if (!mediaTrack) {
        return;
    }
    
    if ([trackSet containsObject:mediaTrack]) {
        if ([mostRecentMediaTrack isEqual:mediaTrack]) {
            mostRecentMediaTrack = nil;
        }
        
        [trackSet removeObject:mediaTrack];
    }
}

- (void)removeTrackWithChannel:(NSString *)channel {
    MPMediaTrack *mediaTrack = [self trackWithChannel:channel];
    [self removeTrack:mediaTrack];
}

@end
