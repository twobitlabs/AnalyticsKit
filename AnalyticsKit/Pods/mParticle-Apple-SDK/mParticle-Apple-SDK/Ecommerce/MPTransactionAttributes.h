//
//  MPTransactionAttributes.h
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
@property (nonatomic, strong, nullable) NSString *affiliation;

/**
 The coupon code string.
 */
@property (nonatomic, strong, nullable) NSString *couponCode;

/**
 The shipping amount of the commerce event transaction.
 */
@property (nonatomic, strong, nullable) NSNumber *shipping;

/**
 The tax amount of the commerce event transaction.
 */
@property (nonatomic, strong, nullable) NSNumber *tax;

/**
 The revenue amount of the commerce event transaction. It usually is the <b>sum(products x quantities) + tax + shipping</b>.
 However it may contain other values not listed in the formula, it will vary per company.
 */
@property (nonatomic, strong, nullable) NSNumber *revenue;

/**
 The unique identifier for the commerce event transaction.
 */
@property (nonatomic, strong, nullable) NSString *transactionId;

@end

extern NSString * _Nonnull const kMPExpTAAffiliation;
extern NSString * _Nonnull const kMPExpTAShipping;
extern NSString * _Nonnull const kMPExpTATax;
extern NSString * _Nonnull const kMPExpTARevenue;
extern NSString * _Nonnull const kMPExpTATransactionId;
extern NSString * _Nonnull const kMPExpTACouponCode;
