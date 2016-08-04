//
//  MPForwardRecord.h
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

#import "MPEnums.h"
#import "MPIConstants.h"

@class MPKitFilter;
@class MPKitExecStatus;

@interface MPForwardRecord : NSObject

@property (nonatomic, unsafe_unretained) uint64_t forwardRecordId;
@property (nonatomic, strong, nonnull) NSMutableDictionary *dataDictionary;

- (nonnull instancetype)initWithId:(int64_t)forwardRecordId data:(nonnull NSData *)data;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus kitFilter:(nullable MPKitFilter *)kitFilter originalEvent:(nullable id)originalEvent;
- (nullable NSData *)dataRepresentation;

@end
