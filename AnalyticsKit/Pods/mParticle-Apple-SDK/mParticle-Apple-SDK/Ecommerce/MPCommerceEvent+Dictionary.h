//
//  MPCommerceEvent+Dictionary.h
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
#import "MPCommerceEventInstruction.h"

typedef NS_ENUM(NSInteger, MPCommerceEventKind) {
    MPCommerceEventKindUnknown = 0,
    MPCommerceEventKindProduct = 1,
    MPCommerceEventKindPromotion,
    MPCommerceEventKindImpression
};


@interface MPCommerceEvent(Dictionary)

- (instancetype)initWithAction:(MPCommerceEventAction)action;
- (NSString *)actionNameForAction:(MPCommerceEventAction)action;
- (MPCommerceEventAction)actionWithName:(NSString *)actionName;
- (void)addProducts:(NSArray<MPProduct *> *)products;
- (NSDictionary *)dictionaryRepresentation;
- (NSArray<MPCommerceEventInstruction *> *)expandedInstructions;
- (NSArray<MPProduct *> *const)addedProducts;
- (MPCommerceEventKind)kind;
- (void)removeProducts:(NSArray<MPProduct *> *)products;
- (NSArray<MPProduct *> *const)removedProducts;
- (void)resetLatestProducts;
- (MPEventType)type;
- (NSMutableDictionary *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary *)beautifiedAttributes;
- (NSMutableDictionary *)userDefinedAttributes;
- (void)setUserDefinedAttributes:(NSMutableDictionary *)userDefinedAttributes;
- (void)setImpressions:(NSDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)impressions;
- (void)setProducts:(NSArray<MPProduct *> *)products;
- (NSMutableDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)copyImpressionsMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSDate *)timestamp;
- (void)setTimestamp:(NSDate *)timestamp;

@end
