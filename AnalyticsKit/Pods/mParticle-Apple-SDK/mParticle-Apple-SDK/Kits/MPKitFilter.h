#import <Foundation/Foundation.h>

@class MPCommerceEvent;
@class MPBaseEvent;
@class MPEventProjection;
@class MPConsentState;

@interface MPKitFilter : NSObject

@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *appliedProjections;
@property (nonatomic, strong, readonly, nullable) NSDictionary *filteredAttributes;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *originalCommerceEvent;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *originalEvent;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *forwardCommerceEvent;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *forwardEvent;
@property (nonatomic, strong, readonly, nullable) MPConsentState *forwardConsentState;
@property (nonatomic, readonly) BOOL shouldFilter;

- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(nullable NSDictionary *)filteredAttributes;
- (nonnull instancetype)initWithEvent:(nonnull MPBaseEvent *)event shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithEvent:(nonnull MPBaseEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPEventProjection *> *)appliedProjections;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPEventProjection *> *)appliedProjections;
- (nonnull instancetype)initWithConsentState:(nonnull MPConsentState *)state shouldFilter:(BOOL)shouldFilter;

@end
