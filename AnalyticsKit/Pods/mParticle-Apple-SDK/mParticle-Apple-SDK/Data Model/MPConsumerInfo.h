//
//  MPConsumerInfo.h
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

#import <Foundation/Foundation.h>

#pragma mark - MPCookie

extern NSString * _Nonnull const kMPCKContent;
extern NSString * _Nonnull const kMPCKDomain;
extern NSString * _Nonnull const kMPCKExpiration;

@interface MPCookie : NSObject <NSCoding>

@property (nonatomic, unsafe_unretained) int64_t cookieId;
@property (nonatomic, strong, nullable) NSString *content;
@property (nonatomic, strong, nullable) NSString *domain;
@property (nonatomic, strong, nullable) NSString *expiration;
@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, unsafe_unretained, readonly) BOOL expired;

- (nonnull instancetype)initWithName:(nonnull NSString *)name configuration:(nonnull NSDictionary *)configuration;
- (nullable NSDictionary *)dictionaryRepresentation;

@end


#pragma mark - MPConsumerInfo
@interface MPConsumerInfo : NSObject <NSCoding>

@property (nonatomic, unsafe_unretained) int64_t consumerInfoId;
@property (nonatomic, strong, nullable) NSArray<MPCookie *> *cookies;
@property (atomic, strong, nonnull) NSNumber *mpId;
@property (nonatomic, strong, nullable) NSString *uniqueIdentifier;

- (nullable NSDictionary *)cookiesDictionaryRepresentation;
- (void)updateWithConfiguration:(nonnull NSDictionary *)configuration;

@end
