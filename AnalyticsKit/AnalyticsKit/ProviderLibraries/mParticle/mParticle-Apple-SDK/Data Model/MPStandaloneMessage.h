//
//  MPStandaloneMessage.h
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

#import "MPDataModelAbstract.h"
#import "MPIConstants.h"
#import "MPDataModelProtocol.h"

@interface MPStandaloneMessage : MPDataModelAbstract <NSCopying, NSCoding, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSString *messageType;
@property (nonatomic, strong, nonnull) NSData *messageData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) int64_t messageId;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;

// Designited initializer for fetching data from the database
- (nonnull instancetype)initWithMessageId:(int64_t)messageId
                                     UUID:(nonnull NSString *)uuid
                              messageType:(nonnull NSString *)messageType
                              messageData:(nonnull NSData *)messageData
                                timestamp:(NSTimeInterval)timestamp
                             uploadStatus:(MPUploadStatus)uploadStatus;

// Designated initializers for creating instances (not fetched from the database)
- (nonnull instancetype)initWithMessageType:(nonnull NSString *)messageType messageInfo:(nonnull NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(nonnull NSString *)uuid timestamp:(NSTimeInterval)timestamp;

@end
