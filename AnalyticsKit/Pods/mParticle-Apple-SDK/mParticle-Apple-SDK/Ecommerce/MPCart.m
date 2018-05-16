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
@property (nonatomic, strong, nullable) NSMutableArray<MPProduct *> *productsList;
@property (nonatomic, strong, readonly, nullable) NSNumber *mpid;
@property (nonatomic) BOOL cartInitialized;

@end


@implementation MPCart

@synthesize cartFile = _cartFile;

- (instancetype)initWithUserId:(NSNumber *)userId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _mpid = userId;
    _productsList = nil;
    _cartInitialized = NO;
    
    return self;
}

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
    
    NSString *cartPath = [NSString stringWithFormat:@"%@::%@", _mpid, @"MPCart.cart"];
    _cartFile = [stateMachineDirectoryPath stringByAppendingPathComponent:cartPath];
    return _cartFile;
}

- (NSMutableArray *)productsList {
    if (_productsList) {
        return _productsList;
    }
    
    if (!_cartInitialized) {
        _cartInitialized = YES;
        MPCart *persistedCart = [self retrieveCart];
        if (persistedCart && persistedCart.productsList.count > 0) {
            _productsList = persistedCart.productsList;
            return _productsList;
        }
    }
    
    _productsList = [[NSMutableArray alloc] init];
    return _productsList;
}

#pragma mark Private methods
- (void)migrate {
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *oldCartFile = [stateMachineDirectoryPath stringByAppendingPathComponent:@"MPCart.cart"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.cartFile]) {
        MPCart *cart = nil;
        @try {
            cart = (MPCart *)[NSKeyedUnarchiver unarchiveObjectWithFile:oldCartFile];
        } @catch(NSException *ex) { }
        
        if (!cart) {
            MPILogError(@"Unable to migrate cart.");
        } else if (cart.productsList) {
            _productsList = cart.productsList;
            [self persistCart];
        }

    }
}

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

- (BOOL)validateProduct:(MPProduct *)product {
    BOOL valid = !MPIsNull(product) && [product isKindOfClass:[MPProduct class]];
    return valid;
}

- (BOOL)validateProducts:(NSArray<MPProduct *> *)products {
    __block BOOL allValidProducts = YES;
    [products enumerateObjectsUsingBlock:^(MPProduct * _Nonnull product, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL thisProductValid = [self validateProduct:product];
        if (!thisProductValid) {
            allValidProducts = NO;
            *stop = YES;
        }
    }];
    return allValidProducts;
}

#pragma mark Public methods
- (void)addProduct:(MPProduct *)product {
    BOOL validProduct = [self validateProduct:product];
    NSAssert(validProduct, @"The 'product' variable is not valid.");
    
    if (validProduct) {
        [self addProducts:@[product] logEvent:YES updateProductList:NO];
    }
}

- (void)addAllProducts:(NSArray<MPProduct *> *)products shouldLogEvents:(BOOL)shouldLogEvents {
    BOOL validProducts = [self validateProducts:products];
    NSAssert(validProducts, @"The 'products' array is not valid");
    
    if (validProducts) {
        [self addProducts:products logEvent:shouldLogEvents updateProductList:NO];
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
