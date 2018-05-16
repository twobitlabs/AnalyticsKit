#import "MPKitFilter.h"
#import "MPEvent.h"

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
    _forwardEvent = nil;
    
    return self;
}

- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter {
    return [self initWithEvent:event shouldFilter:shouldFilter appliedProjections:nil];
}

- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray<MPEventProjection *> *)appliedProjections {
    self = [self initWithFilter:shouldFilter filteredAttributes:event.info];
    if (!self) {
        return nil;
    }
    
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
    _forwardCommerceEvent = commerceEvent;
    _appliedProjections = appliedProjections;
    
    return self;
}

@end
