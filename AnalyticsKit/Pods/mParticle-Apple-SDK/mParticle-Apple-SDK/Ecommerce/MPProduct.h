#import <Foundation/Foundation.h>
/**
 This class is used to describe a product used in a commerce event.
 Since this class behaves similarly to an NSMutableDictionary, custom key/value pairs can be specified, in addition to the
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
@interface MPProduct : NSObject <NSCopying, NSSecureCoding>

/**
 The product brand
 */
@property (nonatomic, strong, nullable) NSString *brand;

/**
 A category to which the product belongs
 */
@property (nonatomic, strong, nullable) NSString *category;

/**
 The coupon associated with the product
 */
@property (nonatomic, strong, nullable) NSString *couponCode;

/**
 The name of the product
 */
@property (nonatomic, strong, nonnull) NSString *name;

/**
 The price of a product. If product is free or price is non-applicable use nil. Default value is nil
 */
@property (nonatomic, strong, nullable) NSNumber *price;

/**
 SKU of a product. This is the product id
 */
@property (nonatomic, strong, nonnull) NSString *sku;

/**
 The variant of the product
 */
@property (nonatomic, strong, nullable) NSString *variant;

/**
 The prosition of the product on the screen or impression list
 */
@property (nonatomic, unsafe_unretained) NSUInteger position;

/**
 The quantity of the product. Default value is 1
 */
@property (nonatomic, strong, nonnull) NSNumber *quantity;

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
- (nonnull instancetype)initWithName:(nonnull NSString *)name sku:(nonnull NSString *)sku quantity:(nonnull NSNumber *)quantity price:(nullable NSNumber *)price;

/**
 Returns an array with all keys in the MPProduct dictionary
 @returns An array with all dictionary keys
 */
- (nonnull NSArray *)allKeys;

/**
 Number of entries in the MPProduct dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nonnull id)obj forKeyedSubscript:(nonnull NSString *)key;

#pragma mark Deprecated and/or Unavailable
/**
 An entity with which the transaction should be affiliated (e.g. a particular store). If nil, mParticle will use an empty string
 @deprecated use MPTransactionAttributes.affiliation instead
 */
@property (nonatomic, strong, nullable) NSString *affiliation __attribute__((deprecated("use MPTransactionAttributes.affiliation instead")));

/**
 The currency of a transaction. If not specified, mParticle will use "USD"
 @deprecated use MPCommerceEvent.currency instead
 */
@property (nonatomic, strong, nullable) NSString *currency __attribute__((deprecated("use MPCommerceEvent.currency instead")));

/**
 A unique ID representing the transaction. This ID should not collide with other transaction IDs. If not specified, mParticle will generate a random id with 20 characters
 @deprecated use MPTransactionAttributes.transactionId instead
 */
@property (nonatomic, strong, nullable) NSString *transactionId __attribute__((deprecated("use MPTransactionAttributes.transactionId instead")));

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
- (nonnull instancetype)initWithName:(nonnull NSString *)name category:(nullable NSString *)category quantity:(NSInteger)quantity totalAmount:(double)totalAmount __attribute__((unavailable("use initWithName:sku:quantity:price: instead")));

/**
 @deprecated use initWithName:sku:quantity:price: instead
 */
- (nonnull instancetype)initWithName:(nonnull NSString *)name category:(nullable NSString *)category quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount __attribute__((unavailable("use initWithName:sku:quantity:price: instead")));

@end

// Internal
extern NSString * _Nonnull const kMPProductName;
extern NSString * _Nonnull const kMPProductSKU;
extern NSString * _Nonnull const kMPProductUnitPrice;
extern NSString * _Nonnull const kMPProductQuantity;
extern NSString * _Nonnull const kMPProductRevenue;
extern NSString * _Nonnull const kMPProductCategory;
extern NSString * _Nonnull const kMPProductTotalAmount;
extern NSString * _Nonnull const kMPProductTransactionId;
extern NSString * _Nonnull const kMPProductAffiliation;
extern NSString * _Nonnull const kMPProductCurrency;
extern NSString * _Nonnull const kMPProductTax;
extern NSString * _Nonnull const kMPProductShipping;

// Expanded
extern NSString * _Nonnull const kMPExpProductBrand;
extern NSString * _Nonnull const kMPExpProductName;
extern NSString * _Nonnull const kMPExpProductSKU;
extern NSString * _Nonnull const kMPExpProductUnitPrice;
extern NSString * _Nonnull const kMPExpProductQuantity;
extern NSString * _Nonnull const kMPExpProductCategory;
extern NSString * _Nonnull const kMPExpProductCouponCode;
extern NSString * _Nonnull const kMPExpProductVariant;
extern NSString * _Nonnull const kMPExpProductPosition;
extern NSString * _Nonnull const kMPExpProductTotalAmount;
