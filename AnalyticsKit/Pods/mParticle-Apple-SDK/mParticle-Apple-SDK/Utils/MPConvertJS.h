//
//  MPConvertJS.h
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

@class MPCommerceEvent;
@class MPPromotionContainer;
@class MPPromotion;
@class MPTransactionAttributes;
@class MPProduct;

@interface MPConvertJS : NSObject

+ (MPCommerceEvent *)MPCommerceEvent:(NSDictionary *)json;
+ (MPPromotionContainer *)MPPromotionContainer:(NSDictionary *)json;
+ (MPPromotion *)MPPromotion:(NSDictionary *)json;
+ (MPTransactionAttributes *)MPTransactionAttributes:(NSDictionary *)json;
+ (MPProduct *)MPProduct:(NSDictionary *)json;

@end
