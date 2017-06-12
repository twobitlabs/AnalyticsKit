//
//  MPUserAttributeChange.h
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

@interface MPUserAttributeChange : NSObject

@property (nonatomic, strong, nonnull) NSString *key;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) id value;
@property (nonatomic, strong, nullable) id valueToLog;
@property (nonatomic, unsafe_unretained, readonly) BOOL changed;
@property (nonatomic, unsafe_unretained) BOOL deleted;
@property (nonatomic, unsafe_unretained) BOOL isArray;

- (nonnull instancetype)initWithUserAttributes:(nullable NSDictionary<NSString *, id> *)userAttributes key:(nonnull NSString *)key value:(nullable id)value;

@end
