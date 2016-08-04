//
//  MPMediaMetadataDPR.m
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

#import "MPMediaMetadataDPR.h"

#define kMPDPRAssetKey @"assetid"
#define kMPDPRCategoryKey @"category"
#define kMPDPRDataSourceKey @"dataSrc"
#define kMPDPRLengthKey @"length"
#define kMPDPRTitleKey @"title"
#define kMPDPRTVKey @"tv"
#define kMPDPRTypeKey @"type"

@implementation MPMediaMetadataDPR

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMediaMetadataDPR *copyObject = [[[self class] alloc] init];
    
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

#pragma mark MPMediaMetadataProtocol
- (NSMutableDictionary *)objectDictionary {
    if (_objectDictionary) {
        return _objectDictionary;
    }
    
    _objectDictionary = [super objectDictionary];
    _objectDictionary[kMPDPRLengthKey] = @"0";
    _objectDictionary[kMPDPRTVKey] = @"false";
    
    return _objectDictionary;
}

#pragma mark Public accessors
- (NSString *)assetId {
    return self.objectDictionary[kMPDPRAssetKey];
}

- (void)setAssetId:(NSString *)assetId {
    self.objectDictionary[kMPDPRAssetKey] = assetId;
}

- (NSString *)category {
    return self.objectDictionary[kMPDPRCategoryKey];
}

- (void)setCategory:(NSString *)category {
    self.objectDictionary[kMPDPRCategoryKey] = category;
}

- (NSString *)dataSource {
    return self.objectDictionary[kMPDPRDataSourceKey];
}

- (void)setDataSource:(NSString *)dataSource {
    self.objectDictionary[kMPDPRDataSourceKey] = dataSource;
}

- (NSUInteger)length {
    return [self.objectDictionary[kMPDPRLengthKey] integerValue];
}

- (void)setLength:(NSUInteger)length {
    self.objectDictionary[kMPDPRLengthKey] = [NSString stringWithFormat:@"%lu", (unsigned long)length];
}

- (NSString *)title {
    return self.objectDictionary[kMPDPRTitleKey];
}

- (void)setTitle:(NSString *)title {
    self.objectDictionary[kMPDPRTitleKey] = title;
}

- (BOOL)tv {
    return [self.objectDictionary[kMPDPRTVKey] isEqualToString:@"true"];
}

- (void)setTv:(BOOL)tv {
    self.objectDictionary[kMPDPRTVKey] = tv ? @"true" : @"false";
}

- (NSString *)type {
    return self.objectDictionary[kMPDPRTypeKey];
}

- (void)setType:(NSString *)type {
    self.objectDictionary[kMPDPRTypeKey] = type;
}

@end
