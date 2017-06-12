//
//  MPUserIdentityChange.h
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
#import "MPEnums.h"

#pragma mark - MPUserIdentityInstance
@interface MPUserIdentityInstance : NSObject

@property (nonatomic, strong, nullable) NSString *value;
@property (nonatomic, strong, nonnull) NSDate *dateFirstSet;
@property (nonatomic, unsafe_unretained) MPUserIdentity type;
@property (nonatomic, unsafe_unretained) BOOL isFirstTimeSet;

- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value;
- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value dateFirstSet:(nonnull NSDate *)dateFirstSet isFirstTimeSet:(BOOL)isFirstTimeSet;
- (nonnull instancetype)initWithUserIdentityDictionary:(nonnull NSDictionary<NSString *, id> *)userIdentityDictionary;
- (nonnull NSMutableDictionary<NSString *, id> *)dictionaryRepresentation;

@end

#pragma mark - MPUserIdentityChange
@interface MPUserIdentityChange : NSObject

@property (nonatomic, strong, nullable) MPUserIdentityInstance *userIdentityNew;
@property (nonatomic, strong, nullable) MPUserIdentityInstance *userIdentityOld;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, unsafe_unretained, readonly) BOOL changed;

- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities;
- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew oldUserIdentity:(nullable MPUserIdentityInstance *)userIdentityOld timestamp:(nullable NSDate *)timestamp userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities;

@end
