//
//  MPMediaMetadataOCR.m
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

#import "MPMediaMetadataOCR.h"

#define kMPOCRTagKey @"ocrtag"
#define kMPOCRTypeKey @"type"

@implementation MPMediaMetadataOCR

- (instancetype)initWithType:(NSString *)type tag:(NSString *)tag {
    self = [super init];
    if (!self || !type || !tag) {
        return nil;
    }
    
    self.type = type;
    self.ocrTag = tag;
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMediaMetadataOCR *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_objectDictionary = [_objectDictionary copy];
    }
    
    return copyObject;
}

#pragma mark Subscripting
- (id)objectForKeyedSubscript:(NSString *const)key {
    return [super objectForKeyedSubscript:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    [super setObject:obj forKeyedSubscript:key];
}

- (NSArray *)allKeys {
    return [super allKeys];
}

- (NSUInteger)count {
    return [super count];
}

#pragma mark Public accessors
- (NSString *)ocrTag {
    return self.objectDictionary[kMPOCRTagKey];
}

- (void)setOcrTag:(NSString *)ocrTag {
    self.objectDictionary[kMPOCRTagKey] = ocrTag;
}

- (NSString *)type {
    return self.objectDictionary[kMPOCRTypeKey];
}

- (void)setType:(NSString *)type {
    self.objectDictionary[kMPOCRTypeKey] = type;
}

@end
