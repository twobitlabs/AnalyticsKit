//
//  MPBags.h
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
- (void)addProduct:(nonnull MPProduct *)product toBag:(nonnull NSString *)bagName;

/**
 Removes a product from a bag. If the bag does not contain the product or if the bag does not exist, this method has no effect.
 @param product An instance of MPProduct
 @param bagName The name of the bag
 */
- (void)removeProduct:(nonnull MPProduct *)product fromBag:(nonnull NSString *)bagName;

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
- (nullable NSDictionary<NSString *, NSArray<MPProduct *> *> *)productBags;

/**
 Removes all product bags together with its respective products.
 */
- (void)removeAllProductBags;

/**
 Removes a product bag. If the bag does not exist, this method has no effect.
 @param bagName The name of the bag
 */
- (void)removeProductBag:(nonnull NSString *)bagName;

@end
