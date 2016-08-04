//
//  MPMediaMetadataBase.m
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
#import "MPMediaMetadataProtocol.h"

@interface MPMediaMetadataBase() <MPMediaMetadataProtocol>

@end


@implementation MPMediaMetadataBase

@synthesize objectDictionary = _objectDictionary;

#pragma mark MPMediaMetadataProtocol
- (NSDictionary *)dictionaryRepresentation {
    return (NSDictionary *)self.objectDictionary;
}

- (NSMutableDictionary *)objectDictionary {
    if (_objectDictionary) {
        return _objectDictionary;
    }
    
    _objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    return _objectDictionary;
}

#pragma mark Public methods
- (id)objectForKeyedSubscript:(NSString *const)key {
    id object = [self.objectDictionary objectForKey:key];
    return object;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    [self.objectDictionary setObject:obj forKey:key];
}

- (NSArray *)allKeys {
    return [self.objectDictionary allKeys];
}

- (NSUInteger)count {
    return [self.objectDictionary count];
}

@end
