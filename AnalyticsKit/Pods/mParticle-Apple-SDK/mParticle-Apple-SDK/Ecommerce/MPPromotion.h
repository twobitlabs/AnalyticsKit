//
//  MPPromotion.h
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

typedef NS_ENUM(NSUInteger, MPPromotionAction) {
    MPPromotionActionClick = 0,
    MPPromotionActionView
};


#pragma mark - MPPromotion
/**
 This class describes a promotion.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let promotion = MPPromotion()

 promotion.promotionId = "xyz123"
 
 promotion.name = "Promotion name"
 
 promotion.position = "bottom banner"
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPPromotion *promotion = [[MPPromotion alloc] init];
 
 promotion.promotionId = &#64;"xyz123";
 
 promotion.name = &#64;"Promotion name";
 
 promotion.position = &#64;"bottom banner";
 </code></pre>
 
 @see MPPromotionContainer
 */
@interface MPPromotion : NSObject <NSCopying, NSCoding>

/**
 Description for the promotion creative.
 */
@property (nonatomic, strong, nullable) NSString *creative;

/**
 Promotion name.
 */
@property (nonatomic, strong, nullable) NSString *name;

/**
 Promotion display position.
 */
@property (nonatomic, strong, nullable) NSString *position;

/**
 Promotion identifier.
 */
@property (nonatomic, strong, nullable) NSString *promotionId;

@end


#pragma mark - MPPromotionContainer
/**
 This class is a container for the information that represents a collection promotions (one or more).
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let promotionContainer = MPPromotionContainer(action: MPPromotionAction.View, promotion: promotion1)
 
 let commerceEvent = MPCommerceEvent(promotionContainer: promotionContainer)
 
 let mParticle = MParticle.sharedInstance()
 
 mParticle.logCommerceEvent(commerceEvent)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion1];
 
 MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
 
 MParticle *mParticle = [MParticle sharedInstance];
 
 [mParticle logCommerceEvent:commerceEvent];
 </code></pre>
 
 @see MPPromotion
 @see MPCommerceEvent
 @see mParticle
 */
@interface MPPromotionContainer : NSObject <NSCopying, NSCoding>

/**
 List of promotions under an <i>action</i>
 */
@property (nonatomic, strong, readonly, nullable) NSArray<MPPromotion *> *promotions;

/**
 A value from the <b>MPPromotionAction</b> enum describing the promotion action.
 */
@property (nonatomic, unsafe_unretained, readonly) MPPromotionAction action;

/**
 Initializes an instance of MPPromotionContainer with an action and a promotion.
 
 @param action A value from the <b>MPPromotionAction</b> enum describing the promotion action
 @param promotion An instance of MPPromotion
 
 @see MPPromotionAction
 */
- (nonnull instancetype)initWithAction:(MPPromotionAction)action promotion:(nullable MPPromotion *)promotion;

/**
 Adds a promotion to the list of promotions to have <i>action</i> applied to.
 
 @param promotion An instance of MPPromotion
 */
- (void)addPromotion:(nonnull MPPromotion *)promotion;

@end
