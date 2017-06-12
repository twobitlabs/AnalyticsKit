//
//  MPConvertJS.m
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

#import "MPConvertJS.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPProduct.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"

typedef NS_ENUM(NSUInteger, MPJSCommerceEventAction) {
    MPJSCommerceEventActionAddToCart = 0,
    MPJSCommerceEventActionRemoveFromCart,
    MPJSCommerceEventActionCheckout,
    MPJSCommerceEventActionCheckoutOptions,
    MPJSCommerceEventActionClick,
    MPJSCommerceEventActionViewDetail,
    MPJSCommerceEventActionPurchase,
    MPJSCommerceEventActionRefund,
    MPJSCommerceEventActionAddToWishList,
    MPJSCommerceEventActionRemoveFromWishlist
};

@implementation MPConvertJS

+ (MPCommerceEventAction)MPCommerceEventAction:(NSNumber *)json {
    int actionInt = [json intValue];
    MPCommerceEventAction action;
    switch (actionInt) {
        case MPJSCommerceEventActionAddToCart:
            action = MPCommerceEventActionAddToCart;
            break;

        case MPJSCommerceEventActionRemoveFromCart:
            action = MPCommerceEventActionRemoveFromCart;
            break;

        case MPJSCommerceEventActionCheckout:
            action = MPCommerceEventActionCheckout;
            break;

        case MPJSCommerceEventActionCheckoutOptions:
            action = MPCommerceEventActionCheckoutOptions;
            break;

        case MPJSCommerceEventActionClick:
            action = MPCommerceEventActionClick;
            break;

        case MPJSCommerceEventActionViewDetail:
            action = MPCommerceEventActionViewDetail;
            break;

        case MPJSCommerceEventActionPurchase:
            action = MPCommerceEventActionPurchase;
            break;

        case MPJSCommerceEventActionRefund:
            action = MPCommerceEventActionRefund;
            break;

        case MPJSCommerceEventActionAddToWishList:
            action = MPCommerceEventActionAddToWishList;
            break;

        case MPJSCommerceEventActionRemoveFromWishlist:
            action = MPCommerceEventActionRemoveFromWishlist;
            break;

        default:
            action = MPCommerceEventActionAddToCart;
            NSAssert(NO, @"Invalid commerce event action");
            break;
    }
    return action;
}

+ (MPCommerceEvent *)MPCommerceEvent:(NSDictionary *)json {
    BOOL isProductAction = json[@"ProductAction"][@"ProductActionType"] != nil;
    BOOL isPromotion = json[@"PromotionAction"] != nil;
    BOOL isImpression = json[@"ProductImpressions"] != nil;
    BOOL isValid = isProductAction || isPromotion || isImpression;

    MPCommerceEvent *commerceEvent = nil;
    if (!isValid) {
        NSAssert(NO, @"Invalid commerce event");
        return commerceEvent;
    }

    if (isProductAction) {
        id productActionJson = json[@"ProductAction"][@"ProductActionType"];
        MPCommerceEventAction action = [MPConvertJS MPCommerceEventAction:productActionJson];
        commerceEvent = [[MPCommerceEvent alloc] initWithAction:action];
    }
    else if (isPromotion) {
        MPPromotionContainer *promotionContainer = [MPConvertJS MPPromotionContainer:json];
        commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    }
    else {
        commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:nil product:nil];
    }

    commerceEvent.checkoutOptions = json[@"CheckoutOptions"];
    commerceEvent.productListName = json[@"productActionListName"];
    commerceEvent.productListSource = json[@"productActionListSource"];
    commerceEvent.currency = json[@"CurrencyCode"];
    commerceEvent.transactionAttributes = [MPConvertJS MPTransactionAttributes:json[@"ProductAction"]];
    commerceEvent.checkoutStep = [json[@"CheckoutStep"] intValue];

    NSMutableArray *products = [NSMutableArray array];
    NSArray *jsonProducts = json[@"ProductAction"][@"ProductList"];
    [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPProduct *product = [MPConvertJS MPProduct:obj];
        [products addObject:product];
    }];
    [commerceEvent addProducts:products];

    NSArray *jsonImpressions = json[@"ProductImpressions"];
    [jsonImpressions enumerateObjectsUsingBlock:^(NSDictionary *jsonImpression, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *listName = jsonImpression[@"ProductImpressionList"];
        NSArray *jsonProducts = jsonImpression[@"ProductList"];
        [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull jsonProduct, NSUInteger idx, BOOL * _Nonnull stop) {
            MPProduct *product = [MPConvertJS MPProduct:jsonProduct];
            [commerceEvent addImpression:product listName:listName];
        }];
    }];

    return commerceEvent;
}

+ (MPPromotionContainer *)MPPromotionContainer:(NSDictionary *)json {
    int promotionActionInt = [json[@"PromotionAction"][@"PromotionActionType"] intValue];
    MPPromotionAction promotionAction = promotionActionInt == 1 ? MPPromotionActionView : MPPromotionActionClick;
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:promotionAction promotion:nil];
    NSArray *jsonPromotions = json[@"PromotionAction"][@"PromotionList"];
    [jsonPromotions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPPromotion *promotion = [MPConvertJS MPPromotion:obj];
        [promotionContainer addPromotion:promotion];
    }];

    return promotionContainer;
}

+ (MPPromotion *)MPPromotion:(NSDictionary *)json {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = json[@"Creative"];
    promotion.name = json[@"Name"];
    promotion.position = json[@"Position"];
    promotion.promotionId = json[@"Id"];
    return promotion;
}

+ (MPTransactionAttributes *)MPTransactionAttributes:(NSDictionary *)json {
    MPTransactionAttributes *transactionAttributes;
    transactionAttributes.affiliation = json[@"Affiliation"];
    transactionAttributes.couponCode = json[@"CouponCode"];
    transactionAttributes.shipping = json[@"ShippingAmount"];
    transactionAttributes.tax = json[@"TaxAmount"];
    transactionAttributes.revenue = json[@"TotalAmount"];
    transactionAttributes.transactionId = json[@"TransactionId"];
    return transactionAttributes;
}

+ (MPProduct *)MPProduct:(NSDictionary *)json {
    MPProduct *product = [[MPProduct alloc] init];
    product.brand = json[@"Brand"];
    product.category = json[@"Category"];
    product.couponCode = json[@"CouponCode"];
    product.name = json[@"Name"];
    product.price = json[@"Price"];
    product.sku = json[@"Sku"];
    product.variant = json[@"Variant"];
    product.position = [json[@"Position"] intValue];
    product.quantity = json[@"Quantity"];

    NSDictionary *jsonAttributes = json[@"Attributes"];
    for (NSString *key in jsonAttributes) {
        NSString *value = jsonAttributes[key];
        [product setObject:value forKeyedSubscript:key];
    }
    return product;
}

@end
