//
//  MPTransactionAttributes.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

/**
 This class represents the atributes of a commerce event transaction. It is used in conjunction with MPCommerceEvent to represent a commerce event transaction.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let transactionAttributes = MPTransactionAttributes()
 
 transactionAttributes.transactionId = "abc987"
 
 transactionAttributes.revenue = 31.41
 
 transactionAttributes.tax = 2.51
 
 transactionAttributes.affiliation = "Awesome Company, Inc."
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
 
 transactionAttributes.transactionId = &#64;"abc987";
 
 transactionAttributes.revenue = &#64;31.41;
 
 transactionAttributes.tax = &#64;2.51;
 
 transactionAttributes.affiliation = &#64;"Awesome Company, Inc.";
 </code></pre>
 
 @see MPCommerceEvent
 */
@interface MPTransactionAttributes : NSObject <NSCopying, NSCoding>

/**
 A string describing the affiliation.
 */
@property (nonatomic, strong) NSString *affiliation;

/**
 The coupon code string.
 */
@property (nonatomic, strong) NSString *couponCode;

/**
 The shipping amount of the commerce event transaction.
 */
@property (nonatomic, strong) NSNumber *shipping;

/**
 The tax amount of the commerce event transaction.
 */
@property (nonatomic, strong) NSNumber *tax;

/**
 The revenue amount of the commerce event transaction. It usually is the <b>sum(products x quantities) + tax + shipping</b>.
 However it may contain other values not listed in the formula, it will vary per company.
 */
@property (nonatomic, strong) NSNumber *revenue;

/**
 The unique identifier for the commerce event transaction.
 */
@property (nonatomic, strong) NSString *transactionId;

@end

extern NSString *const kMPExpTATransactionId;
