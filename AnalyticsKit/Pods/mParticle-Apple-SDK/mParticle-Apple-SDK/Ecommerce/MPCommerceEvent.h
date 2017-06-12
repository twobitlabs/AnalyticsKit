//
//  MPCommerceEvent.h
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

@class MPProduct;
@class MPPromotionContainer;
@class MPTransactionAttributes;

typedef NS_ENUM(NSUInteger, MPCommerceEventAction) {
    MPCommerceEventActionAddToCart = 0,
    MPCommerceEventActionRemoveFromCart,
    MPCommerceEventActionAddToWishList,
    MPCommerceEventActionRemoveFromWishlist,
    MPCommerceEventActionCheckout,
    MPCommerceEventActionCheckoutOptions,
    MPCommerceEventActionClick,
    MPCommerceEventActionViewDetail,
    MPCommerceEventActionPurchase,
    MPCommerceEventActionRefund
};


/**
 This class contains the information and represents a commerce event to be logged using the mParticle SDK.

 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let commerceEvent = MPCommerceEvent(action: MPCommerceEventAction.AddToCart, product: product1)
 
 let mParticle = MParticle.sharedInstance()
 
 mParticle.logCommerceEvent(commerceEvent)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product1];
 
 MParticle *mParticle = [MParticle sharedInstance];
 
 [mParticle logCommerceEvent:commerceEvent];
 </code></pre>
 
 @see mParticle
 */
@interface MPCommerceEvent : NSObject <NSCopying, NSCoding> {
@protected
    NSDate *_timestamp;
}

/**
 Checkout option string describing what the options are.
 */
@property (nonatomic, strong, nullable) NSString *checkoutOptions;

/**
 The currency used in the commerce event.
 */
@property (nonatomic, strong, nullable) NSString *currency;

/**
 A dictionary containing list names as keys and arrays of products impressed under that list name
 
 <pre><code>
 {"listName1":[product1, product2]}
 </code></pre>
 */
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSString *, __kindof NSSet<MPProduct *> *> *impressions;

/**
 List of products being applied <i>action</i>
 */
@property (nonatomic, strong, readonly, nullable) NSArray<MPProduct *> *products;

/**
 A promotion container describing a promotion action and its respective products.
 
 @see MPPromotionContainer
 */
@property (nonatomic, strong, nullable) MPPromotionContainer *promotionContainer;

/**
 Describes a product action list for this commerce event transaction.
 */
@property (nonatomic, strong, nullable) NSString *productListName;

/**
 Describes a product list source for this commerce event transaction.
 */
@property (nonatomic, strong, nullable) NSString *productListSource;

/**
 The label describing the screen on which the commerce event transaction occurred
 */
@property (nonatomic, strong, nullable) NSString *screenName;

/**
 The attributes of the transaction, such as: transactionId, tax, affiliation, shipping, etc.
 
 @see MPTransactionAttributes
 */
@property (nonatomic, strong, nullable) MPTransactionAttributes *transactionAttributes;

/**
 A value from the <b>MPCommerceEventAction</b> enum describing the commerce event action.
 */
@property (nonatomic, unsafe_unretained) MPCommerceEventAction action;

/**
 The step number, within the chain of commerce event transactions, corresponding to the checkout.
 */
@property (nonatomic, unsafe_unretained) NSInteger checkoutStep;

/**
 Flag indicating whether a refund in non-interactive. The default value is false/NO.
 */
@property (nonatomic, unsafe_unretained) BOOL nonInteractive;

/**
 Initializes an instance of MPCommerceEvent with an action and a product.
 
 @param action A value from the <b>MPCommerceEventAction</b> enum describing the commerce event action
 @param product An instance of MPProduct
 
 @see MPCommerceEventAction
 */
- (nonnull instancetype)initWithAction:(MPCommerceEventAction)action product:(nullable MPProduct *)product;

/**
 Initializes an instance of MPCommerceEvent with a list name for a product impression.
 
 @param listName A string under which the product was listed for this impression
 @param product An instance of MPProduct
 */
- (nonnull instancetype)initWithImpressionName:(nullable NSString *)listName product:(nullable MPProduct *)product;

/**
 Initializes an instance of MPCommerceEvent with a promotion container (promotion for products).
 
 @param promotionContainer An instance of MPPromotionContainer describing a promotion action and its respective products
 
 @see MPPromotionContainer
 */
- (nonnull instancetype)initWithPromotionContainer:(nullable MPPromotionContainer *)promotionContainer;

/**
 Adds the representation of a product impression under a given list name.
 
 @param product An instance of MPProduct
 @param listName A string under which the product was listed for this impression
 */
- (void)addImpression:(nonnull MPProduct *)product listName:(nonnull NSString *)listName;

/**
 Adds a product to the list of products to have <i>action</i> applied to.
 
 @param product An instance of MPProduct
 */
- (void)addProduct:(nonnull MPProduct *)product;

/**
 Removes a product to the list of products to have <i>action</i> applied to.
 
 @param product An instance of MPProduct
 */
- (void)removeProduct:(nonnull MPProduct *)product;

/**
 Associates a custom dictionary of key/value pairs to the commerce event.
 
 Alternatively you can set custom attributes using the regular notation for setting key/value pairs in an NSMutableDictionary.
 
 <b>For example:</b>
 
 <b>Swift</b>
 <pre><code>
 let commerceEvent = MPCommerceEvent(action: MPCommerceEventAction.AddToCart, product: product1)
 
 commerceEvent.setCustomAttributes(dictionaryOfKeyValuePairs)
 
 commerceEvent["Custom Key"] = "Custom Value"
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product1];
 
 [commerceEvent setCustomAttributes:dictionaryOfKeyValuePairs];
 
 commerceEvent[&#64;"Custom Key"] = &#64;"Custom Value";
 </code></pre>

 @param customAttributes A dictionary containing the custom key/value pairs.
 */
- (void)setCustomAttributes:(nullable NSDictionary<NSString *, NSString *> *)customAttributes;

/**
 Returns an array with all keys in the custom attributes dictionary
 @returns An array with all keys in the custom attributes dictionary
 */
- (nullable NSArray *)allKeys;

/**
 Number of entries in the custom attributes dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nonnull id)obj forKeyedSubscript:(nonnull NSString *)key;

@end

extern NSString * _Nonnull const kMPCEInstructionsKey;
extern NSString * _Nonnull const kMPExpCECheckoutOptions;
extern NSString * _Nonnull const kMPExpCECurrency;
extern NSString * _Nonnull const kMPExpCEProductListName;
extern NSString * _Nonnull const kMPExpCEProductListSource;
extern NSString * _Nonnull const kMPExpCECheckoutStep;
extern NSString * _Nonnull const kMPExpCEProductImpressionList;
extern NSString * _Nonnull const kMPExpCEProductCount;
