//
//  MPProduct.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

/**
 This class is used to describe a product used in a commerce event.
 Since this class behaves similarly to a NSMutableDictionary, custom key/value pairs can be specified, in addition to the
 ones listed as class properties.
 
 <b>For example:</b>
 
 <b>Swift</b>
 <pre><code>
 let product = MPProduct(name:"Product Name", sku:"s1k2u3", quantity:1, price:1.23)
 
 product["Custom Key"] = "Custom Value"
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPProduct *product = [[MPProduct alloc] initWithName:&#64;"Product Name" sku:&#64;"s1k2u3" quantity:&#64;1 price:&#64;1.23];
 
 product[&#64;"Custom Key"] = &#64;"Custom Value";
 </code></pre>
 */
@interface MPProduct : NSObject <NSCopying, NSCoding>

/**
 The product brand
 */
@property (nonatomic, strong) NSString *brand;

/**
 A category to which the product belongs
 */
@property (nonatomic, strong) NSString *category;

/**
 The coupon associated with the product
 */
@property (nonatomic, strong) NSString *couponCode;

/**
 The name of the product
 */
@property (nonatomic, strong) NSString *name;

/**
 The price of a product. If product is free or price is non-applicable use nil. Default value is nil
 */
@property (nonatomic, strong) NSNumber *price;

/**
 SKU of a product. This is the product id
 */
@property (nonatomic, strong) NSString *sku;

/**
 The variant of the product
 */
@property (nonatomic, strong) NSString *variant;

/**
 The prosition of the product on the screen or impression list
 */
@property (nonatomic, unsafe_unretained) NSUInteger position;

/**
 The quantity of the product. Default value is 1
 */
@property (nonatomic, strong) NSNumber *quantity;

/**
 Initializes an instance of MPProduct.
 @param name The name of the product
 @param sku The SKU or Product Id
 @param quantity The quantity of the product. If non-applicable use 0
 @param price The unit price of the product. If the product is free or if non-applicable pass 0
 @returns An instance of MPProduct, or nil if it could not be created
 
 <b>Swift</b>
 <pre><code>
 let product = MPProduct(name:"Product Name", sku:"s1k2u3", quantity:1, price:1.23)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPProduct *product = [[MPProduct alloc] initWithName:&#64;"Product Name" sku:&#64;"s1k2u3" quantity:&#64;1 price:&#64;1.23];
 </code></pre>
 */
- (instancetype)initWithName:(NSString *)name sku:(NSString *)sku quantity:(NSNumber *)quantity price:(NSNumber *)price;

/**
 Returns an array with all keys in the MPProduct dictionary
 @returns An array with all dictionary keys
 */
- (NSArray *)allKeys;

/**
 Number of entries in the MPProduct dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (id)objectForKeyedSubscript:(NSString *const)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

#pragma mark Deprecated and/or Unavailable
/**
 An entity with which the transaction should be affiliated (e.g. a particular store). If nil, mParticle will use an empty string
 @deprecated use MPTransactionAttributes.affiliation instead
 */
@property (nonatomic, strong) NSString *affiliation __attribute__((deprecated("use MPTransactionAttributes.affiliation instead")));

/**
 The currency of a transaction. If not specified, mParticle will use "USD"
 @deprecated use MPCommerceEvent.currency instead
 */
@property (nonatomic, strong) NSString *currency __attribute__((deprecated("use MPCommerceEvent.currency instead")));

/**
 A unique ID representing the transaction. This ID should not collide with other transaction IDs. If not specified, mParticle will generate a random id with 20 characters
 @deprecated use MPTransactionAttributes.transactionId instead
 */
@property (nonatomic, strong) NSString *transactionId __attribute__((deprecated("use MPTransactionAttributes.transactionId instead")));

/**
 @deprecated use MPTransactionAttributes.revenue instead
 */
@property (nonatomic, readwrite) double revenueAmount __attribute__((unavailable("use MPTransactionAttributes.revenue instead")));

/**
 The total cost of shipping for a transaction. If free or non-applicable use 0. Default value is zero
 @deprecated use MPTransactionAttributes.shipping instead
 */
@property (nonatomic, readwrite) double shippingAmount __attribute__((deprecated("use MPTransactionAttributes.shipping instead")));

/**
 The total tax for a transaction. If free or non-applicable use 0. Default value is zero
 @deprecated use MPTransactionAttributes.tax instead
 */
@property (nonatomic, readwrite) double taxAmount __attribute__((deprecated("use MPTransactionAttributes.tax instead")));

/**
 The total value of a transaction, including tax and shipping. If free or non-applicable use 0. Default value is zero
 @deprecated use MPTransactionAttributes.revenue instead
 */
@property (nonatomic, readwrite) double totalAmount __attribute__((deprecated("use MPTransactionAttributes.revenue instead")));

/**
 The price of a product. If product is free or price is non-applicable use 0. Default value is zero
 @deprecated use the price property instead
 */
@property (nonatomic, readwrite) double unitPrice __attribute__((deprecated("use the price property instead")));

/**
 @deprecated use initWithName:sku:quantity:price: instead
 */
- (instancetype)initWithName:(NSString *)name category:(NSString *)category quantity:(NSInteger)quantity totalAmount:(double)totalAmount __attribute__((deprecated("use initWithName:sku:quantity:price: instead")));

/**
 @deprecated use initWithName:sku:quantity:price: instead
 */
- (instancetype)initWithName:(NSString *)name category:(NSString *)category quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount __attribute__((unavailable("use initWithName:sku:quantity:price: instead")));

@end

// Internal
extern NSString *const kMPProductName;
extern NSString *const kMPProductSKU;
extern NSString *const kMPProductUnitPrice;
extern NSString *const kMPProductQuantity;
extern NSString *const kMPProductRevenue;
extern NSString *const kMPProductCategory;
extern NSString *const kMPProductTotalAmount;

// Deprecated
extern NSString *const kMPProductTransactionId;
extern NSString *const kMPProductAffiliation;
extern NSString *const kMPProductCurrency;
extern NSString *const kMPProductTax;
extern NSString *const kMPProductShipping;

// Expanded
extern NSString *const kMPExpProductBrand;
extern NSString *const kMPExpProductName;
extern NSString *const kMPExpProductSKU;
extern NSString *const kMPExpProductUnitPrice;
extern NSString *const kMPExpProductQuantity;
extern NSString *const kMPExpProductCategory;
extern NSString *const kMPExpProductCouponCode;
extern NSString *const kMPExpProductVariant;
extern NSString *const kMPExpProductPosition;
extern NSString *const kMPExpProductTotalAmount;
