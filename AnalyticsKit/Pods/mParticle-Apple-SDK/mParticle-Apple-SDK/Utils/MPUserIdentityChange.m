//
//  MPUserIdentityChange.m
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

#import "MPUserIdentityChange.h"
#import "MPIConstants.h"

#pragma mark - MPUserIdentityInstance
@implementation MPUserIdentityInstance

- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value {
    self = [super init];
    if (self) {
        _type = type;
        _value = value;
    }
    
    return self;
}

- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value dateFirstSet:(nonnull NSDate *)dateFirstSet isFirstTimeSet:(BOOL)isFirstTimeSet {
    self = [self initWithType:type value:value];
    if (self) {
        _dateFirstSet = dateFirstSet;
        _isFirstTimeSet = isFirstTimeSet;
    }
    
    return self;
}

- (nonnull instancetype)initWithUserIdentityDictionary:(nonnull NSDictionary<NSString *, id> *)userIdentityDictionary {
    MPUserIdentity type = [userIdentityDictionary[kMPUserIdentityTypeKey] integerValue];
    NSString *value = userIdentityDictionary[kMPUserIdentityIdKey];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:([userIdentityDictionary[kMPDateUserIdentityWasFirstSet] doubleValue] / 1000.0)];
    BOOL isFirstSet = [userIdentityDictionary[kMPIsFirstTimeUserIdentityHasBeenSet] boolValue];
    
    self = [self initWithType:type
                        value:value
                 dateFirstSet:date
               isFirstTimeSet:isFirstSet];
    
    return self;
}

- (nonnull NSMutableDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *identityDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    identityDictionary[kMPUserIdentityTypeKey] = @(_type);
    identityDictionary[kMPIsFirstTimeUserIdentityHasBeenSet] = @(_isFirstTimeSet);
    
    if (_dateFirstSet) {
        identityDictionary[kMPDateUserIdentityWasFirstSet] = MPMilliseconds([_dateFirstSet timeIntervalSince1970]);
    }

    if (_value) {
        identityDictionary[kMPUserIdentityIdKey] = _value;
    }
    
    return identityDictionary;
}

@end

#pragma mark - MPUserIdentityChange
@implementation MPUserIdentityChange

- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities {
    self = [super init];
    if (self) {
        _userIdentityNew = userIdentityNew;
        _changed = YES;

        [userIdentities enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull ui, NSUInteger idx, BOOL * _Nonnull stop) {
            MPUserIdentity idType = [ui[kMPUserIdentityTypeKey] unsignedIntegerValue];
            id idValue = ui[kMPUserIdentityIdKey];

            if (idType == _userIdentityNew.type && [idValue isEqual:_userIdentityNew.value]) {
                _changed = NO;
            }

            if (!_changed) {
                *stop = YES;
            }
        }];
    }
    
    return self;
}

- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew oldUserIdentity:(nullable MPUserIdentityInstance *)userIdentityOld timestamp:(nullable NSDate *)timestamp userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities {
    self = [self initWithNewUserIdentity:userIdentityNew userIdentities:userIdentities];
    if (self) {
        _userIdentityOld = userIdentityOld;
        _timestamp = timestamp;
    }
    
    return self;
}

- (NSDate *)timestamp {
    if (!_timestamp) {
        _timestamp = [NSDate date];
    }
    
    return _timestamp;
}

@end
