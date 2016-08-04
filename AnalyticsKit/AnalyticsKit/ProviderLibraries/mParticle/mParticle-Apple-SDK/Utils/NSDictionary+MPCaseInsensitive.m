//
//  NSDictionary+MPCaseInsensitive.m
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

#import "NSDictionary+MPCaseInsensitive.h"
#import "MPDateFormatter.h"
#import "MPILogger.h"

@implementation NSDictionary(MPCaseInsensitive)

- (NSString *)caseInsensitiveKey:(NSString *)key {
    __block NSString *localKey = nil;
    NSString *lowerCaseKey = [key lowercaseString];
    NSArray *keys = [self allKeys];
    [keys enumerateObjectsWithOptions:NSEnumerationConcurrent
                           usingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
                               if ([lowerCaseKey isEqualToString:[aKey lowercaseString]]) {
                                   localKey = aKey;
                                   *stop = YES;
                               }
                           }];
    
    if (!localKey) {
        localKey = key;
    }
    
    return localKey;
}

- (id)valueForCaseInsensitiveKey:(NSString *)key {
    __block id value = nil;
    NSString *lowerCaseKey = [key lowercaseString];
    NSArray *keys = [self allKeys];
    [keys enumerateObjectsWithOptions:NSEnumerationConcurrent
                           usingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
                               if ([lowerCaseKey isEqualToString:[aKey lowercaseString]]) {
                                   value = self[aKey];
                                   *stop = YES;
                               }
                           }];
    
    return value;
}

- (NSDictionary<NSString *, NSString *> *)transformValuesToString {
    NSDictionary *originalDictionary = self;
    __block NSMutableDictionary<NSString *, NSString *> *transformedDictionary = [[NSMutableDictionary alloc] initWithCapacity:originalDictionary.count];
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    
    [originalDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:NSStringClass]) {
            transformedDictionary[key] = obj;
        } else if ([obj isKindOfClass:NSNumberClass]) {
            NSNumber *numberAttribute = (NSNumber *)obj;
            
            if (numberAttribute == (void *)kCFBooleanFalse || numberAttribute == (void *)kCFBooleanTrue) {
                transformedDictionary[key] = [numberAttribute boolValue] ? @"Y" : @"N";
            } else {
                transformedDictionary[key] = [numberAttribute stringValue];
            }
        } else if ([obj isKindOfClass:[NSDate class]]) {
            transformedDictionary[key] = [MPDateFormatter stringFromDateRFC3339:obj];
        } else if ([obj isKindOfClass:[NSData class]] && [(NSData *)obj length] > 0) {
            transformedDictionary[key] = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        } else {
            MPILogError(@"Data type is not supported as an attribute value: %@ - %@", obj, [[obj class] description]);
            NSAssert([obj isKindOfClass:[NSString class]], @"Data type is not supported as an attribute value");
            return;
        }
    }];
    
    return (NSDictionary *)transformedDictionary;
}

@end
