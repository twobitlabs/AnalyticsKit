//
//  MPProduct+Dictionary.h
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

#import "MPProduct.h"

@interface MPProduct(Dictionary)

- (NSDictionary<NSString *, id> *)commerceDictionaryRepresentation;
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;
- (NSDictionary<NSString *, id> *)beautifiedDictionaryRepresentation;
- (void)setTimeAddedToCart:(NSDate *)date;
- (MPProduct *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSMutableDictionary<NSString *, id> *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary<NSString *, id> *)beautifiedAttributes;
- (NSMutableDictionary<NSString *, id> *)userDefinedAttributes;
- (void)setUserDefinedAttributes:(NSMutableDictionary<NSString *, id> *)userDefinedAttributes;

@end
