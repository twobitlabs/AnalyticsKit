#import <Foundation/Foundation.h>

@class MPCommerceEvent;
@class MPEvent;
@class MPEventProjection;

@interface MPKitFilter : NSObject

@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *appliedProjections;
@property (nonatomic, strong, readonly, nullable) NSDictionary *filteredAttributes;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *forwardCommerceEvent;
@property (nonatomic, strong, readonly, nullable) MPEvent *forwardEvent;
@property (nonatomic, readonly) BOOL shouldFilter;

- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(nullable NSDictionary *)filteredAttributes;
- (nonnull instancetype)initWithEvent:(nonnull MPEvent *)event shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithEvent:(nonnull MPEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPEventProjection *> *)appliedProjections;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPEventProjection *> *)appliedProjections;

@end
