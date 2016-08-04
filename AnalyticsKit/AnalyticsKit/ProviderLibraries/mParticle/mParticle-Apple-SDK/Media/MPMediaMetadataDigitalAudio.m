//
//  MPMediaMetadataDigitalAudio.m
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

#import "MPMediaMetadataDigitalAudio.h"
#import "MPIConstants.h"
#import "MPILogger.h"

#define kMPDAAssetKey @"assetid"
#define kMPDADataSourceKey @"dataSrc"
#define kMPDAProviderKey @"provider"
#define kMPDAStationTypeKey @"stationType"
#define kMPDATypeKey @"type"

@interface MPMediaMetadataDigitalAudio()

@end


@implementation MPMediaMetadataDigitalAudio

- (instancetype)init {
    return [self initWithAssetId:nil provider:nil stationType:MPMediaStationTypeCustomStation];
}

- (instancetype)initWithAssetId:(NSString *)assetId provider:(NSString *)provider stationType:(MPMediaStationType)stationType {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.objectDictionary[kMPDADataSourceKey] = @"cms";
    self.objectDictionary[kMPDATypeKey] = @"radio";
    self.assetId = assetId;
    self.provider = provider;
    self.stationType = stationType;
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMediaMetadataDigitalAudio *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_objectDictionary = [_objectDictionary mutableCopy];
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
- (NSString *)assetId {
    return self.objectDictionary[kMPDAAssetKey];
}

- (void)setAssetId:(NSString *)assetId {
    if (!MPIsNull(assetId)) {
        self.objectDictionary[kMPDAAssetKey] = assetId;
    }
}

- (NSString *)dataSource {
    return self.objectDictionary[kMPDADataSourceKey];
}

- (NSString *)provider {
    return self.objectDictionary[kMPDAProviderKey];
}

- (void)setProvider:(NSString *)provider {
    if (!MPIsNull(provider)) {
        self.objectDictionary[kMPDAProviderKey] = provider;
    }
}

- (MPMediaStationType)stationType {
    return (MPMediaStationType)[self.objectDictionary[kMPDAStationTypeKey] integerValue];
}

- (void)setStationType:(MPMediaStationType)stationType {
    self.objectDictionary[kMPDAStationTypeKey] = [NSString stringWithFormat:@"%lu", (unsigned long)stationType];
}

- (NSString *)type {
    return self.objectDictionary[kMPDATypeKey];
}

@end
