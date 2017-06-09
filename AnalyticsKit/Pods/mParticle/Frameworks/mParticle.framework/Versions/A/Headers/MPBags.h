//
//  MPBags.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

@class MPProduct;

/**
 This class is used to describe a product bag to hold the state of products in the hands of a user. Please note a difference 
 when compared with a shopping cart. A product bag is intendend to represent product samples shipped for trial by a user, which 
 later may return the samples or add one or more to a shopping cart with the intent of purchasing them.

 Bags, and products added to them are persisted throughout the lifetime of the application. It is up to you to remove products from 
 a bag, and remove bags according to their respective life-cycles in your app.
 
 You should not try to create independent instance of this class, instead you should use the instance provided to you via the 
 mParticle singleton.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 MParticle.sharedInstance().bags.addProduct(product1, toBag:"bag name")
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 [[MParticle sharedInstance].bags addProduct:product1 toBag:&#64;"bag name"];
 </code></pre>
 */
@interface MPBags : NSObject

/**
 Adds a product to a bag. If a bag with the given name does not exist, one will be automatically created for you.
 @param product An instance of MPProduct
 @param bagName The name of the bag
 */
- (void)addProduct:(MPProduct *)product toBag:(NSString *)bagName;

/**
 Removes a product from a bag. If the bag does not contain the product or if the bag does not exist, this method has no effect.
 @param product An instance of MPProduct
 @param bagName The name of the bag
 */
- (void)removeProduct:(MPProduct *)product fromBag:(NSString *)bagName;

/**
 Returns a dictionary containing bag names as keys and corresponding arrays of products as values.
 
 <pre><code>
 {
 
    "bag name 1":[prod1, prod2],
 
    "bag name 2":[prod3, prod4]
 
 }
 </code></pre>
 
 @returns A dictionary with bags and products.
 */
- (NSDictionary *)productBags;

/**
 Removes all product bags together with its respective products.
 */
- (void)removeAllProductBags;

/**
 Removes a product bag. If the bag does not exist, this method has no effect.
 @param bagName The name of the bag
 */
- (void)removeProductBag:(NSString *)bagName;

@end
