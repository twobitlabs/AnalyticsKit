//
//  NSUserDefaults+mParticle.m
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

#import "NSUserDefaults+mParticle.h"

static NSString *const NSUserDefaultsPrefix = @"mParticle::";

@implementation NSUserDefaults(mParticle)

#pragma mark Private methods
- (NSString *)prefixedKey:(NSString *)keyName {
    NSString *prefixedKey = [NSString stringWithFormat:@"%@%@", NSUserDefaultsPrefix, keyName];
    return prefixedKey;
}

#pragma mark Public methods
- (id)mpObjectForKey:(NSString *)defaultName {
    NSString *prefixedKey = [self prefixedKey:defaultName];
    return [self objectForKey:prefixedKey];
}

- (void)setMPObject:(id)value forKey:(NSString *)defaultName {
    NSString *prefixedKey = [self prefixedKey:defaultName];
    [self setObject:value forKey:prefixedKey];
}

- (void)removeMPObjectForKey:(NSString *)defaultName {
    NSString *prefixedKey = [self prefixedKey:defaultName];
    [self removeObjectForKey:prefixedKey];
}

#pragma mark Objective-C Literals
- (id)objectForKeyedSubscript:(NSString *const)key {
    return [self mpObjectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (obj) {
        [self setMPObject:obj forKey:key];
    } else {
        [self removeMPObjectForKey:key];
    }
}

@end
