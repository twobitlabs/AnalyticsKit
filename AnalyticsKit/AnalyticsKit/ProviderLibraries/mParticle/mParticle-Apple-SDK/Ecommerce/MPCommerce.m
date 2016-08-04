//
//  MPCommerce.m
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

#import "MPCommerce.h"
#import "MPCart.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "mParticle.h"
#import "MPIConstants.h"

@implementation MPCommerce

#pragma mark Public accessors
- (MPCart *)cart {
    return [MPCart sharedInstance];
}

#pragma mark Public methods
- (void)checkout {
    NSArray<MPProduct *> *products = [[MPCart sharedInstance] products];
    if (products.count == 0) {
        return;
    }
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckout];
    [commerceEvent addProducts:products];
    commerceEvent.currency = self.currency;
    
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

- (void)checkoutWithOptions:(NSString *)options step:(NSInteger)step {
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    commerceEvent.checkoutOptions = options;
    commerceEvent.checkoutStep = step;
    
    NSArray<MPProduct *> *products = [[MPCart sharedInstance] products];
    [commerceEvent addProducts:products];
    commerceEvent.currency = self.currency;

    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

- (void)clearCart {
    [[MPCart sharedInstance] clear];
}

- (void)purchaseWithTransactionAttributes:(MPTransactionAttributes *)transactionAttributes clearCart:(BOOL)clearCart {
    NSAssert(transactionAttributes.transactionId, @"'transactionId' is required for purchases.");
    NSArray<MPProduct *> *products = [[MPCart sharedInstance] products];
    NSAssert(!MPIsNull(products), @"Cannot purchase a cart with no products.");
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase];
    commerceEvent.transactionAttributes = transactionAttributes;
    [commerceEvent addProducts:products];
    commerceEvent.currency = self.currency;
    
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
    
    if (clearCart) {
        [self clearCart];
    }
}

- (void)refundTransactionAttributes:(MPTransactionAttributes *)transactionAttributes clearCart:(BOOL)clearCart {
    NSAssert(transactionAttributes.transactionId, @"'transactionId' is required for refunds.");
    NSArray<MPProduct *> *products = [[MPCart sharedInstance] products];
    NSAssert(!MPIsNull(products), @"Cannot refund a cart with no products.");
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase];
    commerceEvent.transactionAttributes = transactionAttributes;
    [commerceEvent addProducts:products];
    commerceEvent.currency = self.currency;

    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
    
    if (clearCart) {
        [self clearCart];
    }
}

@end
