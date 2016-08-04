//
//  MPUserSegments.m
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

#import "MPUserSegments.h"
#import "MPSegment.h"
#import "MPUserSegments+Setters.h"
#import "MPDateFormatter.h"

@implementation MPUserSegments

- (NSString *)description {
    return [NSString stringWithFormat:@"MPUserSegments\n Ids: %@\n Expiration: %@", [self commaSeparatedSegments], [MPDateFormatter stringFromDateRFC3339:self.expiration]];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPUserSegments *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_segmentsIds = [_segmentsIds copy];
        copyObject->_expiration = [_expiration copy];
    }
    
    return copyObject;
}

#pragma mark Public Accessors
- (BOOL)expired {
    if (self.segmentsIds && !self.expiration) {
        return NO;
    }
    
    NSDate *now = [NSDate date];
    BOOL expired = [now compare:self.expiration] == NSOrderedDescending;
    return expired;
}

- (NSString *)commaSeparatedSegments {
    return [self.segmentsIds componentsJoinedByString:@","];
}

@end

#pragma mark MPUserSegments+Setters category
@implementation MPUserSegments(Setters)

- (nonnull instancetype)initWithSegments:(nullable NSArray<MPSegment *> *)segments {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSMutableArray *segmentsIds = [[NSMutableArray alloc] initWithCapacity:segments.count];
    for (MPSegment *segment in segments) {
        [segmentsIds addObject:segment.segmentId];
        
        if (!_expiration || [segment.expiration compare:_expiration] == NSOrderedAscending) {
            _expiration = segment.expiration;
        }
    }
    
    _segmentsIds = [segmentsIds copy];
    
    return self;
}

@end
