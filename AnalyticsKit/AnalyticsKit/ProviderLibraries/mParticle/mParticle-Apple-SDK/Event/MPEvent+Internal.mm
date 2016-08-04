//
//  MPEvent+Internal.m
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

#import "MPEvent+Internal.h"
#import "MPIConstants.h"
#import "MPProduct.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPILogger.h"

NSString *const kMPEventCategoryKey = @"$Category";
NSString *const kMPAttrsEventLengthKey = @"EventLength";
NSString *const kMPEventCustomFlags = @"flags";

@implementation MPEvent(Internal)

#pragma mark Public methods
- (void)beginTiming {
    self.startTime = [NSDate date];
    self.duration = nil;
    
    if (self.endTime) {
        self.endTime = nil;
    }
}

- (NSDictionary *)breadcrumbDictionaryRepresentation {
    NSMutableDictionary *eventDictionary = [@{kMPLeaveBreadcrumbsKey:self.name,
                                              kMPEventStartTimestamp:MPCurrentEpochInMilliseconds}
                                            mutableCopy];
    
    if (self.info) {
        eventDictionary[kMPAttributesKey] = self.info;
    }
    
    return eventDictionary;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *eventDictionary = [@{kMPEventNameKey:self.name,
                                                              kMPEventTypeKey:self.typeName,
                                                              kMPEventCounterKey:@([MPStateMachine sharedInstance].currentSession.eventCounter)}
                                                            mutableCopy];
    
    NSDictionary *info = self.info;
    NSString *category = self.category;
    NSInteger numberOfItems = (info ? info.count : 0) + (category ? 1 : 0);
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:numberOfItems];
    
    if (self.duration) {
        eventDictionary[kMPEventLength] = self.duration;
        
        if (!info || info[kMPAttrsEventLengthKey] == nil) { // Does not override "EventLength" if it already exists
            attributes[kMPAttrsEventLengthKey] = self.duration;
        }
    } else {
        eventDictionary[kMPEventLength] = @0;
    }
    
    if (self.startTime) {
        eventDictionary[kMPEventStartTimestamp] = MPMilliseconds([self.startTime timeIntervalSince1970]);
    } else {
        eventDictionary[kMPEventStartTimestamp] = MPCurrentEpochInMilliseconds;
    }
    
    if (numberOfItems > 0) {
        if (info) {
            [attributes addEntriesFromDictionary:info];
        }
        
        if (category) {
            if (category.length <= LIMIT_NAME) {
                attributes[kMPEventCategoryKey] = category;
            } else {
                MPILogError(@"The event category is too long. Discarding category.");
            }
        }
    }
    
    if (attributes.count > 0) {
        eventDictionary[kMPAttributesKey] = attributes;
    }
    
    if (self.customFlags) {
        eventDictionary[kMPEventCustomFlags] = self.customFlags;
    }
    
    return eventDictionary;
}

- (void)endTiming {
    [self willChangeValueForKey:@"endTime"];
    
    if (self.startTime) {
        self.endTime = [NSDate date];
        
        NSTimeInterval secondsElapsed = [self.endTime timeIntervalSince1970] - [self.startTime timeIntervalSince1970];
        self.duration = MPMilliseconds(secondsElapsed);
    } else {
        self.duration = nil;
        self.endTime = nil;
    }
    
    [self didChangeValueForKey:@"endTime"];
}

- (NSDictionary *)screenDictionaryRepresentation {
    NSMutableDictionary *eventDictionary = [@{kMPEventNameKey:self.name,
                                              kMPEventStartTimestamp:MPCurrentEpochInMilliseconds}
                                            mutableCopy];
    
    if (self.duration) {
        eventDictionary[kMPEventLength] = self.duration;
    } else {
        eventDictionary[kMPEventLength] = @0;
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    if (self.info) {
        [attributes addEntriesFromDictionary:self.info];
    }

    if (self.duration && self.info[kMPAttrsEventLengthKey] == nil) { // Does not override "EventLength" if it already exists
        attributes[kMPAttrsEventLengthKey] = self.duration;
    }
    
    if (attributes.count > 0) {
        eventDictionary[kMPAttributesKey] = attributes;
    }
    
    if (self.customFlags) {
        eventDictionary[kMPEventCustomFlags] = self.customFlags;
    }
    
    return eventDictionary;
}

@end
