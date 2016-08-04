//
//  MPBreadcrumb.m
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

#import "MPBreadcrumb.h"
#import "MPIConstants.h"

@interface MPBreadcrumb()
@property (nonatomic, strong) NSString *content;
@end


@implementation MPBreadcrumb

- (instancetype)initWithSessionUUID:(NSString *)sessionUUID breadcrumbId:(int64_t)breadcrumbId UUID:(NSString *)uuid breadcrumbData:(NSData *)breadcrumbData sessionNumber:(NSNumber *)sessionNumber timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (self) {
        _sessionUUID = sessionUUID;
        _breadcrumbId = breadcrumbId;
        _uuid = uuid;
        _timestamp = timestamp;
        _sessionNumber = sessionNumber;
        _breadcrumbData = breadcrumbData;
        if (breadcrumbData) {
            _content = [[NSString alloc] initWithData:breadcrumbData encoding:NSUTF8StringEncoding];
        }
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Breadcrumb\n UUID: %@\n Content: %@\n timestamp: %.0f\n Session number: %@\n", self.uuid, self.content, self.timestamp, self.sessionNumber];
}

- (BOOL)isEqual:(MPBreadcrumb *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPBreadcrumb class]]) {
        return NO;
    }
    
    BOOL isEqual = _breadcrumbId == object.breadcrumbId &&
                   _timestamp == object.timestamp &&
                   [_uuid isEqualToString:object.uuid] &&
                   [_sessionUUID isEqualToString:object.sessionUUID] &&
                   [_breadcrumbData isEqualToData:object.breadcrumbData];
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPBreadcrumb *copyObject = [[MPBreadcrumb alloc] initWithSessionUUID:[_sessionUUID copy]
                                                            breadcrumbId:_breadcrumbId
                                                                    UUID:[_uuid copy]
                                                          breadcrumbData:[_breadcrumbData copy]
                                                           sessionNumber:[_sessionNumber copy]
                                                               timestamp:_timestamp];
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionUUID forKey:@"sessionUUID"];
    [coder encodeInt64:self.breadcrumbId forKey:@"breadcrumbId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.content forKey:@"content"];
    [coder encodeObject:self.breadcrumbData forKey:@"breadcrumbData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.sessionNumber forKey:@"sessionNumber"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *content = [coder decodeObjectForKey:@"content"];
    NSData *breadcrumbData = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    self = [self initWithSessionUUID:[coder decodeObjectForKey:@"sessionUUID"]
                        breadcrumbId:[coder decodeInt64ForKey:@"breadcrumbId"]
                                UUID:[coder decodeObjectForKey:@"uuid"]
                      breadcrumbData:breadcrumbData
                       sessionNumber:[coder decodeObjectForKey:@"sessionNumber"]
                           timestamp:[coder decodeDoubleForKey:@"timestamp"]];
    
    return self;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *breadcrumbInfo = [NSJSONSerialization JSONObjectWithData:_breadcrumbData options:0 error:nil];
    
    NSMutableDictionary *breadcrumbDictionary = [@{kMPMessageTypeKey:kMPMessageTypeLeaveBreadcrumbs,
                                                   kMPTimestampKey:breadcrumbInfo[kMPTimestampKey],
                                                   kMPMessageIdKey:breadcrumbInfo[kMPMessageIdKey],
                                                   kMPSessionIdKey:breadcrumbInfo[kMPSessionIdKey],
                                                   kMPSessionStartTimestamp:breadcrumbInfo[kMPSessionStartTimestamp]
                                                  }
                                                 mutableCopy];

    if (breadcrumbInfo[kMPSessionNumberKey]) {
       breadcrumbDictionary[kMPSessionNumberKey] = breadcrumbInfo[kMPSessionNumberKey];
    }

    if (breadcrumbInfo[kMPLeaveBreadcrumbsKey]) {
        breadcrumbDictionary[kMPLeaveBreadcrumbsKey] = breadcrumbInfo[kMPLeaveBreadcrumbsKey];
    }
    
    if (breadcrumbInfo[kMPAttributesKey]) {
        breadcrumbDictionary[kMPAttributesKey] = breadcrumbInfo[kMPAttributesKey];
    }

    return [breadcrumbDictionary copy];
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:self.breadcrumbData encoding:NSUTF8StringEncoding];
    
    return serializedString;
}

@end
