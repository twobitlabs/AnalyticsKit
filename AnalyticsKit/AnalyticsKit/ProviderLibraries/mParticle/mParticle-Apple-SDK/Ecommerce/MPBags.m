//
//  MPBags.m
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

#import "MPBags.h"
#import "MPILogger.h"
#import "MPProduct.h"
#import "MPProductBag.h"
#import "MPPersistenceController.h"
#import "MPIConstants.h"

@interface MPBags()

@property (nonatomic, strong, nonnull) NSMutableArray<MPProductBag *> *productBagsArray;

@end


@implementation MPBags

#pragma mark Private accessors
- (NSMutableArray *)productBagsArray {
    if (_productBagsArray) {
        return _productBagsArray;
    }
    
    NSArray<MPProductBag *> *productBags = [[MPPersistenceController sharedInstance] fetchProductBags];
    
    _productBagsArray = productBags ? [[NSMutableArray alloc] initWithArray:productBags] : [[NSMutableArray alloc] initWithCapacity:1];
    return _productBagsArray;
}

#pragma mark MPBags+Internal
- (NSDictionary *)dictionaryRepresentation {
    if (self.productBagsArray.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:self.productBagsArray.count];
    NSDictionary *productBagDictionary;
    
    for (MPProductBag *productBag in self.productBagsArray) {
        productBagDictionary = [productBag dictionaryRepresentation];
        
        if (productBagDictionary) {
            [dictionary addEntriesFromDictionary:productBagDictionary];
        }
    }
    
    if (dictionary.count == 0) {
        return nil;
    }
    
    return dictionary;
}

#pragma mark Public methods
- (void)addProduct:(MPProduct *)product toBag:(NSString *)bagName {
    if (MPIsNull(bagName)) {
        MPILogError(@"'bagName' cannot be nil/null.");
        return;
    }
    
    if (MPIsNull(product)) {
        MPILogError(@"'product' cannot be nil/null.");
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", bagName];
    MPProductBag *productBag = [[self.productBagsArray filteredArrayUsingPredicate:predicate] firstObject];
    
    if (productBag) {
        [productBag.products addObject:product];
    } else {
        productBag = [[MPProductBag alloc] initWithName:bagName product:product];
        [self.productBagsArray addObject:productBag];
    }
    
    [[MPPersistenceController sharedInstance] saveProductBag:productBag];
}

- (void)removeProduct:(MPProduct *)product fromBag:(NSString *)bagName {
    if (MPIsNull(bagName)) {
        MPILogWarning(@"'bagName' parameter is nil/null.");
        return;
    }
    
    if (MPIsNull(product)) {
        MPILogWarning(@"'product' parameter is nil/null.");
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", bagName];
    MPProductBag *productBag = [[self.productBagsArray filteredArrayUsingPredicate:predicate] firstObject];
    
    if (!productBag) {
        MPILogDebug(@"No bag was found under the name: %@", bagName);
        return;
    }

    NSUInteger numberOfProducts = productBag.products.count;
    [productBag.products removeObject:product];
    
    if (numberOfProducts != productBag.products.count) {
        [[MPPersistenceController sharedInstance] saveProductBag:productBag];
    } else {
        MPILogDebug(@"Bag %@, did not contain such product", bagName);
    }
}

- (nullable NSDictionary<NSString *, NSArray<MPProduct *> *> *)productBags {
    if (self.productBagsArray.count == 0) {
        return nil;
    }
    
    NSMutableDictionary<NSString *, NSArray<MPProduct *> *> *productBags = [[NSMutableDictionary alloc] initWithCapacity:self.productBagsArray.count];
    
    for (MPProductBag *productBag in self.productBagsArray) {
        productBags[productBag.name] = productBag.products;
    }
    
    return productBags;
}

- (void)removeAllProductBags {
    [[MPPersistenceController sharedInstance] deleteAllProductBags];
    _productBagsArray = nil;
}

- (void)removeProductBag:(NSString *)bagName {
    if (MPIsNull(bagName)) {
        MPILogWarning(@"'bagName' parameter is nil/null.");
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", bagName];
    MPProductBag *productBag = [[self.productBagsArray filteredArrayUsingPredicate:predicate] firstObject];
    
    if (productBag) {
        [[MPPersistenceController sharedInstance] deleteProductBag:productBag];
        [self.productBagsArray removeObject:productBag];
    } else {
        MPILogDebug(@"Bag %@, did not exist.", bagName);
    }
}

@end
