//
//  MPStandaloneMessage.m
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

#import "MPStandaloneMessage.h"

@implementation MPStandaloneMessage

- (instancetype)initWithMessageId:(int64_t)messageId UUID:(NSString *)uuid messageType:(NSString *)messageType messageData:(NSData *)messageData timestamp:(NSTimeInterval)timestamp uploadStatus:(MPUploadStatus)uploadStatus {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _messageId = messageId;
    _uuid = uuid;
    _messageType = messageType;
    _timestamp = timestamp;
    _uploadStatus = uploadStatus;
    _messageData = messageData;
    
    return self;
}

- (instancetype)initWithMessageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp {
    return [self initWithMessageId:0
                              UUID:uuid
                       messageType:messageType
                       messageData:[NSJSONSerialization dataWithJSONObject:messageInfo options:0 error:nil]
                         timestamp:timestamp
                      uploadStatus:uploadStatus];
}

- (NSString *)description {
    NSString *serializedString = [self serializedString];
    
    return [NSString stringWithFormat:@"StandaloneMessage\n Id: %lld\n UUID: %@\n Type: %@\n timestamp: %.0f\n Content: %@\n", self.messageId, self.uuid, self.messageType, self.timestamp, serializedString];
}

- (BOOL)isEqual:(MPStandaloneMessage *)object {
    BOOL isEqual = _messageId == object.messageId &&
                   _timestamp == object.timestamp &&
                   [_messageType isEqualToString:object.messageType] &&
                   [_messageData isEqualToData:object.messageData];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPStandaloneMessage *copyObject = [[MPStandaloneMessage alloc] initWithMessageId:_messageId
                                                                                UUID:[_uuid copy]
                                                                         messageType:[_messageType copy]
                                                                         messageData:[_messageData copy]
                                                                           timestamp:_timestamp
                                                                        uploadStatus:_uploadStatus];
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.messageId forKey:@"messageId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.messageType forKey:@"messageType"];
    [coder encodeObject:self.messageData forKey:@"messageData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeInteger:self.uploadStatus forKey:@"uploadStatus"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self initWithMessageId:[coder decodeInt64ForKey:@"messageId"]
                              UUID:[coder decodeObjectForKey:@"uuid"]
                       messageType:[coder decodeObjectForKey:@"messageType"]
                       messageData:[coder decodeObjectForKey:@"messageData"]
                         timestamp:[coder decodeDoubleForKey:@"timestamp"]
                      uploadStatus:[coder decodeIntegerForKey:@"uploadStatus"]];
    
    return self;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:_messageData options:0 error:nil];
    return dictionary;
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:_messageData encoding:NSUTF8StringEncoding];
    return serializedString;
}

@end
