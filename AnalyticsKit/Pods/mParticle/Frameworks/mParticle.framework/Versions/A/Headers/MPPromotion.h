//
//  MPPromotion.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

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
@property (nonatomic, strong) NSString *creative;

/**
 Promotion name.
 */
@property (nonatomic, strong) NSString *name;

/**
 Promotion display position.
 */
@property (nonatomic, strong) NSString *position;

/**
 Promotion identifier.
 */
@property (nonatomic, strong) NSString *promotionId;

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
@property (nonatomic, strong, readonly) NSArray *promotions;

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
- (instancetype)initWithAction:(MPPromotionAction)action promotion:(MPPromotion *)promotion;

/**
 Adds a promotion to the list of promotions to have <i>action</i> applied to.
 
 @param promotion An instance of MPPromotion
 */
- (void)addPromotion:(MPPromotion *)promotion;

@end
