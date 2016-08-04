//
//  MPSession.h
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

@interface MPSession : MPDataModelAbstract <NSCopying>

@property (nonatomic, strong, nonnull) NSMutableDictionary *attributesDictionary;
@property (nonatomic, strong, readonly, nonnull) NSNumber *sessionNumber;
@property (nonatomic, unsafe_unretained) NSTimeInterval backgroundTime;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval foregroundTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval startTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval endTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval length;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval suspendTime;
@property (nonatomic, unsafe_unretained, readonly) uint eventCounter;
@property (nonatomic, unsafe_unretained, readonly) uint numberOfInterruptions;
@property (nonatomic, unsafe_unretained) int64_t sessionId;
@property (nonatomic, unsafe_unretained, readonly) BOOL persisted;

- (nonnull instancetype)initWithStartTime:(NSTimeInterval)timestamp;

- (nonnull instancetype)initWithSessionId:(int64_t)sessionId
                                     UUID:(nonnull NSString *)uuid
                           backgroundTime:(NSTimeInterval)backgroundTime
                                startTime:(NSTimeInterval)startTime
                                  endTime:(NSTimeInterval)endTime
                               attributes:(nullable NSMutableDictionary *)attributesDictionary
                            sessionNumber:(nullable NSNumber *)sessionNumber
                    numberOfInterruptions:(uint)numberOfInterruptions
                             eventCounter:(uint)eventCounter
                              suspendTime:(NSTimeInterval)suspendTime __attribute__((objc_designated_initializer));

- (void)incrementCounter;
- (void)suspendSession;

@end
