//
//  MPCommerce.h
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

@class MPCart;
@class MPTransactionAttributes;

/**
 This class is a convenience wrapper to using the e-commerce methods.
 It contains a reference to the cart singleton (<b>MPCart</b>), which should be used to log adding and removing products to the shopping cart.
 
 Using the methods and properties of this class should be done through the instance provided in the mParticle singleton.
 
 Note that all operations provided here can be accomplished through the <b>logCommerceEvent:</b> method.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let commerce = MParticle.sharedInstance().commerce
 
 commerce.cart.addProduct(product)
 
 commerce.purchaseWithTransactionAttributes(transactionAttributes, clearCart:true)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPCommerce *commerce = [MParticle sharedInstance].commerce;
 
 [commerce.cart addProduct:product];
 
 [commerce purchaseWithTransactionAttributes:transactionAttributes clearCart:YES];
 </code></pre>
 
 @see MPCart
 @see MPTransactionAttributes
 @see mParticle
 */
@interface MPCommerce : NSObject

/**
 A reference to the MPCart singleton.
 
 @see MPCart
 */
@property (nonatomic, strong, readonly, nonnull) MPCart *cart;

/**
 The currency used in the commerce event.
 */
@property (nonatomic, strong, nullable) NSString *currency;

/**
 Logs a checkout commerce event with the products contained in the shopping cart.
 */
- (void)checkout;

/**
 Logs a checkout with options commerce event with the products contained in the shopping cart.
 
 @param options A string describing what the options are
 @param step The step number, within the chain of commerce event transactions, corresponding to the checkout
 */
- (void)checkoutWithOptions:(nullable NSString *)options step:(NSInteger)step;

/**
 Clears the contents of the shopping cart. 
 
 This method is equivalent to calling the MPCart's <i>clear</i> method.
 */
- (void)clearCart;

/**
 Logs a <i>purchase</i> commerce event with the products contained in the shopping cart.
 
 @param transactionAttributes The attributes of the transaction, such as: transactionId, tax, affiliation, shipping, etc.
 @param clearCart A flag indicating whether the shopping cart should be cleared after logging this commerce event.
 
 @see MPTransactionAttributes
 */
- (void)purchaseWithTransactionAttributes:(nonnull MPTransactionAttributes *)transactionAttributes clearCart:(BOOL)clearCart;

/**
 Logs a <i>refund</i> commerce event with the products contained in the shopping cart.
 
 @param transactionAttributes The attributes of the transaction, such as: transactionId, tax, affiliation, shipping, etc.
 @param clearCart A flag indicating whether the shopping cart should be cleared after logging this commerce event.
 
 @see MPTransactionAttributes
 */
- (void)refundTransactionAttributes:(nonnull MPTransactionAttributes *)transactionAttributes clearCart:(BOOL)clearCart;

@end
