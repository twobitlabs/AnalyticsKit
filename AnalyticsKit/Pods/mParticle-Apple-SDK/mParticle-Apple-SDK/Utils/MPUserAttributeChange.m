//
//  MPUserAttributeChange.m
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

#import "MPUserAttributeChange.h"
#import "MPIConstants.h"

@implementation MPUserAttributeChange

@synthesize valueToLog = _valueToLog;

- (nonnull instancetype)initWithUserAttributes:(nullable NSDictionary<NSString *, id> *)userAttributes key:(nonnull NSString *)key value:(nullable id)value {
    Class NSStringClass = [NSString class];
    Class NSArrayClass = [NSArray class];
    BOOL validKey = !MPIsNull(key) && [key isKindOfClass:NSStringClass];
    BOOL isValueAnArray = [value isKindOfClass:NSArrayClass];
    
    NSAssert(validKey, @"'key' must be a string.");
    NSAssert(value == nil || (value != nil && ([value isKindOfClass:NSStringClass] || [value isKindOfClass:[NSNumber class]] || isValueAnArray) || (NSNull *)value == [NSNull null]), @"'value' must be either nil, string, number, or array of strings.");
    
    if (!validKey || (!userAttributes && !value)) {
        return nil;
    }

    self = [super init];
    if (self) {
        _userAttributes = userAttributes;
        _key = key;
        _value = value;
        _changed = YES;
        _deleted = NO;
        
        id existingValue = userAttributes[key];
        if (existingValue) {
            _isArray = [existingValue isKindOfClass:NSArrayClass] || isValueAnArray;

            BOOL isExistingValueNull = (NSNull *)existingValue == [NSNull null];
            if (value) {
                _changed = isExistingValueNull || ![existingValue isEqual:value];
            } else {
                _changed = !isExistingValueNull;
            }
        } else {
            _isArray = isValueAnArray;
        }
    }
    
    return self;
}

- (void)setDeleted:(BOOL)deleted {
    _deleted = deleted;
    _changed = YES;
}

- (id)valueToLog {
    if (!_valueToLog) {
        _valueToLog = _value && !_deleted ? _value : [NSNull null];
    }
    
    return _valueToLog;
}

- (void)setValueToLog:(id)valueToLog {
    _valueToLog = valueToLog ? valueToLog : [NSNull null];
}

@end
