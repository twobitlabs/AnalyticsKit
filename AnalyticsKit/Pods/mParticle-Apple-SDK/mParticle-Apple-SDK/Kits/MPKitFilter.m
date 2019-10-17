#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPConsentState.h"

@implementation MPKitFilter

- (id)init {
    return [self initWithFilter:NO filteredAttributes:nil];
}

- (instancetype)initWithFilter:(BOOL)shouldFilter {
    return [self initWithFilter:shouldFilter filteredAttributes:nil];
}

- (instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(NSDictionary *)filteredAttributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldFilter = shouldFilter;
    _filteredAttributes = filteredAttributes;
    _originalEvent = nil;
    _forwardEvent = nil;
    
    return self;
}

- (instancetype)initWithEvent:(MPBaseEvent *)event shouldFilter:(BOOL)shouldFilter {
    return [self initWithEvent:event shouldFilter:shouldFilter appliedProjections:nil];
}

- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray<MPEventProjection *> *)appliedProjections {
    self = [self initWithFilter:shouldFilter filteredAttributes:event.customAttributes];
    if (!self) {
        return nil;
    }
    
    _originalEvent = event;
    _forwardEvent = event;
    _appliedProjections = appliedProjections;
    
    return self;
}

- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter {
    return [self initWithCommerceEvent:commerceEvent shouldFilter:shouldFilter appliedProjections:nil];
}

- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray<MPEventProjection *> *)appliedProjections {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldFilter = shouldFilter;
    _originalCommerceEvent = commerceEvent;
    _forwardCommerceEvent = commerceEvent;
    _appliedProjections = appliedProjections;
    
    return self;
}

- (nonnull instancetype)initWithConsentState:(nonnull MPConsentState *)state shouldFilter:(BOOL)shouldFilter {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldFilter = shouldFilter;
    _forwardConsentState = state;
    
    return self;
}

@end
