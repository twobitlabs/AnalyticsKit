#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPIConstants.h"
#import "MPCart.h"
#import "MPCart+Dictionary.h"
#import "MPEnums.h"
#include <vector>
#include "EventTypeName.h"
#import "MPEvent.h"
#import "MPCommerceEventInstruction.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "mParticle.h"
#import "MPILogger.h"

using namespace std;
using namespace mParticle;

// Internal keys
NSString *const kMPCECheckoutOptions = @"co";
NSString *const kMPCECurrency = @"cu";
NSString *const kMPCEProducts = @"pl";
NSString *const kMPCEProductListName = @"pal";
NSString *const kMPCEProductListSource = @"pls";
NSString *const kMPCEAction = @"an";
NSString *const kMPCECheckoutStep = @"cs";
NSString *const kMPCEScreenName = @"sn";
NSString *const kMPCENonInteractive = @"ni";
NSString *const kMPCEPromotions = @"pm";
NSString *const kMPCEImpressions = @"pi";
NSString *const kMPCEImpressionList = @"pil";
NSString *const kMPCEProductAction = @"pd";
NSString *const kMPCEUserDefinedAttributes = @"attrs";
NSString *const kMPCEShoppingCartState = @"sc";
NSString *const kMPCEInstructionsKey = @"instructions";
NSString *const kMPExpCECheckoutOptions = @"Checkout Options";
NSString *const kMPExpCECurrency = @"Currency Code";
NSString *const kMPExpCEProductListName = @"Product Action List";
NSString *const kMPExpCEProductListSource = @"Product List Source";
NSString *const kMPExpCECheckoutStep = @"Checkout Step";
NSString *const kMPExpCEProductImpressionList = @"Product Impression List";
NSString *const kMPExpCEProductCount = @"Product Count";

const NSUInteger kMPNumberOfCommerceEventActions = 10;

static NSArray *actionNames;

@interface MPCommerceEvent() {
    MPCommerceEventKind commerceEventKind;
    MPEventType type;
}

@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableDictionary *beautifiedAttributes;
@property (nonatomic, strong) NSMutableArray<MPProduct *> *latestAddedProducts;
@property (nonatomic, strong) NSMutableArray<MPProduct *> *latestRemovedProducts;
@property (nonatomic, strong) NSMutableDictionary<NSString *, __kindof NSSet<MPProduct *> *> *productImpressions;
@property (nonatomic, strong) NSMutableArray<MPProduct *> *productsList;
@property (nonatomic, strong) NSMutableDictionary *userDefinedAttributes;
@property (nonatomic, strong) NSDictionary *shoppingCartState;
@end

@implementation MPCommerceEvent

@synthesize transactionAttributes = _transactionAttributes;
@synthesize beautifiedAttributes = _beautifiedAttributes;
@synthesize userDefinedAttributes = _userDefinedAttributes;
@synthesize currency = _currency;
@synthesize screenName = _screenName;
@synthesize nonInteractive = _nonInteractive;

+ (void)initialize {
    actionNames = @[@"add_to_cart", @"remove_from_cart", @"add_to_wishlist", @"remove_from_wishlist", @"checkout", @"checkout_option", @"click", @"view_detail", @"purchase", @"refund"];
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    commerceEventKind = MPCommerceEventKindUnknown;
    
    return self;
}

- (instancetype)initWithAction:(MPCommerceEventAction)action {
    return [self initWithAction:action product:nil];
}

- (instancetype)initWithAction:(MPCommerceEventAction)action product:(MPProduct *)product {
    self = [super init];
    if (!self) {
        return nil;
    }
    _shoppingCartState = [[MParticle sharedInstance].identity.currentUser.cart dictionaryRepresentation];
    commerceEventKind = MPCommerceEventKindProduct;
    self.action = action;
    [self setEventType];

    if (product) {
        [self addProduct:product];
    }
    
    return self;
}

- (instancetype)initWithImpressionName:(NSString *)listName product:(MPProduct *)product {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    commerceEventKind = MPCommerceEventKindImpression;
    [self setEventType];

    if (listName && product) {
        [self addImpression:product listName:listName];
    }
    
    return self;
}

- (instancetype)initWithPromotionContainer:(MPPromotionContainer *)promotionContainer {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    commerceEventKind = MPCommerceEventKindPromotion;

    if (!MPIsNull(promotionContainer)) {
        _promotionContainer = promotionContainer;
        [self setEventType];
    }
    
    return self;
}

- (NSString *)description {
    __block NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ {\n", [[self class] description]];
    
    if (_attributes.count > 0) {
        [description appendString:@"  Attributes:{\n"];
        
        [_attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [description appendFormat:@"    %@:%@\n", key, obj];
        }];
        
        [description appendString:@"  }\n"];
    }
    
    if (_userDefinedAttributes.count > 0) {
        [description appendString:@"  User Defined Attributes:{\n"];
        
        [_userDefinedAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [description appendFormat:@"    %@:%@\n", key, obj];
        }];
        
        [description appendString:@"  }\n"];
    }
    
    if (self.transactionAttributes) {
        [description appendFormat:@"%@", self.transactionAttributes];
    }
    
    if (_productImpressions.count > 0) {
        [description appendString:@"  Impressions:{\n"];
        
        [_productImpressions enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableSet *products, BOOL *stop) {
            for (MPProduct *product in products) {
                [description appendFormat:@"    %@:%@\n", key, [product dictionaryRepresentation]];
            }
        }];
        
        [description appendString:@"  }\n"];
    }
    
    if (_promotionContainer) {
        [description appendFormat:@"%@", _promotionContainer];
    }
    
    [description appendString:@"}\n"];
    
    return (NSString *)description;
}

#pragma mark Private accessors
- (NSMutableDictionary *)attributes {
    if (_attributes) {
        return _attributes;
    }
    
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:3];
    return _attributes;
}

- (NSMutableDictionary *)beautifiedAttributes {
    if (_beautifiedAttributes) {
        return _beautifiedAttributes;
    }
    
    NSMutableDictionary *beautifiedAttributes = [NSMutableDictionary dictionary];
    NSDictionary *attributeNameMapping = @{
                                           kMPCECheckoutOptions: kMPExpCECheckoutOptions,
                                           kMPCEProductListName: kMPExpCEProductListName,
                                           kMPCEProductListSource: kMPExpCEProductListSource
                                           };
    
    [attributeNameMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull shortKey, id  _Nonnull longKey, BOOL * _Nonnull stop) {
        id value = self.attributes[shortKey];
        if (value) {
            beautifiedAttributes[longKey] = value;
        }
    }];
    
    if (_currency) {
        beautifiedAttributes[kMPExpCECurrency] = _currency;
    }
    
    NSDictionary *transactionDictionary = [self.transactionAttributes beautifiedDictionaryRepresentation];
    [beautifiedAttributes addEntriesFromDictionary:transactionDictionary];
    
    return beautifiedAttributes;
}

- (NSMutableArray<MPProduct *> *)latestAddedProducts {
    if (_latestAddedProducts) {
        return _latestAddedProducts;
    }
    
    _latestAddedProducts = [[NSMutableArray alloc] initWithCapacity:1];
    return _latestAddedProducts;
}

- (NSMutableArray<MPProduct *> *)latestRemovedProducts {
    if (_latestRemovedProducts) {
        return _latestRemovedProducts;
    }
    
    _latestRemovedProducts = [[NSMutableArray alloc] initWithCapacity:1];
    return _latestRemovedProducts;
}

- (NSMutableDictionary *)productImpressions {
    if (_productImpressions) {
        return _productImpressions;
    }
    
    _productImpressions = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _productImpressions;
}

- (NSMutableArray *)productsList {
    if (_productsList) {
        return _productsList;
    }
    
    _productsList = [[NSMutableArray alloc] initWithCapacity:1];
    return _productsList;
}

- (NSMutableDictionary *)userDefinedAttributes {
    if (_userDefinedAttributes) {
        return _userDefinedAttributes;
    }
    
    _userDefinedAttributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _userDefinedAttributes;
}

#pragma mark Private methods
- (void)setEventType {
    static const vector<EventType> productActionEventType {AddToCart, RemoveFromCart, AddToWishlist, RemoveFromWishlist, Checkout, CheckoutOption, Click, ViewDetail, Purchase, Refund};
    static const vector<EventType> promotionActionEventType {PromotionClick, PromotionView};
    
    switch (commerceEventKind) {
        case MPCommerceEventKindProduct:
            type = static_cast<MPEventType>(productActionEventType[(NSUInteger)self.action]);
            break;
            
        case MPCommerceEventKindPromotion:
            type = _promotionContainer ? static_cast<MPEventType>(promotionActionEventType[(NSUInteger)self.promotionContainer.action]) : MPEventTypeOther;
            break;
            
        case MPCommerceEventKindImpression:
            type = static_cast<MPEventType>(Impression);
            break;

        default:
            type = static_cast<MPEventType>(Other);
            break;
    }
}

#pragma mark Subscripting
- (id)objectForKeyedSubscript:(NSString *const)key {
    NSAssert(key != nil, @"'key' cannot be nil.");
    
    id object = [self.userDefinedAttributes objectForKey:key];
    return object;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    NSAssert(key != nil, @"'key' cannot be nil.");
    NSAssert(obj != nil, @"'obj' cannot be nil.");
    NSAssert([obj isKindOfClass:[NSString class]], @"'obj' for custom attributes must be a NSString");
    
    if (obj == nil) {
        return;
    }
    
    [self.userDefinedAttributes setObject:obj forKey:key];
}

- (NSArray *)allKeys {
    return [self.userDefinedAttributes allKeys];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPCommerceEvent *copyObject = [[[self class] alloc] init];

    if (copyObject) {
        copyObject->_attributes = _attributes ? [[NSMutableDictionary alloc] initWithDictionary:[_attributes copy]] : nil;
        copyObject->_beautifiedAttributes = _beautifiedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_beautifiedAttributes copy]] : nil;
        copyObject->_productsList = _productsList ? [[NSMutableArray alloc] initWithArray:[_productsList copy]] : nil;
        copyObject->_productImpressions = _productImpressions ? [[NSMutableDictionary alloc] initWithDictionary:[_productImpressions copy]] : nil;
        copyObject.promotionContainer = [_promotionContainer copy];
        copyObject.transactionAttributes = [_transactionAttributes copy];
        copyObject->_userDefinedAttributes = _userDefinedAttributes ? [[NSMutableDictionary alloc] initWithDictionary:[_userDefinedAttributes copy]] : nil;
        copyObject->type = type;
        copyObject->commerceEventKind = commerceEventKind;
        copyObject->_timestamp = [_timestamp copy];
        copyObject->_shoppingCartState = _shoppingCartState ? [[NSMutableDictionary alloc] initWithDictionary:[_shoppingCartState copy]] : nil;
        copyObject->_currency = [_currency copy];
    }
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:type forKey:@"type"];
    [coder encodeInteger:commerceEventKind forKey:@"commerceEventKind"];
    
    if (_attributes) {
        [coder encodeObject:_attributes forKey:@"attributes"];
    }
    
    if (_beautifiedAttributes) {
        [coder encodeObject:_beautifiedAttributes forKey:@"beautifiedAttributes"];
    }
    
    if (_productsList) {
        [coder encodeObject:_productsList forKey:@"productsList"];
    }
    
    if (_productImpressions) {
        [coder encodeObject:_productImpressions forKey:@"productImpressions"];
    }
    
    if (_promotionContainer) {
        [coder encodeObject:_promotionContainer forKey:@"promotionContainer"];
    }
    
    if (_transactionAttributes) {
        [coder encodeObject:_transactionAttributes forKey:@"transactionAttributes"];
    }
    
    if (_userDefinedAttributes) {
        [coder encodeObject:_userDefinedAttributes forKey:@"userDefinedAttributes"];
    }
    
    if (_timestamp) {
        [coder encodeObject:_timestamp forKey:@"timestamp"];
    }
    
    if (_currency) {
        [coder encodeObject:_currency forKey:@"currency"];
    }
    
    if (_screenName) {
        [coder encodeObject:_screenName forKey:@"screenName"];
    }
    
    if (_nonInteractive) {
        [coder encodeBool:_nonInteractive forKey:@"nonInteractive"];
    }
    
    if (_shoppingCartState) {
        [coder encodeObject:_shoppingCartState forKey:@"shoppingCartState"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    NSDictionary *dictionary = [coder decodeObjectForKey:@"attributes"];
    if (dictionary.count > 0) {
        self->_attributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    dictionary = [coder decodeObjectForKey:@"beautifiedAttributes"];
    if (dictionary) {
        self->_beautifiedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    dictionary = [coder decodeObjectForKey:@"productImpressions"];
    if (dictionary.count > 0) {
        self->_productImpressions = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    @try {
        dictionary = [coder decodeObjectForKey:@"userDefinedAttributes"];
    }
    
    @catch ( NSException *e) {
        dictionary = nil;
        MPILogError(@"Exception decoding MPCommerceEvent User Defined Attributes: %@", [e reason]);
    }
    
    @finally {
        if (dictionary.count > 0) {
            self->_userDefinedAttributes = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        }
    }
    
    NSArray *array = [coder decodeObjectForKey:@"productsList"];
    if (array.count > 0) {
        self->_productsList = [[NSMutableArray alloc] initWithArray:array];
    }
    
    self->_timestamp = [coder decodeObjectForKey:@"timestamp"];
    self->_currency = [coder decodeObjectForKey:@"currency"];
    self->_screenName = [coder decodeObjectForKey:@"screenName"];
    self->_nonInteractive = [coder decodeBoolForKey:@"nonInteractive"];
    
    self.promotionContainer = [coder decodeObjectForKey:@"promotionContainer"];
    self.transactionAttributes = [coder decodeObjectForKey:@"transactionAttributes"];
    type = (MPEventType)[coder decodeIntegerForKey:@"type"];
    commerceEventKind = (MPCommerceEventKind)[coder decodeIntegerForKey:@"commerceEventKind"];
    
    dictionary = [coder decodeObjectForKey:@"shoppingCartState"];
    if (dictionary) {
        self->_shoppingCartState = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    
    return self;
}

#pragma mark MPCommerceEvent+Dictionary
- (NSString *)actionNameForAction:(MPCommerceEventAction)action {
    if (action >= kMPNumberOfCommerceEventActions) {
        return nil;
    }
    
    return actionNames[(NSUInteger)action];
}

- (MPCommerceEventAction)actionWithName:(NSString *)actionName {
    return (MPCommerceEventAction)[actionNames indexOfObject:actionName];
}

- (void)addProducts:(nonnull NSArray<MPProduct *> *)products {
    for (MPProduct *product in products) {
        [self addProduct:product];
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (_userDefinedAttributes.count > 0) {
        dictionary[kMPCEUserDefinedAttributes] = [_userDefinedAttributes transformValuesToString];
    }

    if (_shoppingCartState) {
        dictionary[kMPCEShoppingCartState] = _shoppingCartState;
    }
    
    if (_currency) {
        dictionary[kMPCECurrency] = _currency;
    }

    if (_screenName) {
        dictionary[kMPCEScreenName] = _screenName;
    }
    
    if (_nonInteractive) {
        dictionary[kMPCENonInteractive] = @(_nonInteractive);
    }
    
    // Product/Promotion
    switch (commerceEventKind) {
        case MPCommerceEventKindProduct: {
            // Product Action
            NSMutableDictionary *productAction = [[NSMutableDictionary alloc] initWithCapacity:12];
            
            if (_attributes.count > 0) {
                [productAction addEntriesFromDictionary:[_attributes transformValuesToString]];
            }

            // Products
            __block double calculatedRevenue = 0;
            if (_productsList.count > 0) {
                __block NSMutableArray *products = [[NSMutableArray alloc] initWithCapacity:_productsList.count];
                
                [_productsList enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                    NSDictionary *productDictionary = [product commerceDictionaryRepresentation];
                    
                    if (productDictionary) {
                        [products addObject:productDictionary];
                        calculatedRevenue += [product.quantity doubleValue] * [product.price doubleValue];
                    }
                }];
                
                if (products.count > 0) {
                    productAction[kMPCEProducts] = products;
                }
            }
            
            if (productAction.count > 0) {
                dictionary[kMPCEProductAction] = productAction;
            }

            // Transaction attributes
            if (_transactionAttributes.revenue == nil) {
                calculatedRevenue += [_transactionAttributes.shipping doubleValue] + [_transactionAttributes.tax doubleValue];
                _transactionAttributes.revenue = @(calculatedRevenue);
            }
            
            NSDictionary *transactionAttributes = [_transactionAttributes dictionaryRepresentation];
            if (transactionAttributes) {
                [productAction addEntriesFromDictionary:transactionAttributes];
            }
        }
            break;
            
        case MPCommerceEventKindPromotion: {
            if (_promotionContainer) {
                NSDictionary *promotionDictionary = [_promotionContainer dictionaryRepresentation];
                
                if (promotionDictionary) {
                    dictionary[kMPCEPromotions] = promotionDictionary;
                }
            }
        }
            break;
            
        case MPCommerceEventKindImpression: {
            if (_productImpressions.count > 0) {
                __block NSMutableArray *impressions = [[NSMutableArray alloc] initWithCapacity:_productImpressions.count];
                
                [_productImpressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSMutableSet *listedProducts, BOOL *stop) {
                    if (listedProducts.count > 0) {
                        NSMutableArray *productRepresentations = [[NSMutableArray alloc] initWithCapacity:listedProducts.count];
                        for (MPProduct *product in listedProducts) {
                            NSDictionary *productDictionary = [product commerceDictionaryRepresentation];
                            
                            if (productDictionary) {
                                [productRepresentations addObject:productDictionary];
                            }
                        }
                        
                        NSDictionary *impressionDictionary = @{kMPCEImpressionList:listName,
                                                               kMPCEProducts:productRepresentations};
                        
                        [impressions addObject:impressionDictionary];
                    }
                }];
                
                if (impressions.count > 0) {
                    dictionary[kMPCEImpressions] = impressions;
                }
            }
        }
            break;
            
        case MPCommerceEventKindUnknown:
            return nil;
            break;
    }
    
    return dictionary.count > 0 ? (NSDictionary *)dictionary : nil;
}

- (NSArray<MPCommerceEventInstruction *> *)expandedInstructions {
    __block vector<MPCommerceEventInstruction *> expansionInstructions;
    NSString *eventName;
    __block MPEvent *event;
    __block NSMutableDictionary *eventInfo;
    __block MPProduct *product;
    __block NSDictionary *productDictionary;
    __block MPCommerceEventInstruction *commerceEventInstruction;
    
    switch (commerceEventKind) {
        case MPCommerceEventKindProduct: {
            MPCommerceEventAction action = self.action;
            BOOL purchaseOrRefund = action == MPCommerceEventActionPurchase || action == MPCommerceEventActionRefund;
            MPCommerceInstruction instruction = purchaseOrRefund ? MPCommerceInstructionTransaction : MPCommerceInstructionEvent;
            NSString *actionName = [self actionNameForAction:action];
            NSUInteger productCount = _productsList.count;
            
            // Expanding n products
            if (productCount > 0) {
                eventName = [NSString stringWithFormat:@"eCommerce - %@ - Item", actionName];
                
                for (product in _productsList) {
                    event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
                    eventInfo = [[NSMutableDictionary alloc] initWithCapacity:4];

                    productDictionary = [product beautifiedDictionaryRepresentation];
                    if (productDictionary) {
                        [eventInfo addEntriesFromDictionary:productDictionary];
                    }

                    if (purchaseOrRefund && self.transactionAttributes.transactionId) {
                        eventInfo[kMPExpTATransactionId] = self.transactionAttributes.transactionId;
                    }

                    if (_userDefinedAttributes.count > 0) {
                        [eventInfo addEntriesFromDictionary:_userDefinedAttributes];
                    }

                    if (eventInfo.count > 0) {
                        event.info = eventInfo;
                    }

                    commerceEventInstruction = [[MPCommerceEventInstruction alloc] initWithInstruction:instruction event:event product:product];
                    expansionInstructions.push_back(commerceEventInstruction);
                }
            }

            // Expanding the transaction summary (+1)
            if (purchaseOrRefund) {
                eventName = [NSString stringWithFormat:@"eCommerce - %@ - Total", actionName];
                event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
                
                eventInfo = [[NSMutableDictionary alloc] initWithCapacity:4];
                eventInfo[kMPExpCECurrency] = self.currency ? : @"USD";
                eventInfo[kMPExpCEProductCount] = @(productCount);
                
                NSDictionary *transactionDictionary = [_transactionAttributes beautifiedDictionaryRepresentation];
                if (transactionDictionary) {
                    [eventInfo addEntriesFromDictionary:transactionDictionary];
                }
                
                if (self.productListName) {
                    eventInfo[kMPExpCEProductListName] = self.productListName;
                }
                
                if (self.productListSource) {
                    eventInfo[kMPExpCEProductListSource] = self.productListSource;
                }
                
                if (self.checkoutOptions) {
                    eventInfo[kMPExpCECheckoutOptions] = self.checkoutOptions;
                }
                
                if (self.checkoutStep != NSNotFound) {
                    eventInfo[kMPExpCECheckoutStep] = [@(self.checkoutStep) stringValue];
                }
                
                if (_userDefinedAttributes.count > 0) {
                    [eventInfo addEntriesFromDictionary:_userDefinedAttributes];
                }

                if (eventInfo.count > 0) {
                    event.info = eventInfo;
                }

                commerceEventInstruction = [[MPCommerceEventInstruction alloc] initWithInstruction:MPCommerceInstructionEvent event:event];
                expansionInstructions.push_back(commerceEventInstruction);
            }
        }
            break;
            
        case MPCommerceEventKindPromotion: {
            eventName = [NSString stringWithFormat:@"eCommerce - %@ - Item", [self.promotionContainer actionNameForAction:self.promotionContainer.action]];
            event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
            eventInfo = [[NSMutableDictionary alloc] initWithCapacity:4];

            NSDictionary *promotionDictionary = [self.promotionContainer beautifiedDictionaryRepresentation];
            if (promotionDictionary) {
                [eventInfo addEntriesFromDictionary:promotionDictionary];
            }

            if (_userDefinedAttributes.count > 0) {
                [eventInfo addEntriesFromDictionary:_userDefinedAttributes];
            }

            if (eventInfo.count > 0) {
                event.info = eventInfo;
            }

            commerceEventInstruction = [[MPCommerceEventInstruction alloc] initWithInstruction:MPCommerceInstructionEvent event:event];
            expansionInstructions.push_back(commerceEventInstruction);
        }
            break;
            
        case MPCommerceEventKindImpression: {
            if (_productImpressions.count > 0) {
                eventName = @"eCommerce - Impression - Item";
                
                [_productImpressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSMutableSet *listedProducts, BOOL *stop) {
                    if (listedProducts.count > 0) {
                        for (product in listedProducts) {
                            event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
                            eventInfo = [[NSMutableDictionary alloc] initWithCapacity:4];
                            eventInfo[kMPExpCEProductImpressionList] = listName;

                            productDictionary = [product beautifiedDictionaryRepresentation];
                            if (productDictionary) {
                                [eventInfo addEntriesFromDictionary:productDictionary];
                            }
                            
                            if (self->_userDefinedAttributes.count > 0) {
                                [eventInfo addEntriesFromDictionary:self->_userDefinedAttributes];
                            }

                            if (eventInfo.count > 0) {
                                event.info = eventInfo;
                            }

                            commerceEventInstruction = [[MPCommerceEventInstruction alloc] initWithInstruction:MPCommerceInstructionEvent event:event];
                            expansionInstructions.push_back(commerceEventInstruction);
                        }
                    }
                }];
            }
        }
            break;
            
        case MPCommerceEventKindUnknown:
            return nil;
            break;
    }
    
    NSArray<MPCommerceEventInstruction *> *expInstructions = [NSArray arrayWithObjects:&expansionInstructions[0] count:expansionInstructions.size()];
    return expInstructions;
}

- (NSArray<MPProduct *> *const)addedProducts {
    return commerceEventKind == MPCommerceEventKindProduct ? (NSArray *)_latestAddedProducts : nil;
}

- (MPCommerceEventKind)kind {
    return commerceEventKind;
}

- (void)removeProducts:(NSArray<MPProduct *> *)products {
    for (MPProduct *product in products) {
        [self removeProduct:product];
    }
}

- (NSArray<MPProduct *> *const)removedProducts {
    return commerceEventKind == MPCommerceEventKindProduct ? (NSArray *)_latestRemovedProducts : nil;
}

- (void)resetLatestProducts {
    _latestAddedProducts = nil;
    _latestRemovedProducts = nil;
}

- (MPEventType)type {
    return type;
}

- (void)setImpressions:(NSDictionary *)impressions {
    self.productImpressions = impressions ? [[NSMutableDictionary alloc] initWithDictionary:impressions] : nil;
}

- (void)setProducts:(NSArray<MPProduct *> *)products {
    self.productsList = products ? [[NSMutableArray alloc] initWithArray:products] : nil;
}

- (NSMutableDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)copyImpressionsMatchingHashedProperties:(NSDictionary *)hashedMap {
    __block NSMutableDictionary<NSString *, __kindof NSSet<MPProduct *> *> *copyProductImpressions = [[NSMutableDictionary alloc] init];
    
    [_productImpressions enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableSet *listedProducts, BOOL *stop) {
        __block NSMutableSet<MPProduct *> *filteredProducts = [[NSMutableSet alloc] init];
        
        [listedProducts enumerateObjectsUsingBlock:^(MPProduct *product, BOOL *stop) {
            MPProduct *filteredProduct = [product copyMatchingHashedProperties:hashedMap];
            
            if (filteredProduct) {
                [filteredProducts addObject:filteredProduct];
            }
        }];
        
        copyProductImpressions[key] = filteredProducts;
    }];
    
    return copyProductImpressions;
}

- (NSDate *)timestamp {
    return _timestamp;
}

- (void)setTimestamp:(NSDate *)timestamp {
    _timestamp = timestamp;
}

#pragma mark Public accessors
- (NSString *)checkoutOptions {
    return self.attributes[kMPCECheckoutOptions];
}

- (void)setCheckoutOptions:(NSString *)checkoutOptions {
    if (checkoutOptions) {
        self.attributes[kMPCECheckoutOptions] = checkoutOptions;
    } else {
        [self.attributes removeObjectForKey:kMPCECheckoutOptions];
    }
}

- (NSString *)currency {
    return _currency;
}

- (void)setCurrency:(NSString *)currency {
    _currency = currency;
}

- (NSDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)impressions {
    return _productImpressions.count > 0 ? (NSDictionary *)_productImpressions : nil;
}

- (NSArray<MPProduct *> *)products {
    return _productsList.count > 0 ? (NSArray *)_productsList : nil;
}

- (NSString *)productListName {
    return self.attributes[kMPCEProductListName];
}

- (void)setProductListName:(NSString *)productListName {
    if (productListName) {
        self.attributes[kMPCEProductListName] = productListName;
    } else {
        [self.attributes removeObjectForKey:kMPCEProductListName];
    }
}

- (NSString *)productListSource {
    return self.attributes[kMPCEProductListSource];
}

- (void)setProductListSource:(NSString *)productListSource {
    if (productListSource) {
        self.attributes[kMPCEProductListSource] = productListSource;
    } else {
        [self.attributes removeObjectForKey:kMPCEProductListSource];
    }
}

- (void)setPromotionContainer:(MPPromotionContainer *)promotionContainer {
    if (commerceEventKind == MPCommerceEventKindUnknown) {
        commerceEventKind = MPCommerceEventKindPromotion;
    }
    
    NSAssert(commerceEventKind == MPCommerceEventKindPromotion, @"Promotions and Products cannot be mixed in the same commerce event.");

    _promotionContainer = promotionContainer;
}

- (MPCommerceEventAction)action {
    return [self actionWithName:self.attributes[kMPCEAction]];
}

- (void)setAction:(MPCommerceEventAction)action {
    self.attributes[kMPCEAction] = [self actionNameForAction:action];
}

- (NSInteger)checkoutStep {
    NSInteger checkoutStep = self.attributes[kMPCECheckoutStep] ? [self.attributes[kMPCECheckoutStep] integerValue] : NSNotFound;
    return checkoutStep;
}

- (void)setCheckoutStep:(NSInteger)checkoutStep {
    NSNumber *checkoutStepNumber = @(checkoutStep);
    self.attributes[kMPCECheckoutStep] = checkoutStepNumber;
}

#pragma mark Public methods
- (void)addImpression:(MPProduct *)product listName:(NSString *)listName {
    NSAssert(!MPIsNull(listName), @"'listName' cannot be nil/null.");
    NSAssert(listName.length > 0, @"'listName' length cannot be 0.");
    NSAssert(product != nil, @"'product' cannot be nil.");
    NSAssert([product isKindOfClass:[MPProduct class]], @"'product' is not an instance of MPProduct.");
    
    if (commerceEventKind == MPCommerceEventKindUnknown) {
        commerceEventKind = MPCommerceEventKindImpression;
    }
    
    NSAssert(commerceEventKind == MPCommerceEventKindImpression, @"Impressions, Products and Promotions cannot be mixed in the same commerce event.");

    if (MPIsNull(listName) || listName.length == 0 || MPIsNull(product) || ![product isKindOfClass:[MPProduct class]]) {
        return;
    }

    NSMutableSet *listedProducts = self.productImpressions[listName];
    
    if (listedProducts) {
        [listedProducts addObject:product];
    } else {
        listedProducts = [[NSMutableSet alloc] initWithCapacity:1];
        [listedProducts addObject:product];
        
        self.productImpressions[listName] = listedProducts;
    }
}

- (void)addProduct:(MPProduct *)product {
    NSAssert(!MPIsNull(product), @"'product' cannot be nil/null.");
    NSAssert([product isKindOfClass:[MPProduct class]], @"'product' is not an instance of MPProduct.");

    if (commerceEventKind == MPCommerceEventKindUnknown) {
        commerceEventKind = MPCommerceEventKindProduct;
    }
    
    NSAssert(commerceEventKind == MPCommerceEventKindProduct, @"Products, Impressions, and Promotions cannot be mixed in the same commerce event.");

    if (MPIsNull(product) || ![product isKindOfClass:[MPProduct class]]) {
        return;
    }

    [self.productsList addObject:product];
    [self.latestAddedProducts addObject:product];
}

- (void)removeProduct:(MPProduct *)product {
    NSAssert(!MPIsNull(product), @"'product' cannot be nil/null.");
    NSAssert([product isKindOfClass:[MPProduct class]], @"'product' is not an instance of MPProduct.");
    
    if (commerceEventKind == MPCommerceEventKindUnknown) {
        commerceEventKind = MPCommerceEventKindProduct;
    }
    
    NSAssert(commerceEventKind == MPCommerceEventKindProduct, @"Products, Impressions, and Promotions cannot be mixed in the same commerce event.");
    
    if (MPIsNull(product) || ![product isKindOfClass:[MPProduct class]]) {
        return;
    }

    NSUInteger productIndex = [self.productsList indexOfObject:product];
    if (productIndex == NSNotFound) {
        [self.productsList addObject:product];
        [self.latestRemovedProducts addObject:product];
    } else {
        [self.latestRemovedProducts addObject:_productsList[productIndex]];
        [_productsList removeObjectAtIndex:productIndex];
    }
}

- (void)setCustomAttributes:(NSDictionary<NSString *, NSString *> *)customAttributes {
    if (customAttributes) {
        _userDefinedAttributes = [[NSMutableDictionary alloc] initWithDictionary:customAttributes copyItems:YES];
    } else {
        _userDefinedAttributes = nil;
    }
}

@end
