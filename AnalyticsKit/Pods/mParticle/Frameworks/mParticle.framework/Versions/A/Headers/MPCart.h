//
//  MPCart.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

@class MPProduct;

/**
 This class is a singleton and used to keep the state of the shopping cart.
 E-commerce transactions logged using the MPCommerce class or the logCommerceEvent: method will keep the state of the respective products in here.

 Once products are added to the cart, its contents are persisted through the lifetime of the app. Therefore it is important that after completing an ecommerce transaction
 (purchase, refund, etc) that you call the cart's <b>clear</b> method to empty its content and remove the whatever data was persisted.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let cart = MPCart.sharedInstance()
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCart *cart = [MPCart sharedInstance];
 </code></pre>
 
 @see MPCommerce
 @see mParticle
 */
@interface MPCart : NSObject <NSCoding>

/**
 Returns the shared instance object.
 @returns the Singleton instance of the MPClass class.
 */
+ (instancetype)sharedInstance;

/**
 Adds a product to the shopping cart. 
 Calling this method directly will create a <i>AddToCart</i>  <b> MPCommerceEvent</b> with <i>product</i> and invoke the <b>logCommerceEvent:</b> method on your behalf.

 <b>Swift</b>
 <pre><code>
 let cart = MPCart.sharedInstance()
 
 cart.addProduct(product)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCart *cart = [MPCart sharedInstance];
 
 [cart addProduct:product];
 </code></pre>
 
 @param product An instance of MPProduct
 
 @see MPCommerceEvent
 @see mParticle
 */
- (void)addProduct:(MPProduct *)product;

/**
 Empties the shopping cart. Removes all its contents and respective persisted data.
 
 <b>Swift</b>
 <pre><code>
 let cart = MPCart.sharedInstance()
 
 cart.clear()
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCart *cart = [MPCart sharedInstance];
 
 [cart clear];
 </code></pre>
 */
- (void)clear;

/**
 Returns the collection of products in the shoppint cart.
 @returns An array with products in the shoppint cart or nil if the cart is empty.
 */
- (NSArray *)products;

/**
 Removes a product from the shopping cart.
 Calling this method directly will create a <i>RemoveFromCart</i>  <b> MPCommerceEvent</b> with <i>product</i> and invoke the <b>logCommerceEvent:</b> method on your behalf.
 
 <b>Swift</b>
 
 <pre><code>
 let cart = MPCart.sharedInstance()

 cart.removeProduct(product)
 </code></pre>
 
 <b>Objective-C</b>
 
 <pre><code>
 MPCart *cart = [MPCart sharedInstance];
 
 [cart removeProduct:product];
 </code></pre>
 
 @param product An instance of MPProduct

 @see MPCommerceEvent
 @see mParticle
 */
- (void)removeProduct:(MPProduct *)product;

@end
