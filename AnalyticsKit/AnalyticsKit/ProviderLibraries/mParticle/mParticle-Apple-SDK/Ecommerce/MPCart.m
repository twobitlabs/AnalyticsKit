//
//  MPCart.m
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

#import "MPCart.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPILogger.h"

@interface MPCart()

@property (nonatomic, strong, readonly, nullable) NSString *cartFile;
@property (nonatomic, strong, nonnull) NSMutableArray<MPProduct *> *productsList;

@end


@implementation MPCart

@synthesize cartFile = _cartFile;

#pragma mark Private accessors
- (NSString *)cartFile {
    if (_cartFile) {
        return _cartFile;
    }
    
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    _cartFile = [stateMachineDirectoryPath stringByAppendingPathComponent:@"MPCart.cart"];
    return _cartFile;
}

- (NSMutableArray *)productsList {
    if (_productsList) {
        return _productsList;
    }
    
    _productsList = [[NSMutableArray alloc] init];
    return _productsList;
}

#pragma mark Private methods
- (void)persistCart {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:self.cartFile]) {
        [fileManager removeItemAtPath:self.cartFile error:nil];
    }
    
    if (self.productsList.count > 0) {
        if (![NSKeyedArchiver archiveRootObject:self toFile:self.cartFile]) {
            MPILogError(@"Cart was not persisted.");
        }
    }
}

- (void)removePersistedCart {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:self.cartFile]) {
        [fileManager removeItemAtPath:_cartFile error:nil];
    }
}

- (MPCart *)retrieveCart {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:self.cartFile]) {
        return nil;
    }
    
    MPCart *cart = (MPCart *)[NSKeyedUnarchiver unarchiveObjectWithFile:_cartFile];
    return cart;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (_productsList) {
        [coder encodeObject:_productsList forKey:@"productsList"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [[MPCart alloc] init];
    if (self) {
        NSArray *productList = [coder decodeObjectForKey:@"productsList"];
        if (productList) {
            _productsList = [[NSMutableArray alloc] initWithArray:productList];
        }
    }

    return self;
}

#pragma mark MPCart+Dictionary
- (void)addProducts:(NSArray<MPProduct *> *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList {
    if (logEvent) {
        for (MPProduct *product in products) {
            [product setTimeAddedToCart:[NSDate date]];
        }
        
        MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart];
        [commerceEvent addProducts:products];
        
        [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
    } else if (updateProductList) {
        [self.productsList addObjectsFromArray:products];
        [self persistCart];
    }
}

- (NSDictionary<NSString *, __kindof NSArray *> *)dictionaryRepresentation {
    if (_productsList.count == 0) {
        return nil;
    }
    
    __block NSMutableArray<NSDictionary *> *cartProducts = [[NSMutableArray alloc] initWithCapacity:_productsList.count];
    
    [_productsList enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
        NSDictionary *productDictionary = [product commerceDictionaryRepresentation];
        
        if (productDictionary) {
            [cartProducts addObject:productDictionary];
        }
    }];
    
    if (cartProducts.count > 0) {
        NSDictionary<NSString *, __kindof NSArray *> *dictionary = @{@"pl":cartProducts};
        return dictionary;
    } else {
        return nil;
    }
}

- (void)removeProducts:(NSArray<MPProduct *> *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList {
    if (logEvent) {
        MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionRemoveFromCart];
        [commerceEvent removeProducts:products];
        [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
    } else if (updateProductList) {
        [self.productsList removeObjectsInArray:products];
        [self persistCart];
    }
}

#pragma mark Class methods
+ (instancetype)sharedInstance {
    static MPCart *sharedInstance = nil;
    static dispatch_once_t cartPredicate;
    
    dispatch_once(&cartPredicate, ^{
        sharedInstance = [[MPCart alloc] init];
        
        MPCart *persistedCart = [sharedInstance retrieveCart];
        if (persistedCart && persistedCart.productsList.count > 0) {
            sharedInstance.productsList = persistedCart.productsList;
        }
    });
    
    return sharedInstance;
}

#pragma mark Public methods
- (void)addProduct:(MPProduct *)product {
    BOOL validProduct = !MPIsNull(product) && [product isKindOfClass:[MPProduct class]];
    NSAssert(validProduct, @"The 'product' variable is not valid.");
    
    if (validProduct) {
        [self addProducts:@[product] logEvent:YES updateProductList:NO];
    }
}

- (void)clear {
    _productsList = nil;
    [self removePersistedCart];
}

- (NSArray<MPProduct *> *)products {
    return _productsList.count > 0 ? (NSArray *)_productsList : nil;
}

- (void)removeProduct:(MPProduct *)product {
    BOOL validProduct = !MPIsNull(product) && [product isKindOfClass:[MPProduct class]];
    NSAssert(validProduct, @"The 'product' variable is not valid.");

    if (validProduct) {
        [self removeProducts:@[product] logEvent:YES updateProductList:NO];
    }
}

@end
