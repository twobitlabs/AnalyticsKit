//
//  MPCart.h
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

/**
 This class is a singleton and used to keep the state of the shopping cart.
 E-commerce transactions logged using the MPCommerce class or the logCommerceEvent: method will keep the state of the respective products in here.

 Once products are added to the cart, its contents are persisted through the lifetime of the app. Therefore it is important that after completing an ecommerce transaction
 (purchase, refund, etc) that you call the cart's <b>clear</b> method to empty its content and remove whatever data was persisted.
 
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
+ (nonnull instancetype)sharedInstance;

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
- (void)addProduct:(nonnull MPProduct *)product;

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
- (nullable NSArray<MPProduct *> *)products;

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
- (void)removeProduct:(nonnull MPProduct *)product;

@end
