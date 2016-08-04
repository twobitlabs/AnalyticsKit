//
//  MPPromotion+Dictionary.h
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

@interface MPPromotion(Dictionary)

- (NSDictionary<NSString *, NSString *> *)dictionaryRepresentation;
- (NSDictionary<NSString *, NSString *> *)beautifiedDictionaryRepresentation;
- (MPPromotion *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;
- (NSMutableDictionary<NSString *, NSString *> *)beautifiedAttributes;
- (void)setBeautifiedAttributes:(NSMutableDictionary<NSString *, NSString *> *)beautifiedAttributes;

@end


@interface MPPromotionContainer(Dictionary)

- (NSString *)actionNameForAction:(MPPromotionAction)action;
- (MPPromotionAction)actionWithName:(NSString *)actionName;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)beautifiedDictionaryRepresentation;
- (void)setPromotions:(NSArray *)promotions;
- (MPPromotionContainer *)copyMatchingHashedProperties:(NSDictionary *)hashedMap;

@end
