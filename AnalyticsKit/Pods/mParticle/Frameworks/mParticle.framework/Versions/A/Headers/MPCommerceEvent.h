//
//  MPCommerceEvent.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

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
@interface MPCommerceEvent : NSObject <NSCopying, NSCoding>

/**
 Checkout option string describing what the options are.
 */
@property (nonatomic, strong) NSString *checkoutOptions;

/**
 The currency used in the commerce event.
 */
@property (nonatomic, strong) NSString *currency;

/**
 A dictionary containing list names as keys and arrays of products impressed under that list name
 
 <pre><code>
 {"listName1":[product1, product2]}
 </code></pre>
 */
@property (nonatomic, strong, readonly) NSDictionary *impressions;

/**
 List of products being applied <i>action</i>
 */
@property (nonatomic, strong, readonly) NSArray *products;

/**
 A promotion container describing a promotion action and its respective products.
 
 @see MPPromotionContainer
 */
@property (nonatomic, strong) MPPromotionContainer *promotionContainer;

/**
 Describes a product action list for this commerce event transaction.
 */
@property (nonatomic, strong) NSString *productListName;

/**
 Describes a product list source for this commerce event transaction.
 */
@property (nonatomic, strong) NSString *productListSource;

/**
 The label describing the screen on which the commerce event transaction occurred
 */
@property (nonatomic, strong) NSString *screenName;

/**
 The attributes of the transaction, such as: transactionId, tax, affiliation, shipping, etc.
 
 @see MPTransactionAttributes
 */
@property (nonatomic, strong) MPTransactionAttributes *transactionAttributes;

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
- (instancetype)initWithAction:(MPCommerceEventAction)action product:(MPProduct *)product;

/**
 Initializes an instance of MPCommerceEvent with a list name for a product impression.
 
 @param listName A string under which the product was listed for this impression
 @param product An instance of MPProduct
 */
- (instancetype)initWithImpressionName:(NSString *)listName product:(MPProduct *)product;

/**
 Initializes an instance of MPCommerceEvent with a promotion container (promotion for products).
 
 @param promotionContainer An instance of MPPromotionContainer describing a promotion action and its respective products
 
 @see MPPromotionContainer
 */
- (instancetype)initWithPromotionContainer:(MPPromotionContainer *)promotionContainer;

/**
 Adds the representation of a product impression under a given list name.
 
 @param product An instance of MPProduct
 @param listName A string under which the product was listed for this impression
 */
- (void)addImpression:(MPProduct *)product listName:(NSString *)listName;

/**
 Adds a product to the list of products to have <i>action</i> applied to.
 
 @param product An instance of MPProduct
 */
- (void)addProduct:(MPProduct *)product;

/**
 Removes a product to the list of products to have <i>action</i> applied to.
 
 @param product An instance of MPProduct
 */
- (void)removeProduct:(MPProduct *)product;

/**
 Associates a custom dictionary of key/value pairs to the commerce event.
 
 Alternatively you can set custom attributes using the regular notation for setting key/value pairs in a NSMutableDictionary.
 
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
- (void)setCustomAttributes:(NSDictionary *)customAttributes;

/**
 Returns an array with all keys in the custom attributes dictionary
 @returns An array with all keys in the custom attributes dictionary
 */
- (NSArray *)allKeys;

/**
 Number of entries in the custom attributes dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (id)objectForKeyedSubscript:(NSString *const)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end

extern NSString *const kMPCEInstructionsKey;
extern NSString *const kMPExpCECheckoutOptions;
extern NSString *const kMPExpCECurrency;
extern NSString *const kMPExpCEProductListName;
extern NSString *const kMPExpCEProductListSource;
extern NSString *const kMPExpCECheckoutStep;
extern NSString *const kMPExpCEProductImpressionList;
extern NSString *const kMPExpCEProductCount;
