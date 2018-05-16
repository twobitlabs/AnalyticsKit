#import <Foundation/Foundation.h>

@class MPCommerceEvent;
@class MPPromotionContainer;
@class MPPromotion;
@class MPTransactionAttributes;
@class MPProduct;
@class MPIdentityApiRequest;

@interface MPConvertJS : NSObject

+ (MPCommerceEvent *)MPCommerceEvent:(NSDictionary *)json;
+ (MPPromotionContainer *)MPPromotionContainer:(NSDictionary *)json;
+ (MPPromotion *)MPPromotion:(NSDictionary *)json;
+ (MPTransactionAttributes *)MPTransactionAttributes:(NSDictionary *)json;
+ (MPProduct *)MPProduct:(NSDictionary *)json;
+ (MPIdentityApiRequest *)MPIdentityApiRequest:(NSDictionary *)json;

@end
