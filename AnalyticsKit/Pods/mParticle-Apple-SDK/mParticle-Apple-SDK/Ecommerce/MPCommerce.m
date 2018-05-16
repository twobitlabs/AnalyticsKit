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
    return [MParticle sharedInstance].identity.currentUser.cart;
}

#pragma mark Public methods
- (void)checkout {
    NSArray<MPProduct *> *products = [self.cart products];
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
    
    NSArray<MPProduct *> *products = [self.cart products];
    [commerceEvent addProducts:products];
    commerceEvent.currency = self.currency;

    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

- (void)clearCart {
    [self.cart clear];
}

- (void)purchaseWithTransactionAttributes:(MPTransactionAttributes *)transactionAttributes clearCart:(BOOL)clearCart {
    NSAssert(transactionAttributes.transactionId, @"'transactionId' is required for purchases.");
    NSArray<MPProduct *> *products = [self.cart products];
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
    NSArray<MPProduct *> *products = [self.cart products];
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
