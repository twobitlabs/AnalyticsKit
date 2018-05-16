#import "MPKitContainer.h"
#import "MPKitExecStatus.h"
#import "MPEnums.h"
#include "MessageTypeName.h"
#import "MPStateMachine.h"
#include "MPHasher.h"
#import "MPKitConfiguration.h"
#import <UIKit/UIKit.h>
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPILogger.h"
#import "MPKitFilter.h"
#include "EventTypeName.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEventProjection.h"
#include <map>
#import "MPAttributeProjection.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "NSArray+MPCaseInsensitive.h"
#import "MPIUserDefaults.h"
#include "MPBracket.h"
#import "MPConsumerInfo.h"
#import "MPForwardQueueItem.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPForwardQueueParameters.h"
#import "MPIntegrationAttributes.h"
#import "MPKitAPI.h"
#import "mParticle.h"

#define DEFAULT_ALLOCATION_FOR_KITS 2

NSString *const kitFileExtension = @"eks";
static NSMutableSet <id<MPExtensionKitProtocol>> *kitsRegistry;

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
- (void)executeKitsInitializedBlocks;
@end

@interface MPKitAPI ()

- (id)initWithKitCode:(NSNumber *)kitCode;

@end

@interface MPKitContainer() {
    dispatch_semaphore_t kitsSemaphore;
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>> brackets;
}

@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;
@property (nonatomic, unsafe_unretained) BOOL kitsInitialized;
@property (nonatomic, strong) NSDate *initializedTime;

@end


@implementation MPKitContainer

@synthesize kitsInitialized = _kitsInitialized;

+ (void)initialize {
    kitsRegistry = [[NSMutableSet alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _kitsInitialized = NO;
        _attributionInfo = [NSMutableDictionary dictionary];
        NSMutableDictionary *linkInfo = _attributionInfo;
        _initializedTime = [NSDate date];
        kitsSemaphore = dispatch_semaphore_create(1);
        
        _attributionCompletionHandler = [^void(MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error) {
            if (attributionResult && attributionResult.kitCode) {
                linkInfo[attributionResult.kitCode] = attributionResult;
            }
            if ([MParticle sharedInstance].options.onAttributionComplete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MParticle sharedInstance].options.onAttributionComplete(attributionResult, error);
                });
                
            }
        } copy];
        
        if (![MPStateMachine sharedInstance].optOut) {
            [self initializeKits];
        }
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

#pragma mark Notification handlers
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    SEL didBecomeActiveSelector = @selector(didBecomeActive);
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:didBecomeActiveSelector]) {
            [kitRegister.wrapperInstance didBecomeActive];
        }
    }
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.launchOptions = [notification userInfo];
    SEL launchOptionsSelector = @selector(setLaunchOptions:);
    SEL startSelector = @selector(start);
    
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
        
        if (kitInstance && ![kitInstance started]) {
            if ([kitInstance respondsToSelector:launchOptionsSelector]) {
                [kitInstance setLaunchOptions:stateMachine.launchOptions];
            }
            
            if ([kitInstance respondsToSelector:startSelector]) {
                @try {
                    [kitInstance start];
                }
                @catch (NSException *exception) {
                    MPILogError(@"Exception thrown while starting kit (%@): %@", kitInstance, exception);
                }
            }
        }
    }
}

#pragma mark Private accessors
- (NSMutableArray<MPForwardQueueItem *> *)forwardQueue {
    if (_forwardQueue) {
        return _forwardQueue;
    }
    
    _forwardQueue = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    return _forwardQueue;
}

- (BOOL)kitsInitialized {
    return _kitsInitialized;
}

- (void)setKitsInitialized:(BOOL)kitsInitialized {
    _kitsInitialized = kitsInitialized;
    
    if (_kitsInitialized) {
        [self replayQueuedItems];
        [[MParticle sharedInstance] executeKitsInitializedBlocks];
    }
}

#pragma mark Private methods
- (const std::shared_ptr<mParticle::Bracket>)bracketForKit:(NSNumber *)kitCode {
    NSAssert(kitCode != nil, @"Required parameter. It cannot be nil.");
    
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>>::iterator bracketIterator;
    bracketIterator = brackets.find(kitCode);
    
    shared_ptr<mParticle::Bracket> bracket = bracketIterator != brackets.end() ? bracketIterator->second : nullptr;
    return bracket;
}

- (void)flushSerializedKits {
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        [self freeKit:kitRegister.code];
    }
}

- (void)freeKit:(NSNumber *)kitCode {
    NSAssert(kitCode != nil, @"Required parameter. It cannot be nil.");
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];

    if (kitRegister.wrapperInstance) {
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(deinit)]) {
            [kitRegister.wrapperInstance deinit];
        }
        
        kitRegister.wrapperInstance = nil;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
        NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", kitCode, kitFileExtension]];
        
        if ([fileManager fileExistsAtPath:kitPath]) {
            [fileManager removeItemAtPath:kitPath error:nil];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:kitCode};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeInactiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
}

- (void)initializeKits {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];

    NSArray *directoryContents = [userDefaults getKitConfigurations];
    
    for (NSDictionary *kitConfigurationDictionary in directoryContents) {
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
        self.kitConfigurations[kitConfiguration.kitCode] = kitConfiguration;
        [self startKit:kitConfiguration.kitCode configuration:kitConfiguration];
        
        self.kitsInitialized = YES;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([MPStateMachine sharedInstance].logLevel >= MPILogLevelDebug) {
            NSArray<NSNumber *> *supportedKits = [self supportedKits];
            
            if (supportedKits.count > 0) {
                NSMutableString *listOfKits = [[NSMutableString alloc] initWithString:@"Included kits: {"];
                for (NSNumber *supportedKit in supportedKits) {
                    [listOfKits appendFormat:@"%@, ", [self nameForKitCode:supportedKit]];
                }
                
                [listOfKits deleteCharactersInRange:NSMakeRange(listOfKits.length - 2, 2)];
                [listOfKits appendString:@"}"];
                
                MPILogDebug(@"%@", listOfKits);
            }
        }
    });
}

- (NSDictionary *)methodMessageTypeMapping {
    NSString *messageTypeEvent = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Event).c_str() encoding:NSUTF8StringEncoding];
    
    NSDictionary *methodMessageTypeDictionary = @{@"logEvent:":messageTypeEvent,
                                                  @"logScreen:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::ScreenView).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logScreenEvent:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::ScreenView).c_str() encoding:NSUTF8StringEncoding],
                                                  @"beginSession":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::SessionStart).c_str() encoding:NSUTF8StringEncoding],
                                                  @"endSession":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::SessionEnd).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logTransaction:":messageTypeEvent,
                                                  @"logLTVIncrease:eventName:eventInfo:":messageTypeEvent,
                                                  @"leaveBreadcrumb:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logError:exception:topmostContext:eventInfo:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::CrashReport).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logNetworkPerformanceMeasurement:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::NetworkPerformance).c_str() encoding:NSUTF8StringEncoding],
                                                  @"profileChange:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Profile).c_str() encoding:NSUTF8StringEncoding],
                                                  @"setOptOut:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::OptOut).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logCommerceEvent:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::CommerceEvent).c_str() encoding:NSUTF8StringEncoding],
                                                  @"leaveBreadcrumb:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding]
                                                  };
    
    return methodMessageTypeDictionary;
}

- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)kitCode {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
    return kitRegister.name;
}

- (void)replayQueuedItems {
    if (!_forwardQueue) {
        return;
    }
    
    NSMutableArray<MPForwardQueueItem *> *forwardQueueCopy = _forwardQueue;
    _forwardQueue = nil;
    
    for (MPForwardQueueItem *forwardQueueItem in forwardQueueCopy) {
        switch (forwardQueueItem.queueItemType) {
            case MPQueueItemTypeEvent: {
                dispatch_async([MParticle messageQueue], ^{
                    [self forwardSDKCall:forwardQueueItem.selector event:forwardQueueItem.event messageType:forwardQueueItem.messageType userInfo:nil kitHandler:forwardQueueItem.eventCompletionHandler];
                });
                break;
            }
                
            case MPQueueItemTypeEcommerce: {
                dispatch_async([MParticle messageQueue], ^{
                    [self forwardCommerceEventCall:forwardQueueItem.commerceEvent kitHandler:forwardQueueItem.commerceEventCompletionHandler];
                });
                break;
            }
                
            case MPQueueItemTypeGeneralPurpose: {
                dispatch_async([MParticle messageQueue], ^{
                    [self forwardSDKCall:forwardQueueItem.selector parameters:forwardQueueItem.queueParameters messageType:forwardQueueItem.messageType kitHandler:forwardQueueItem.generalPurposeCompletionHandler];
                });
                break;
            }
        }
    }
}

- (BOOL)shouldIncludeEventWithAttributes:(NSDictionary<NSString *, id> *)attributes afterAttributeValueFilteringWithConfiguration:(MPKitConfiguration *)configuration {
    if (!configuration.attributeValueFilteringIsActive) {
        return YES;
    }
    
    __block BOOL isMatch = NO;
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *hashedAttribute = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        if ([hashedAttribute isEqualToString:configuration.attributeValueFilteringHashedAttribute]) {
            *stop = YES;
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *value = (NSString *)obj;
                NSString *hashedValue = [NSString stringWithCString:mParticle::Hasher::hashString([[value lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                if ([hashedValue isEqualToString:configuration.attributeValueFilteringHashedValue]) {
                    isMatch = YES;
                }
            }
        }
    }];
    
    BOOL shouldInclude = configuration.attributeValueFilteringShouldIncludeMatches ? isMatch : !isMatch;
    return shouldInclude;
}

- (BOOL)isDisabledByBracketConfiguration:(NSDictionary *)bracketConfiguration {
    shared_ptr<mParticle::Bracket> localBracket;
    if (!bracketConfiguration) {
        return NO;
    }
    NSString *const MPKitBracketLowKey = @"lo";
    NSString *const MPKitBracketHighKey = @"hi";
    
    long mpId = [[MPPersistenceController mpId] longValue];
    short low = (short)[bracketConfiguration[MPKitBracketLowKey] integerValue];
    short high = (short)[bracketConfiguration[MPKitBracketHighKey] integerValue];
    localBracket = make_shared<mParticle::Bracket>(mpId, low, high);
    return !localBracket->shouldForward();
}

- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(MPKitConfiguration *)kitConfiguration {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
    
    if (!kitRegister) {
        return nil;
    }
    
    if (kitRegister.wrapperInstance) {
        return kitRegister.wrapperInstance;
    }
    
    [self startKitRegister:kitRegister configuration:kitConfiguration];
    
    return kitRegister.wrapperInstance;
}

- (void)startKitRegister:(nonnull id<MPExtensionKitProtocol>)kitRegister configuration:(nonnull MPKitConfiguration *)kitConfiguration {
    BOOL disabled = [self isDisabledByBracketConfiguration:kitConfiguration.bracketConfiguration];
    if (disabled) {
        return;
    }
    
    NSDictionary * configuration = kitConfiguration.configuration;
    configuration = [self validateAndTransformToSafeConfiguration:configuration];
    
    if (configuration) {
        kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] init];
        
        MPKitAPI *kitApi = [[MPKitAPI alloc] initWithKitCode:kitRegister.code];
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(setKitApi:)]) {
            [kitRegister.wrapperInstance setKitApi:kitApi];
        }
        
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(didFinishLaunchingWithConfiguration:)]) {
            [kitRegister.wrapperInstance didFinishLaunchingWithConfiguration:configuration];
        }
    }
}

- (NSDictionary *)validateAndTransformToSafeConfiguration:(NSDictionary *)configuration {
    if (configuration.count == 0) {
        return nil;
    }
    
    __block NSMutableDictionary *safeConfiguration = [[NSMutableDictionary alloc] initWithCapacity:configuration.count];
    __block BOOL configurationModified = NO;
    [configuration enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if ((NSNull *)obj != [NSNull null]) {
            safeConfiguration[key] = obj;
        } else {
            configurationModified = YES;
        }
    }];
    
    if (configurationModified) {
        return safeConfiguration.count > 0 ? [safeConfiguration copy] : nil;
    } else {
        return configuration;
    }
}

- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType {
    id value = nil;
    
    switch (dataType) {
        case MPDataTypeString:
            if (MPIsNull(originalValue)) {
                return nil;
            }
            
            value = originalValue;
            break;
            
        case MPDataTypeInt:
        case MPDataTypeLong: {
            if (MPIsNull(originalValue)) {
                return @0;
            }
            
            NSInteger integerValue = [originalValue integerValue];
            
            if (integerValue != 0) {
                value = @(integerValue);
            } else {
                if ([originalValue isEqualToString:@"0"]) {
                    value = @(integerValue);
                } else {
                    value = nil;
                    MPILogError(@"Value '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeFloat: {
            if (MPIsNull(originalValue)) {
                return @0.0;
            }
            
            float floatValue = [originalValue floatValue];
            
            if (floatValue != HUGE_VAL && floatValue != -HUGE_VAL && floatValue != 0.0) {
                value = @(floatValue);
            } else {
                if ([originalValue isEqualToString:@"0"] || [originalValue isEqualToString:@"0.0"] || [originalValue isEqualToString:@".0"]) {
                    value = @(floatValue);
                } else {
                    value = [NSNull null];
                    MPILogError(@"Attribute '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeBool: {
            if (MPIsNull(originalValue)) {
                return @NO;
            }
            
            if ([originalValue caseInsensitiveCompare:@"true"] == NSOrderedSame) {
                value = @YES;
            } else {
                value = @NO;
            }
        }
            break;
    }
    
    return value;
}

- (void)updateBracketsWithConfiguration:(NSDictionary *)configuration kitCode:(NSNumber *)kitCode {
    NSAssert(kitCode != nil, @"Required parameter. It cannot be nil.");
    
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>>::iterator bracketIterator;
    bracketIterator = brackets.find(kitCode);

    if (!configuration) {
        if (bracketIterator != brackets.end()) {
            brackets.erase(bracketIterator);
        }
        
        return;
    }
    
    long mpId = [[MPPersistenceController mpId] longValue];
    short low = (short)[configuration[@"lo"] integerValue];
    short high = (short)[configuration[@"hi"] integerValue];
    
    shared_ptr<mParticle::Bracket> bracket;
    if (bracketIterator != brackets.end()) {
        bracket = bracketIterator->second;
        bracket->mpId = mpId;
        bracket->low = low;
        bracket->high = high;
    } else {
        brackets[kitCode] = make_shared<mParticle::Bracket>(mpId, low, high);
    }
}

#pragma mark Public class methods
+ (BOOL)registerKit:(nonnull id<MPExtensionKitProtocol>)kitRegister {
    NSAssert(kitRegister != nil, @"Required parameter. It cannot be nil.");
    
    [kitsRegistry addObject:kitRegister];
    return YES;
}

+ (nullable NSSet<id<MPExtensionKitProtocol>> *)registeredKits {
    return kitsRegistry.count > 0 ? kitsRegistry : nil;
}

+ (MPKitContainer *)sharedInstance {
    static MPKitContainer *sharedInstance = nil;
    static dispatch_once_t kitContainerPredicate;
    
    dispatch_once(&kitContainerPredicate, ^{
        sharedInstance = [[MPKitContainer alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Public accessors
- (NSMutableDictionary<NSNumber *, MPKitConfiguration *> *)kitConfigurations {
    if (_kitConfigurations) {
        return _kitConfigurations;
    }
    
    _kitConfigurations = [[NSMutableDictionary alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    
    return _kitConfigurations;
}

#pragma mark Filtering methods
- (void)filter:(id<MPExtensionKitProtocol>)kitRegister forCommerceEvent:(MPCommerceEvent *const)commerceEvent completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    NSNumber *zero = @0;
    __block MPKitFilter *kitFilter;
    void (^completionHandlerCopy)(MPKitFilter *, BOOL finished) = [completionHandler copy];
    
    // Attribute value filtering
    if (![self shouldIncludeEventWithAttributes:commerceEvent.userDefinedAttributes afterAttributeValueFilteringWithConfiguration:kitConfiguration]) {
        kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:YES];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Event type filter
    __block NSString *hashValue = [NSString stringWithCString:mParticle::EventTypeName::hashForEventType(static_cast<mParticle::EventType>([commerceEvent type])).c_str() encoding:NSUTF8StringEncoding];
    
    __block BOOL shouldFilter = kitConfiguration.eventTypeFilters[hashValue] && [kitConfiguration.eventTypeFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    __block MPCommerceEvent *forwardCommerceEvent = [commerceEvent copy];
    
    // Entity type filter
    MPCommerceEventKind commerceEventKind = [commerceEvent kind];
    NSString *commerceEventKindValue = [@(commerceEventKind) stringValue];
    shouldFilter = [kitConfiguration.commerceEventEntityTypeFilters[commerceEventKindValue] isEqualToNumber:zero];
    if (shouldFilter) {
        switch (commerceEventKind) {
            case MPCommerceEventKindProduct:
            case MPCommerceEventKindImpression:
                [forwardCommerceEvent setProducts:nil];
                [forwardCommerceEvent setImpressions:nil];
                break;
                
            case MPCommerceEventKindPromotion:
                [forwardCommerceEvent.promotionContainer setPromotions:nil];
                break;
                
            default:
                forwardCommerceEvent = nil;
                break;
        }
        
        if (forwardCommerceEvent) {
            kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:forwardCommerceEvent shouldFilter:NO];
            completionHandlerCopy(kitFilter, YES);
        } else {
            kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:NO];
            completionHandlerCopy(kitFilter, YES);
        }
        
        return;
    } else { // App family attribute and Commerce event attribute filters
        // App family attribute filter
        NSDictionary *appFamilyFilter = kitConfiguration.commerceEventAppFamilyAttributeFilters[commerceEventKindValue];
        
        if (appFamilyFilter.count > 0) {
            switch (commerceEventKind) {
                case MPCommerceEventKindProduct: {
                    __block NSMutableArray *products = [[NSMutableArray alloc] init];
                    
                    [commerceEvent.products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                        MPProduct *filteredProduct = [product copyMatchingHashedProperties:appFamilyFilter];
                        
                        if (filteredProduct) {
                            [products addObject:filteredProduct];
                        }
                    }];
                    
                    if (products.count > 0) {
                        [forwardCommerceEvent setProducts:products];
                    }
                }
                    break;
                    
                case MPCommerceEventKindImpression:
                    forwardCommerceEvent.impressions = [commerceEvent copyImpressionsMatchingHashedProperties:appFamilyFilter];
                    break;
                    
                case MPCommerceEventKindPromotion:
                    forwardCommerceEvent.promotionContainer = [commerceEvent.promotionContainer copyMatchingHashedProperties:appFamilyFilter];
                    break;
                    
                default:
                    break;
            }
        }
        
        NSDictionary *commerceEventAttributeFilters = kitConfiguration.commerceEventAttributeFilters;
        if (commerceEventAttributeFilters) {
            // Commerce event attribute filter (expanded attributes)
            __block NSString *auxString;
            __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] init];
            
            [[forwardCommerceEvent beautifiedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                auxString = [NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key];
                hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                
                id filterValue = commerceEventAttributeFilters[hashValue];
                BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                
                if (!filterValue || (filterValue && !filterValueIsFalse)) {
                    filteredAttributes[key] = obj;
                }
            }];
            
            [forwardCommerceEvent setBeautifiedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
            
            // Commerce event attribute filter (user defined attributes)
            filteredAttributes = [[NSMutableDictionary alloc] init];
            
            [[forwardCommerceEvent userDefinedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                auxString = [NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key];
                hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                
                id filterValue = commerceEventAttributeFilters[hashValue];
                BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                
                if (!filterValue || (filterValue && !filterValueIsFalse)) {
                    filteredAttributes[key] = obj;
                }
            }];
            
            [forwardCommerceEvent setUserDefinedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
            
            // Transaction attributes
            __block MPTransactionAttributes *filteredTransactionAttributes = [[MPTransactionAttributes alloc] init];
            
            [[forwardCommerceEvent.transactionAttributes beautifiedDictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
                auxString = [NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key];
                hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                
                id filterValue = commerceEventAttributeFilters[hashValue];
                BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                
                if (!filterValue || (filterValue && !filterValueIsFalse)) {
                    if ([key isEqualToString:kMPExpTAAffiliation]) {
                        filteredTransactionAttributes.affiliation = forwardCommerceEvent.transactionAttributes.affiliation;
                    } else if ([key isEqualToString:kMPExpTAShipping]) {
                        filteredTransactionAttributes.shipping = forwardCommerceEvent.transactionAttributes.shipping;
                    } else if ([key isEqualToString:kMPExpTATax]) {
                        filteredTransactionAttributes.tax = forwardCommerceEvent.transactionAttributes.tax;
                    } else if ([key isEqualToString:kMPExpTARevenue]) {
                        filteredTransactionAttributes.revenue = forwardCommerceEvent.transactionAttributes.revenue;
                    } else if ([key isEqualToString:kMPExpTATransactionId]) {
                        filteredTransactionAttributes.transactionId = forwardCommerceEvent.transactionAttributes.transactionId;
                    } else if ([key isEqualToString:kMPExpTACouponCode]) {
                        filteredTransactionAttributes.couponCode = forwardCommerceEvent.transactionAttributes.couponCode;
                    }
                }
            }];
            
            forwardCommerceEvent.transactionAttributes = filteredTransactionAttributes;
        }
    }
    
    [self project:kitRegister commerceEvent:forwardCommerceEvent completionHandler:^(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections) {
        NSArray<MPEventProjection *> *appliedProjectionsArray = !appliedProjections.empty() ? [NSArray arrayWithObjects:&appliedProjections[0] count:appliedProjections.size()] : nil;
        
        if (!projectedEvents.empty()) {
            const auto lastProjectedEvent = projectedEvents.back();
            
            for (auto &projectedEvent : projectedEvents) {
                kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
                completionHandlerCopy(kitFilter, lastProjectedEvent == projectedEvent);
            }
        }
        
        if (!projectedCommerceEvents.empty()) {
            const auto lastProjectedCommerceEvent = projectedCommerceEvents.back();
            
            for (auto &projectedCommerceEvent : projectedCommerceEvents) {
                kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:projectedCommerceEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
                completionHandlerCopy(kitFilter, lastProjectedCommerceEvent == projectedCommerceEvent);
            }
        }
    }];
}

- (void)filter:(id<MPExtensionKitProtocol>)kitRegister forEvent:(MPEvent *const)event selector:(SEL)selector completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    NSNumber *zero = @0;
    __block MPKitFilter *kitFilter;
    void (^completionHandlerCopy)(MPKitFilter *, BOOL) = [completionHandler copy];
    __block NSString *hashValue = nil;
    __block BOOL shouldFilter = NO;
    
    // Attribute value filtering
    shouldFilter = ![self shouldIncludeEventWithAttributes:event.info afterAttributeValueFilteringWithConfiguration:kitConfiguration];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Event type filter
    if (selector != @selector(logScreen:)) {
        
        hashValue = [NSString stringWithCString:mParticle::EventTypeName::hashForEventType(static_cast<mParticle::EventType>(event.type)).c_str() encoding:NSUTF8StringEncoding];
        
        shouldFilter = kitConfiguration.eventTypeFilters[hashValue] && [kitConfiguration.eventTypeFilters[hashValue] isEqualToNumber:zero];
        if (shouldFilter) {
            kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
            completionHandlerCopy(kitFilter, YES);
            return;
        }
        
    }
    
    // Message type filter
    NSString *selectorString = NSStringFromSelector(selector);
    NSString *messageType = [self methodMessageTypeMapping][selectorString];
    if (messageType) {
        shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:zero];
        
        if (shouldFilter) {
            kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
            completionHandlerCopy(kitFilter, YES);
            return;
        }
    }
    
    NSDictionary *attributeFilters;
    NSDictionary *nameFilters;
    NSString *eventTypeString;
    
    if ([selectorString isEqualToString:@"logScreen:"]) { // Screen name and screen attribute filters
        eventTypeString = @"0";
        nameFilters = kitConfiguration.screenNameFilters;
        attributeFilters = kitConfiguration.screenAttributeFilters;
    } else { // Event name and event attribute filters
        eventTypeString = [@(event.type) stringValue];
        nameFilters = kitConfiguration.eventNameFilters;
        attributeFilters = kitConfiguration.eventAttributeFilters;
    }
    
    __block NSString *auxString = [[NSString stringWithFormat:@"%@%@", eventTypeString, event.name] lowercaseString];
    hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([auxString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                   encoding:NSUTF8StringEncoding];
    
    shouldFilter = nameFilters[hashValue] && [nameFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Attributes
    MPMessageType messageTypeCode = (MPMessageType)mParticle::MessageTypeName::messageTypeForName(string([messageType UTF8String]));
    if (messageTypeCode != MPMessageTypeEvent && messageTypeCode != MPMessageTypeScreenView) {
        messageTypeCode = MPMessageTypeUnknown;
    }
    
    MPEvent *forwardEvent = [event copy];
    
    if (event.info) {
        __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:forwardEvent.info.count];
        
        [forwardEvent.info enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            auxString = [NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key];
            hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([auxString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                           encoding:NSUTF8StringEncoding];
            
            id attributeFilterValue = attributeFilters[hashValue];
            BOOL attributeFilterIsFalse = [attributeFilterValue isEqualToNumber:zero];
            
            if (!attributeFilterValue || (attributeFilterValue && !attributeFilterIsFalse)) {
                filteredAttributes[key] = obj;
            } else if (attributeFilterValue && attributeFilterIsFalse) {
                shouldFilter = YES;
            }
        }];
        
        forwardEvent.info = filteredAttributes.count > 0 ? filteredAttributes : nil;
    }
    
    [self project:kitRegister event:forwardEvent messageType:messageTypeCode completionHandler:^(vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections) {
        __weak auto lastProjectedEvent = projectedEvents.back();
        NSArray<MPEventProjection *> *appliedProjectionsArray = !appliedProjections.empty() ? [NSArray arrayWithObjects:&appliedProjections[0] count:appliedProjections.size()] : nil;
        
        for (auto &projectedEvent : projectedEvents) {
            BOOL finished = projectedEvent == lastProjectedEvent;
            kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:shouldFilter appliedProjections:appliedProjectionsArray];
            completionHandlerCopy(kitFilter, finished);
        }
    }];
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forSelector:(SEL)selector {
    MPKitFilter *kitFilter = nil;
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (kitConfiguration) {
        NSString *selectorString = NSStringFromSelector(selector);
        NSString *messageType = [self methodMessageTypeMapping][selectorString];
        
        if (messageType) {
            BOOL shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:@0];
            
            kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
        }
    }
    
    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributes:(NSDictionary *)userAttributes {
    if (!userAttributes) {
        return nil;
    }
    
    MPKitFilter *kitFilter = nil;
    __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (kitConfiguration) {
        [userAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                     encoding:NSUTF8StringEncoding];
            
            BOOL shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
            if (!shouldFilter) {
                filteredAttributes[key] = [value copy];
            }
        }];
    }
    
    if (filteredAttributes.count > 0) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:YES filteredAttributes:filteredAttributes];
    }
    
    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributeKey:(NSString *)key value:(id)value {
    if (!key) {
        return nil;
    }
    
    NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                             encoding:NSUTF8StringEncoding];
    
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    MPKitFilter *kitFilter = nil;
    BOOL shouldFilter = NO;
    
    if (kitConfiguration) {
        shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
        
        kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
    }
    
    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserIdentityKey:(NSString *)key identityType:(MPUserIdentity)identityType {
    NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)identityType];
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    MPKitFilter *kitFilter = nil;
    BOOL shouldFilter = NO;
    
    if (kitConfiguration) {
        shouldFilter = kitConfiguration.userIdentityFilters[identityTypeString] && [kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        
        kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
    }
    
    return kitFilter;
}

#pragma mark Projection methods
- (void)project:(id<MPExtensionKitProtocol>)kitRegister commerceEvent:(MPCommerceEvent *const)commerceEvent completionHandler:(void (^)(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > MPMessageTypeCommerceEvent) ||
        ![kitConfiguration.configuredMessageTypeProjections[MPMessageTypeCommerceEvent] boolValue])
    {
        vector<MPCommerceEvent *> projectedCommerceEvents;
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        
        projectedCommerceEvents.push_back(commerceEvent);
        
        completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        
        return;
    }
    
    __weak MPKitContainer *weakSelf = self;
    
    __strong MPKitContainer *strongSelf = weakSelf;
    if (strongSelf) {
        dispatch_semaphore_wait(strongSelf->kitsSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    // Filter projections only to those of 'messageType'
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageType == %ld", (long)MPMessageTypeCommerceEvent];
    NSArray *projections = [kitConfiguration.projections filteredArrayUsingPredicate:predicate];
    
    // Priming projections
    vector<MPCommerceEvent *> projectedCommerceEvents;
    vector<MPEvent *> projectedEvents;
    vector<MPEventProjection *> appliedProjections;
    __block vector<MPEventProjection *> applicableEventProjections;
    MPEventType typeOfCommerceEvent = [commerceEvent type];
    MPCommerceEventKind kindOfCommerceEvent = [commerceEvent kind];
    
    NSArray *const products = [&commerceEvent] {
        return [commerceEvent kind] == MPCommerceEventKindProduct ? commerceEvent.products : (NSArray *)nil;
    }();
    
    NSArray *const promotions = [&commerceEvent] {
        return [commerceEvent kind] == MPCommerceEventKindPromotion ? commerceEvent.promotionContainer.promotions : (NSArray *)nil;
    }();
    
    BOOL (^isApplicableEventProjection)(MPEventProjection *, NSDictionary *) = ^ BOOL (MPEventProjection *eventProjection, NSDictionary *sourceDictionary) {
        
        __block BOOL foundNonMatch = NO;
        [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
            __block BOOL isApplicable = NO;
            [sourceDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                NSString *keyHash = [NSString stringWithCString:mParticle::Hasher::hashString(to_string(typeOfCommerceEvent) + string([[key lowercaseString] UTF8String])).c_str()
                                                       encoding:NSUTF8StringEncoding];
                
                isApplicable = [projectionMatch.attributeKey isEqualToString:keyHash] && [projectionMatch.attributeValues caseInsensitiveContainsObject:value];
                *stop = isApplicable;
            }];
            foundNonMatch = !isApplicable;
            *stop = foundNonMatch;
        }];
        
        return !foundNonMatch;
    };
    
    if (projections.count > 0) {
        // Identifying which projections are applicable
        for (MPEventProjection *eventProjection in projections) {
            if (eventProjection.eventType == typeOfCommerceEvent) {
                if (!MPIsNull(eventProjection.projectionMatches)) {
                    switch (eventProjection.propertyKind) {
                        case MPProjectionPropertyKindEventField:
                            if (isApplicableEventProjection(eventProjection, [[commerceEvent beautifiedAttributes] transformValuesToString])) {
                                applicableEventProjections.push_back(eventProjection);
                            }
                            break;
                            
                        case MPProjectionPropertyKindEventAttribute:
                            if (isApplicableEventProjection(eventProjection, [[commerceEvent userDefinedAttributes] transformValuesToString])) {
                                applicableEventProjections.push_back(eventProjection);
                            }
                            break;
                            
                        case MPProjectionPropertyKindProductField:
                            if (kindOfCommerceEvent == MPCommerceEventKindProduct) {
                                [products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                                    *stop = isApplicableEventProjection(eventProjection, [[product beautifiedAttributes] transformValuesToString]);
                                    if (*stop) {
                                        applicableEventProjections.push_back(eventProjection);
                                    }
                                }];
                            } else if (kindOfCommerceEvent == MPCommerceEventKindImpression) {
                                NSDictionary *impressions = commerceEvent.impressions;
                                __block BOOL stopIteration = NO;
                                
                                [impressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSSet *productImpressions, BOOL *stop) {
                                    [productImpressions enumerateObjectsUsingBlock:^(MPProduct *productImpression, BOOL *stop) {
                                        stopIteration = isApplicableEventProjection(eventProjection, [[productImpression beautifiedAttributes] transformValuesToString]);
                                        if (stopIteration) {
                                            applicableEventProjections.push_back(eventProjection);
                                            *stop = YES;
                                        }
                                    }];
                                    
                                    if (stopIteration) {
                                        *stop = YES;
                                    }
                                }];
                            }
                            break;
                            
                        case MPProjectionPropertyKindProductAttribute:
                            if (kindOfCommerceEvent == MPCommerceEventKindProduct) {
                                [products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                                    *stop = isApplicableEventProjection(eventProjection, [[product userDefinedAttributes] transformValuesToString]);
                                    if (*stop) {
                                        applicableEventProjections.push_back(eventProjection);
                                    }
                                }];
                            } else if (kindOfCommerceEvent == MPCommerceEventKindImpression) {
                                NSDictionary *impressions = commerceEvent.impressions;
                                __block BOOL stopIteration = NO;
                                
                                [impressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSSet *productImpressions, BOOL *stop) {
                                    [productImpressions enumerateObjectsUsingBlock:^(MPProduct *productImpression, BOOL *stop) {
                                        stopIteration = isApplicableEventProjection(eventProjection, [[productImpression userDefinedAttributes] transformValuesToString]);
                                        if (stopIteration) {
                                            applicableEventProjections.push_back(eventProjection);
                                            *stop = YES;
                                        }
                                    }];
                                    
                                    if (stopIteration) {
                                        *stop = YES;
                                    }
                                }];
                            }
                            break;
                            
                        case MPProjectionPropertyKindPromotionField: {
                            if (kindOfCommerceEvent == MPCommerceEventKindPromotion) {
                                [promotions enumerateObjectsUsingBlock:^(MPPromotion *promotion, NSUInteger idx, BOOL *stop) {
                                    *stop = isApplicableEventProjection(eventProjection, [[promotion beautifiedAttributes] transformValuesToString]);
                                    if (*stop) {
                                        applicableEventProjections.push_back(eventProjection);
                                    }
                                }];
                            }
                        }
                            break;
                            
                        case MPProjectionPropertyKindPromotionAttribute:
                            break;
                    }
                } else {
                    applicableEventProjections.push_back(eventProjection);
                }
            }
        } // for
    } // If (projection.count)
    
    // Block to project a dictionary according to an attribute projection
    NSDictionary * (^projectDictionaryWithAttributeProjection)(NSDictionary *, MPAttributeProjection *) = ^(NSDictionary *sourceDictionary, MPAttributeProjection *attributeProjection) {
        NSMutableDictionary *projectedDictionary = [[NSMutableDictionary alloc] init];
        id value;
        
        switch (attributeProjection.matchType) {
            case MPProjectionMatchTypeHash: {
                map<int, NSString *> hashKeyMap;
                NSString *key;
                NSEnumerator *keyEnumerator = [sourceDictionary keyEnumerator];
                while ((key = [keyEnumerator nextObject])) {
                    string attributeToHash = to_string(typeOfCommerceEvent) + string([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    int hashValue = mParticle::Hasher::hashFromString(attributeToHash);
                    hashKeyMap[hashValue] = key;
                }
                
                key = hashKeyMap[[attributeProjection.name intValue]];
                
                if (!MPIsNull(key)) {
                    value = [strongSelf transformValue:sourceDictionary[key] dataType:attributeProjection.dataType];
                    
                    if (value) {
                        projectedDictionary[attributeProjection.projectedName] = value;
                    }
                } else if (attributeProjection.required) {
                    return (NSDictionary *)[NSNull null];
                }
            }
                break;
                
            case MPProjectionMatchTypeField:
            case MPProjectionMatchTypeString:
                if ([sourceDictionary valueForCaseInsensitiveKey:attributeProjection.name]) {
                    value = [strongSelf transformValue:[sourceDictionary valueForCaseInsensitiveKey:attributeProjection.name] dataType:attributeProjection.dataType];
                    
                    if (value) {
                        projectedDictionary[attributeProjection.projectedName] = value;
                    }
                } else if (attributeProjection.required) {
                    return (NSDictionary *)[NSNull null];
                }
                break;
                
            case MPProjectionMatchTypeStatic:
                value = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                
                if (value) {
                    projectedDictionary[attributeProjection.projectedName] = value;
                }
                break;
                
            case MPProjectionMatchTypeNotSpecified:
                break;
        }
        
        if (projectedDictionary.count == 0) {
            projectedDictionary = nil;
        }
        
        return (NSDictionary *)projectedDictionary;
    };
    
    // Block to project a commerce event according to attribute projections
    NSDictionary * (^projectCommerceEventWithAttributes)(MPCommerceEvent *, NSArray *) = ^(MPCommerceEvent *commerceEvent, NSArray<MPAttributeProjection *> *attributeProjections) {
        NSMutableDictionary *projectedCommerceEventDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *sourceDictionary;
        NSDictionary *projectedDictionary;
        NSPredicate *predicate;
        NSArray<MPAttributeProjection *> *filteredAttributeProjections;
        
        vector<MPProjectionPropertyKind> propertyKinds = {MPProjectionPropertyKindEventField, MPProjectionPropertyKindEventAttribute};
        
        for (auto propertyKind : propertyKinds) {
            predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)propertyKind];
            filteredAttributeProjections = [attributeProjections filteredArrayUsingPredicate:predicate];
            
            if (filteredAttributeProjections.count > 0) {
                if (propertyKind == MPProjectionPropertyKindEventField) {
                    sourceDictionary = [[commerceEvent beautifiedAttributes] transformValuesToString];
                } else if (propertyKind == MPProjectionPropertyKindEventAttribute) {
                    sourceDictionary = [[commerceEvent userDefinedAttributes] transformValuesToString];
                } else {
                    continue;
                }
            }
            
            for (MPAttributeProjection *attributeProjection in attributeProjections) {
                projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                
                if (projectedDictionary) {
                    if ((NSNull *)projectedDictionary != [NSNull null]) {
                        [projectedCommerceEventDictionary addEntriesFromDictionary:projectedDictionary];
                    } else {
                        return (NSDictionary *)[NSNull null];
                    }
                }
            }
        }
        
        if (projectedCommerceEventDictionary.count == 0) {
            projectedCommerceEventDictionary = nil;
        }
        
        return (NSDictionary *)projectedCommerceEventDictionary;
    };
    
    // Block to project a product according to attribute projections
    NSDictionary * (^projectProductWithAttributes)(MPProduct *, NSArray *) = ^(MPProduct *product, NSArray<MPAttributeProjection *> *attributeProjections) {
        NSMutableDictionary *projectedProductDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *sourceDictionary;
        NSDictionary *projectedDictionary;
        NSPredicate *predicate;
        NSArray<MPAttributeProjection *> *filteredAttributeProjections;
        
        vector<MPProjectionPropertyKind> propertyKinds = {MPProjectionPropertyKindProductField, MPProjectionPropertyKindProductAttribute};
        
        for (auto propertyKind : propertyKinds) {
            predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)propertyKind];
            filteredAttributeProjections = [attributeProjections filteredArrayUsingPredicate:predicate];
            
            if (filteredAttributeProjections.count > 0) {
                if (propertyKind == MPProjectionPropertyKindProductField) {
                    sourceDictionary = [[product beautifiedAttributes] transformValuesToString];
                } else if (propertyKind == MPProjectionPropertyKindProductAttribute) {
                    sourceDictionary = [[product userDefinedAttributes] transformValuesToString];
                } else {
                    continue;
                }
                
                for (MPAttributeProjection *attributeProjection in filteredAttributeProjections) {
                    projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                    
                    if (projectedDictionary) {
                        if ((NSNull *)projectedDictionary != [NSNull null]) {
                            [projectedProductDictionary addEntriesFromDictionary:projectedDictionary];
                        } else {
                            return (NSDictionary *)[NSNull null];
                        }
                    }
                }
            }
        }
        
        if (projectedProductDictionary.count == 0) {
            return (NSDictionary *)nil;
        }
        
        return (NSDictionary *)projectedProductDictionary;
    };
    
    // Block to apply maximum custom attributes to the projected dictionary
    void (^applyMaxCustomAttributes)(MPCommerceEvent *, MPEventProjection *, NSMutableDictionary *) = ^(MPCommerceEvent *commerceEvent, MPEventProjection *eventProjection, NSMutableDictionary *projectedDictionary) {
        NSUInteger maxCustomParams = eventProjection.maxCustomParameters;
        NSDictionary *userDictionary = [[commerceEvent userDefinedAttributes] transformValuesToString];
        
        if (eventProjection.appendAsIs && maxCustomParams > 0) {
            if (userDictionary.count > maxCustomParams) {
                NSMutableArray *keys = [[userDictionary allKeys] mutableCopy];
                
                [keys sortUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
                    return [key1 compare:key2];
                }];
                
                NSRange deletionRange = NSMakeRange(maxCustomParams - 1, maxCustomParams - userDictionary.count);
                [keys removeObjectsInRange:deletionRange];
                
                for (NSString *key in keys) {
                    projectedDictionary[key] = userDictionary[key];
                }
            } else {
                [projectedDictionary addEntriesFromDictionary:userDictionary];
            }
        }
    };
    
    // Applying projections
    if (!applicableEventProjections.empty()) {
        for (auto &eventProjection : applicableEventProjections) {
            NSMutableDictionary *projectedCommerceEventDictionary = [[NSMutableDictionary alloc] init];
            NSDictionary *projectedDictionary;
            vector<NSMutableDictionary *> projectedDictionaries;
            BOOL requirementsMet = YES;
            
            // Projecting commerce event fields and attributes
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d || propertyKind == %d", (int)MPProjectionPropertyKindEventField, (int)MPProjectionPropertyKindEventAttribute];
            NSArray<MPAttributeProjection *> *attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
            
            if (attributeProjections.count > 0) {
                projectedDictionary = projectCommerceEventWithAttributes(commerceEvent, attributeProjections);
                
                if (projectedDictionary) {
                    if ((NSNull *)projectedDictionary != [NSNull null]) {
                        [projectedCommerceEventDictionary addEntriesFromDictionary:projectedDictionary];
                    } else {
                        requirementsMet = NO;
                    }
                }
            }
            
            // Projecting products/promotions attributes
            switch (kindOfCommerceEvent) {
                case MPCommerceEventKindProduct: {
                    vector<NSUInteger> productIndexes;
                    NSUInteger numberOfProducts = products.count;
                    
                    if (numberOfProducts > 0) {
                        if (eventProjection.behaviorSelector == MPProjectionBehaviorSelectorForEach) {
                            productIndexes.reserve(numberOfProducts);
                            
                            for (NSUInteger idx = 0; idx < numberOfProducts; ++idx) {
                                productIndexes.push_back(idx);
                            }
                        } else {
                            productIndexes.push_back(numberOfProducts - 1);
                        }
                        
                        predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d || propertyKind == %d", (int)MPProjectionPropertyKindProductField, (int)MPProjectionPropertyKindProductAttribute];
                        attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
                        
                        for (auto idx : productIndexes) {
                            MPProduct *product = products[idx];
                            projectedDictionary = projectProductWithAttributes(product, attributeProjections);
                            
                            if (projectedDictionary) {
                                if ((NSNull *)projectedDictionary != [NSNull null]) {
                                    NSMutableDictionary *projectedProductDictionary = [[NSMutableDictionary alloc] initWithDictionary:projectedDictionary];
                                    
                                    if (projectedCommerceEventDictionary.count > 0) {
                                        [projectedProductDictionary addEntriesFromDictionary:projectedCommerceEventDictionary];
                                    }
                                    
                                    applyMaxCustomAttributes(commerceEvent, eventProjection, projectedProductDictionary);
                                    
                                    projectedDictionaries.push_back(projectedProductDictionary);
                                } else {
                                    requirementsMet = NO;
                                    break;
                                }
                            }
                        }
                    }
                }
                    break;
                    
                case MPCommerceEventKindPromotion: {
                    vector<NSUInteger> promotionIndexes;
                    NSUInteger numberOfPromotions = promotions.count;
                    
                    if (numberOfPromotions > 0) {
                        if (eventProjection.behaviorSelector == MPProjectionBehaviorSelectorForEach) {
                            promotionIndexes.reserve(numberOfPromotions);
                            
                            for (NSUInteger index = 0; index < numberOfPromotions; ++index) {
                                promotionIndexes.push_back(index);
                            }
                        } else {
                            promotionIndexes.push_back(numberOfPromotions - 1);
                        }
                        
                        predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)MPProjectionPropertyKindPromotionField];
                        attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
                        
                        for (auto idx : promotionIndexes) {
                            MPPromotion *promotion = promotions[idx];
                            NSDictionary *sourceDictionary = [[promotion beautifiedAttributes] transformValuesToString];
                            
                            for (MPAttributeProjection *attributeProjection in attributeProjections) {
                                NSDictionary *projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                                
                                if (projectedDictionary) {
                                    if ((NSNull *)projectedDictionary != [NSNull null]) {
                                        NSMutableDictionary *projectedPromotionDictionary = [[NSMutableDictionary alloc] initWithDictionary:projectedDictionary];
                                        
                                        if (projectedCommerceEventDictionary.count > 0) {
                                            [projectedPromotionDictionary addEntriesFromDictionary:projectedCommerceEventDictionary];
                                        }
                                        
                                        applyMaxCustomAttributes(commerceEvent, eventProjection, projectedPromotionDictionary);
                                        
                                        projectedDictionaries.push_back(projectedPromotionDictionary);
                                    } else {
                                        requirementsMet = NO;
                                        break;
                                    }
                                }
                            }
                            
                            if (!requirementsMet) {
                                break;
                            }
                        }
                    }
                }
                    break;
                    
                default:
                    break;
            }
            
            // The collection of projected dictionaries become events or commerce events
            if (requirementsMet) {
                if (!projectedDictionaries.empty()) {
                    for (auto &projectedDictionary : projectedDictionaries) {
                        if (eventProjection.outboundMessageType == MPMessageTypeCommerceEvent) {
                            MPCommerceEvent *projectedCommerceEvent = [commerceEvent copy];
                            [projectedCommerceEvent setUserDefinedAttributes:projectedDictionary];
                            projectedCommerceEvents.push_back(projectedCommerceEvent);
                        } else {
                            MPEvent *projectedEvent = [[MPEvent alloc] initWithName:(eventProjection.projectedName ? : @" ") type:MPEventTypeTransaction];
                            projectedEvent.info = projectedDictionary;
                            projectedEvents.push_back(projectedEvent);
                        }
                        
                        appliedProjections.push_back(eventProjection);
                    }
                } else {
                    if (eventProjection.outboundMessageType == MPMessageTypeCommerceEvent) {
                        MPCommerceEvent *projectedCommerceEvent = [commerceEvent copy];
                        projectedCommerceEvents.push_back(projectedCommerceEvent);
                    } else {
                        MPEvent *projectedEvent = [[MPEvent alloc] initWithName:(eventProjection.projectedName ? : @" ") type:MPEventTypeTransaction];
                        projectedEvents.push_back(projectedEvent);
                    }
                    
                    appliedProjections.push_back(eventProjection);
                }
            } else {
                projectedCommerceEvents.push_back(commerceEvent);
            }
        } // for (event projection)
    } // If (applying projections)
    
    // If no projection was applied, uses the original commerce event.
    if (projectedCommerceEvents.empty() && projectedEvents.empty()) {
        projectedCommerceEvents.push_back(commerceEvent);
    }
    
    if (strongSelf) {
        dispatch_semaphore_signal(strongSelf->kitsSemaphore);
    }
    
    completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
}

- (void)project:(id<MPExtensionKitProtocol>)kitRegister event:(MPEvent *const)event messageType:(MPMessageType)messageType completionHandler:(void (^)(vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > messageType) ||
        ![kitConfiguration.configuredMessageTypeProjections[messageType] boolValue])
    {
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        projectedEvents.push_back(event);
        
        completionHandler(projectedEvents, appliedProjections);
        
        return;
    }
    
    __weak MPKitContainer *weakSelf = self;
    
    __strong MPKitContainer *strongSelf = weakSelf;
    if (strongSelf) {
        dispatch_semaphore_wait(strongSelf->kitsSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    // Attribute projection lambda function
    NSDictionary * (^projectAttributes)(MPEvent *const, MPEventProjection *const) = ^(MPEvent *const event, MPEventProjection *const eventProjection) {
        NSDictionary *eventInfo = event.info;
        if (!eventInfo) {
            return (NSDictionary *)nil;
        }
        
        NSMutableArray<MPAttributeProjection *> *attributeProjections = [[NSMutableArray alloc] initWithArray:eventProjection.attributeProjections];
        NSUInteger maxCustomParams = eventProjection.maxCustomParameters;
        NSMutableArray *projectedKeys = [[NSMutableArray alloc] init];
        NSMutableArray *nonProjectedKeys = [[NSMutableArray alloc] init];
        __block NSMutableDictionary *projectedAttributes = [[NSMutableDictionary alloc] init];
        
        if (eventInfo.count > 0) {
            [nonProjectedKeys addObjectsFromArray:[eventInfo allKeys]];
            [projectedAttributes addEntriesFromDictionary:[eventInfo copy]];
        }
        
        __block BOOL doesNotContainRequiredAttribute = NO;
        __block NSMutableArray<MPAttributeProjection *> *removeAttributeProjections = [[NSMutableArray alloc] init];
        
        // Building a map between keys and their respective hashes
        __block std::map<NSString *, int> keyHashMap;
        __block std::map<int, NSString *> hashKeyMap;
        NSString *key;
        NSEnumerator *keyEnumerator = [eventInfo keyEnumerator];
        while ((key = [keyEnumerator nextObject])) {
            string attributeToHash = messageType == MPMessageTypeScreenView ? "0" : to_string(event.type);
            attributeToHash += string([[event.name lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
            attributeToHash += string([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
            
            int hashValue = mParticle::Hasher::hashFromString(attributeToHash);
            keyHashMap[key] = hashValue;
            hashKeyMap[hashValue] = key;
        }
        
        [eventInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            [removeAttributeProjections removeAllObjects];
            NSString *projectedAttributeKey;
            id projectedAttributeValue;
            
            for (MPAttributeProjection *attributeProjection in attributeProjections) {
                BOOL stopInnerLoop = NO;
                
                switch (attributeProjection.matchType) {
                    case MPProjectionMatchTypeString: {
                        if ([key caseInsensitiveCompare:attributeProjection.name] == NSOrderedSame) {
                            projectedAttributeValue = [strongSelf transformValue:obj dataType:attributeProjection.dataType];
                            
                            if (projectedAttributeValue) {
                                projectedAttributeKey = attributeProjection.projectedName ? : key;
                                [projectedAttributes removeObjectForKey:key];
                                projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                                [projectedKeys addObject:projectedAttributeValue];
                                [removeAttributeProjections addObject:attributeProjection];
                            } else if (attributeProjection.required) {
                                doesNotContainRequiredAttribute = YES;
                                *stop = YES;
                                stopInnerLoop = YES;
                            }
                        } else if (attributeProjection.required && MPIsNull(eventInfo[attributeProjection.name])) {
                            doesNotContainRequiredAttribute = YES;
                            *stop = YES;
                            stopInnerLoop = YES;
                        }
                    }
                        break;
                        
                    case MPProjectionMatchTypeHash: {
                        int hashValue = keyHashMap[key];
                        
                        if (hashValue == [attributeProjection.name integerValue]) {
                            projectedAttributeValue = [strongSelf transformValue:obj dataType:attributeProjection.dataType];
                            
                            if (projectedAttributeValue) {
                                projectedAttributeKey = attributeProjection.projectedName ? : key;
                                [projectedAttributes removeObjectForKey:key];
                                projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                                [projectedKeys addObject:projectedAttributeValue];
                                [removeAttributeProjections addObject:attributeProjection];
                            } else if (attributeProjection.required) {
                                doesNotContainRequiredAttribute = YES;
                                *stop = YES;
                                stopInnerLoop = YES;
                            }
                        } else if (attributeProjection.required) {
                            auto iterator = hashKeyMap.find([attributeProjection.name intValue]);
                            
                            if (iterator == hashKeyMap.end()) {
                                doesNotContainRequiredAttribute = YES;
                                *stop = YES;
                                stopInnerLoop = YES;
                            }
                        }
                    }
                        break;
                        
                    case MPProjectionMatchTypeField:
                        projectedAttributeKey = attributeProjection.projectedName ? : key;
                        projectedAttributes[projectedAttributeKey] = event.name;
                        [projectedKeys addObject:projectedAttributeKey];
                        [removeAttributeProjections addObject:attributeProjection];
                        break;
                        
                    case MPProjectionMatchTypeStatic:
                        projectedAttributeKey = attributeProjection.projectedName ? : key;
                        projectedAttributeValue = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                        
                        if (projectedAttributeValue) {
                            projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                            [projectedKeys addObject:projectedAttributeKey];
                        }
                        [removeAttributeProjections addObject:attributeProjection];
                        break;
                        
                    case MPProjectionMatchTypeNotSpecified:
                        break;
                }
                
                if (stopInnerLoop) {
                    break;
                }
            }
            
            if (removeAttributeProjections.count > 0) {
                [attributeProjections removeObjectsInArray:removeAttributeProjections];
            }
        }];
        
        if (doesNotContainRequiredAttribute) {
            return (NSDictionary *)[NSNull null];
        }
        
        // If the number of attributes is greater than the max number allowed, sort the keys and remove the excess from the bottom of the list
        [nonProjectedKeys removeObjectsInArray:projectedKeys];
        
        if (eventProjection.appendAsIs && maxCustomParams > 0) {
            if (nonProjectedKeys.count > maxCustomParams) {
                NSInteger numberOfRemainingSlots = maxCustomParams - projectedKeys.count;
                
                if (numberOfRemainingSlots > 0) {
                    [nonProjectedKeys sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                        return [obj1 compare:obj2];
                    }];
                    
                    [nonProjectedKeys removeObjectsInRange:NSMakeRange(0, numberOfRemainingSlots)];
                    [projectedAttributes removeObjectsForKeys:nonProjectedKeys];
                }
            }
        } else {
            [projectedAttributes removeObjectsForKeys:nonProjectedKeys];
        }
        
        if (projectedAttributes.count == 0) {
            projectedAttributes = nil;
        }
        
        return (NSDictionary *)projectedAttributes;
    }; // End of attribute projection lambda function
    
    // Filter projections only to those of 'messageType'
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageType == %ld", (long)messageType];
    NSArray *projections = [kitConfiguration.projections filteredArrayUsingPredicate:predicate];
    
    // Apply projections
    vector<MPEvent *> projectedEvents;
    vector<MPEventProjection *> appliedProjections;
    MPEvent *projectedEvent;
    MPEventProjection *defaultProjection = nil;
    NSDictionary *projectedAttributes;
    NSDictionary<NSString *, NSString *> *eventInfo = [event.info transformValuesToString];
    
    if (projections.count > 0) {
        int eventNameHash = 0;
        
        for (MPEventProjection *eventProjection in projections) {
            BOOL shouldProjectEvent = NO;
            
            switch (eventProjection.matchType) {
                case MPProjectionMatchTypeString:
                    if ([event.name caseInsensitiveCompare:eventProjection.name] == NSOrderedSame) {
                        if (eventProjection.projectionMatches) {
                            __block BOOL foundNonMatch = NO;
                            [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                    foundNonMatch = YES;
                                    *stop = YES;
                                }
                            }];
                            shouldProjectEvent = !foundNonMatch;
                        } else {
                            shouldProjectEvent = YES;
                        }
                    }
                    break;
                    
                case MPProjectionMatchTypeHash: {
                    if (eventNameHash == 0) {
                        string nameToHash = messageType == MPMessageTypeScreenView ? "0" : to_string(event.type);
                        nameToHash += string([[event.name lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                        eventNameHash = mParticle::Hasher::hashFromString(nameToHash);
                    }
                    
                    if (eventNameHash == [eventProjection.name integerValue]) {
                        if (eventProjection.projectionMatches) {
                            __block BOOL foundNonMatch = NO;
                            [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                    foundNonMatch = YES;
                                    *stop = YES;
                                }
                            }];
                            shouldProjectEvent = !foundNonMatch;
                        } else {
                            shouldProjectEvent = YES;
                        }
                    }
                }
                    break;
                    
                case MPProjectionMatchTypeNotSpecified:
                    shouldProjectEvent = YES;
                    break;
                    
                default: // Filter and Static... only applicable to attributes
                    break;
            }
            
            if (shouldProjectEvent) {
                projectedEvent = [event copy];
                projectedAttributes = projectAttributes(projectedEvent, eventProjection);
                
                if ((NSNull *)projectedAttributes != [NSNull null]) {
                    projectedEvent.info = projectedAttributes;
                    
                    if (eventProjection.projectedName) {
                        if (eventProjection.projectionMatches) {
                            __block BOOL foundNonMatch = NO;
                            [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                    foundNonMatch = YES;
                                    *stop = YES;
                                }
                            }];
                            if (!foundNonMatch) {
                                projectedEvent.name = eventProjection.projectedName;
                            }
                            
                        } else {
                            projectedEvent.name = eventProjection.projectedName;
                        }
                    }
                    
                    projectedEvents.push_back(projectedEvent);
                    appliedProjections.push_back(eventProjection);
                }
            }
        }
    }
    
    // Default projection, applied only if no other projection was applicable
    if (projectedEvents.empty()) {
        defaultProjection = kitConfiguration.defaultProjections[messageType];
        
        if (!MPIsNull(defaultProjection)) {
            projectedEvent = [event copy];
            projectedAttributes = projectAttributes(projectedEvent, defaultProjection);
            
            if ((NSNull *)projectedAttributes != [NSNull null]) {
                projectedEvent.info = projectedAttributes;
                
                if (defaultProjection.projectedName && defaultProjection.projectionType == MPProjectionTypeEvent) {
                    projectedEvent.name = defaultProjection.projectedName;
                }
                
                projectedEvents.push_back(projectedEvent);
                appliedProjections.push_back(defaultProjection);
            }
        }
        
        if (projectedEvents.empty()) {
            projectedEvents.push_back(event);
        }
    }
    
    if (strongSelf) {
        dispatch_semaphore_signal(strongSelf->kitsSemaphore);
    }
    
    completionHandler(projectedEvents, appliedProjections);
}

#pragma mark Public methods
- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry {
    if (kitsRegistry.count == 0) {
        return nil;
    }
    
    NSMutableArray <id<MPExtensionKitProtocol>> *activeKitsRegistry = [[NSMutableArray alloc] initWithCapacity:kitsRegistry.count];
    
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        BOOL active = kitRegister.wrapperInstance ? [kitRegister.wrapperInstance started] : NO;
        std::shared_ptr<mParticle::Bracket> bracket = [self bracketForKit:kitRegister.code];
        
        if (active && (bracket == nullptr || (bracket != nullptr && bracket->shouldForward()))) {
            [activeKitsRegistry addObject:kitRegister];
        }
    }
    
    return activeKitsRegistry.count > 0 ? activeKitsRegistry : nil;
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitConfigurations {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (MPIsNull(kitConfigurations) || stateMachine.optOut) {
        [self flushSerializedKits];
        self.kitsInitialized = YES;
        
        return;
    }
    
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    
    NSPredicate *predicate;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSDictionary *userAttributes = userDefaults[kMPUserAttributeKey];
    NSArray *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    NSArray<NSNumber *> *supportedKits = [self supportedKits];
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    id<MPExtensionKitProtocol>kitRegister;
    id<MPKitProtocol> kitInstance;
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    Class NSArrayClass = [NSArray class];

    // Adds all currently configured kits to a list
    vector<NSNumber *> deactivateKits;
    for (kitRegister in activeKitsRegistry) {
        deactivateKits.push_back(kitRegister.code);
    }
    
    // Configure kits according to server instructions
    for (NSDictionary *kitConfigurationDictionary in kitConfigurations) {
        MPKitConfiguration *kitConfiguration = nil;
        
        NSNumber *kitCode = kitConfigurationDictionary[@"id"];
        
        predicate = [NSPredicate predicateWithFormat:@"SELF == %@", kitCode];
        BOOL isKitSupported = [supportedKits filteredArrayUsingPredicate:predicate].count > 0;

        if (isKitSupported) {
            predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
            kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
            kitInstance = kitRegister.wrapperInstance;
            kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            self.kitConfigurations[kitCode] = kitConfiguration;
            
            if (kitInstance) {
                [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration kitCode:kitCode];
                
                if ([kitInstance respondsToSelector:@selector(setConfiguration:)]) {
                    [kitInstance setConfiguration:kitConfiguration.configuration];
                }
            } else {
                [self startKitRegister:kitRegister configuration:kitConfiguration];
                kitInstance = kitRegister.wrapperInstance;
                
                if (kitInstance) {
                    [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration kitCode:kitCode];
                    if (![kitInstance started]) {
                        if ([kitInstance respondsToSelector:@selector(setLaunchOptions:)]) {
                            [kitInstance performSelector:@selector(setLaunchOptions:) withObject:stateMachine.launchOptions];
                        }
                        
                        if ([kitInstance respondsToSelector:@selector(start)]) {
                            @try {
                                [kitInstance start];
                            }
                            @catch (NSException *exception) {
                                MPILogError(@"Exception thrown while starting kit (%@): %@", kitInstance, exception);
                            }
                        }
                    }
                }
                
                [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration kitCode:kitCode];
            }
            
            if (kitInstance) {
                NSArray *alreadySynchedUserAttributes = userDefaults[kMPSynchedUserAttributesKey];
                if (userAttributes && ![alreadySynchedUserAttributes containsObject:kitCode]) {
                    NSMutableArray *synchedUserAttributes = [[NSMutableArray alloc] initWithCapacity:alreadySynchedUserAttributes.count + 1];
                    [synchedUserAttributes addObjectsFromArray:alreadySynchedUserAttributes];
                    [synchedUserAttributes addObject:kitCode];
                    userDefaults[kMPSynchedUserAttributesKey] = synchedUserAttributes;

                    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
                    NSString *key;
                    id value;
                    while ((key = [attributeEnumerator nextObject])) {
                        value = userAttributes[key];

                        FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:self.kitConfigurations[kitRegister.code]];
                        if ([kitInstance respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                            [kitInstance onSetUserAttribute:filteredUser];
                        } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:value:)] && [value isKindOfClass:NSStringClass]) {
                            [kitInstance setUserAttribute:key value:value];
                        } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:value:)] && [value isKindOfClass:NSNumberClass]) {
                            value = [value stringValue];
                            [kitInstance setUserAttribute:key value:value];
                        } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:values:)] && [value isKindOfClass:NSArrayClass]) {
                            [kitInstance setUserAttribute:key values:value];
                        }
                    }
                }

                NSArray *alreadySynchedUserIdentities = userDefaults[kMPSynchedUserIdentitiesKey];
                if (userIdentities && [kitInstance respondsToSelector:@selector(setUserIdentity:identityType:)] && ![alreadySynchedUserIdentities containsObject:kitCode]) {
                    NSMutableArray *synchedUserIdentities = [[NSMutableArray alloc] initWithCapacity:alreadySynchedUserIdentities.count + 1];
                    [synchedUserIdentities addObjectsFromArray:alreadySynchedUserIdentities];
                    [synchedUserIdentities addObject:kitCode];
                    userDefaults[kMPSynchedUserIdentitiesKey] = synchedUserIdentities;

                    for (NSDictionary *userIdentity in userIdentities) {
                        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] intValue];
                        NSString *identityString = userIdentity[kMPUserIdentityIdKey];

                        [kitInstance setUserIdentity:identityString identityType:identityType];
                    }
                }
            }
        } else {
            MPILogWarning(@"SDK is trying to configure a kit (code = %@). However, it is not currently registered with the core SDK.", kitCode);
        }
        
        if (!deactivateKits.empty()) {
            for (size_t i = 0; i < deactivateKits.size(); ++i) {
                if ([deactivateKits.at(i) isEqualToNumber:kitCode]) {
                    deactivateKits.erase(deactivateKits.begin() + i);
                    break;
                }
            }
        }
    }
    
    // Remove currently configured kits that were not in the instructions from the server
    if (!deactivateKits.empty()) {
        for (vector<NSNumber *>::iterator ekIterator = deactivateKits.begin(); ekIterator != deactivateKits.end(); ++ekIterator) {
            predicate = [NSPredicate predicateWithFormat:@"code == %@", *ekIterator];
            kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
            [self freeKit:kitRegister.code];
        }
    }
    
    self.kitsInitialized = YES;

    dispatch_semaphore_signal(kitsSemaphore);
}

- (nullable NSArray<NSNumber *> *)supportedKits {
    if (kitsRegistry.count == 0) {
        return nil;
    }
    
    NSMutableArray<NSNumber *> *supportedKits = [[NSMutableArray alloc] initWithCapacity:kitsRegistry.count];
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        [supportedKits addObject:kitRegister.code];
    }
    
    return supportedKits;
}

#pragma mark Forward methods
- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus))kitHandler {
    if (!self.kitsInitialized) {
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent completionHandler:kitHandler];
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        __block NSNumber *lastKit = nil;
        
        [self filter:kitRegister forCommerceEvent:commerceEvent completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
            if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
                return;
            }
            
            if (kitFilter.forwardCommerceEvent || kitFilter.forwardEvent) {
                __block MPKitExecStatus *execStatus = nil;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, kitFilter, &execStatus);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                NSNumber *currentKit = kitRegister.code;
                if (execStatus.success && ![lastKit isEqualToNumber:currentKit]) {
                    lastKit = currentKit;
                    
                    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeCommerceEvent
                                                                                       execStatus:execStatus
                                                                                        kitFilter:kitFilter
                                                                                    originalEvent:commerceEvent];
                    
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                    
                    MPILogDebug(@"Forwarded logCommerceEvent call to kit: %@", kitRegister.name);
                }
            }
        }];
    }
}

- (void)forwardSDKCall:(SEL)selector event:(MPEvent *)event messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo kitHandler:(void (^)(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus))kitHandler {
    if (!self.kitsInitialized) {
        if (messageType == MPMessageTypePushRegistration) {
            return;
        }
        
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:messageType completionHandler:kitHandler];
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        __block NSNumber *lastKit = nil;
        
        void (^forwardWithFilter)(MPKitFilter *const) = ^(MPKitFilter *const kitFilter) {
            if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
                return;
            }
            
            if (kitFilter.forwardEvent) {
                __block MPKitExecStatus *execStatus = nil;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, kitFilter.forwardEvent, &execStatus);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                NSNumber *currentKit = kitRegister.code;
                if (execStatus.success && ![lastKit isEqualToNumber:currentKit] && kitFilter.forwardEvent && messageType != MPMessageTypeUnknown) {
                    lastKit = currentKit;
                    
                    MPForwardRecord *forwardRecord = nil;
                    
                    if (messageType == MPMessageTypeOptOut || messageType == MPMessageTypePushRegistration) {
                        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                          execStatus:execStatus
                                                                           stateFlag:[userInfo[@"state"] boolValue]];
                    } else {
                        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                          execStatus:execStatus
                                                                           kitFilter:kitFilter
                                                                       originalEvent:event];
                    }
                    
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                    
                    MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
                }
            }
        };
        
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            if (event) {
                [self filter:kitRegister forEvent:event selector:selector completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
                    forwardWithFilter(kitFilter);
                }];
            } else {
                MPKitFilter *kitFilter = [self filter:kitRegister forSelector:selector];
                forwardWithFilter(kitFilter);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
    SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
    SEL otherUserAttributeSelector = NULL;
    
    if (selector == setUserAttributeListSelector) {
        otherUserAttributeSelector = setUserAttributeSelector;
    } else if (selector == setUserAttributeSelector) {
        otherUserAttributeSelector = setUserAttributeListSelector;
    }
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector] || (otherUserAttributeSelector && [kitRegister.wrapperInstance respondsToSelector:otherUserAttributeSelector])) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserAttributeKey:key value:value];
            
            if (!kitFilter.shouldFilter) {
                MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, kitConfiguration);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                MPILogDebug(@"Forwarded user attribute key: %@ value: %@ to kit: %@", key, value, kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(id<MPKitProtocol> kit, NSDictionary *forwardAttributes, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserAttributes:userAttributes];
            
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            dispatch_sync(dispatch_get_main_queue(), ^{
                @try {
                    kitHandler(kitRegister.wrapperInstance, kitFilter.filteredAttributes, kitConfiguration);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
            });
            
            MPILogDebug(@"Forwarded user attributes to kit: %@", kitRegister.name);
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserIdentityKey:identityString identityType:identityType];
            
            if (!kitFilter.shouldFilter) {
                MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, kitConfiguration);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                MPILogDebug(@"Forwarded setting user identity: %@ to kit: %@", identityString, kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector errorMessage:(NSString *)errorMessage exception:(NSException *)exception eventInfo:(NSDictionary *)eventInfo kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitExecStatus **execStatus))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithFilter:NO];
            
            if (!kitFilter.shouldFilter) {
                __block MPKitExecStatus *execStatus = nil;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, &execStatus);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitExecStatus **execStatus))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            __block MPKitExecStatus *execStatus = nil;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                @try {
                    kitHandler(kitRegister.wrapperInstance, &execStatus);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
            });
            
            MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
        }
    }
}

- (void)forwardSDKCall:(SEL)selector parameters:(MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType kitHandler:(void (^)(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitExecStatus **execStatus))kitHandler {
    if (!self.kitsInitialized) {
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:messageType completionHandler:kitHandler];
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        __block NSNumber *lastKit = nil;
        
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            @try {
                __block MPKitExecStatus *execStatus = nil;
                NSNumber *currentKit = kitRegister.code;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        kitHandler(kitRegister.wrapperInstance, parameters, &execStatus);
                    } @catch (NSException *e) {
                        MPILogError(@"Kit handler threw an exception: %@", e);
                    }
                });
                
                if (execStatus.success && ![lastKit isEqualToNumber:currentKit]) {
                    lastKit = currentKit;
                    
                    if (messageType != MPMessageTypeUnknown) {
                        MPForwardRecord *forwardRecord = nil;
                        
                        if (messageType == MPMessageTypePushRegistration) {
                            BOOL stateFlag = NO;
                            
                            if (selector == @selector(failedToRegisterForUserNotifications:)) {
                                stateFlag = NO;
                            } else if (selector == @selector(setDeviceToken:)) {
                                stateFlag = parameters[0] != nil;
                            }
                            
                            forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType execStatus:execStatus stateFlag:stateFlag];
                        } else {
                            forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType execStatus:execStatus];
                        }
                        
                        if (forwardRecord) {
                            [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                        }
                    }
                    
                    MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
                }
            } @catch (NSException *exception) {
                MPILogError(@"An exception happened forwarding %@ to kit: %@\n  reason: %@", NSStringFromSelector(selector), kitRegister.name, [exception reason]);
            }
        }
    }
}

- (void)forwardIdentitySDKCall:(SEL)selector kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration *kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            kitHandler(kitRegister.wrapperInstance, kitConfiguration);
            
            MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
        }
    }
}

- (NSArray<NSDictionary<NSString *, id> *> *)userIdentitiesArrayForKit:(NSNumber *)kitCode {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
    if (!kitRegister) {
        return nil;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSArray<NSDictionary<NSString *, id> *> *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    __block NSMutableArray *forwardUserIdentities = [[NSMutableArray alloc] initWithCapacity:userIdentities.count];
        
    [userIdentities enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUserIdentity identityType = (MPUserIdentity)[obj[kMPUserIdentityTypeKey] integerValue];
        NSString *identityString = obj[kMPUserIdentityIdKey];
        MPKitFilter *kitFilter = [self filter:kitRegister forUserIdentityKey:identityString identityType:identityType];
        
        if (!kitFilter.shouldFilter) {
            [forwardUserIdentities addObject:obj];
        }
    }];
    return forwardUserIdentities;
}

- (nullable NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(nonnull NSNumber *)kitCode {
    NSArray<MPIntegrationAttributes *> *array = [[MPPersistenceController sharedInstance] fetchIntegrationAttributes];
    __block NSDictionary<NSString *, NSString *> *dictionary = nil;
    [array enumerateObjectsUsingBlock:^(MPIntegrationAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.kitCode.intValue == kitCode.intValue) {
            dictionary = obj.attributes;
            *stop = YES;
        }
    }];
    return dictionary;
}


/*
 * Original intention of this method is to ensure that any kits that set 
 * integration attributes have done so prior to the SDK's first upload.
 */
- (BOOL)shouldDelayUpload: (NSTimeInterval) maxWaitTime  {
    NSTimeInterval timeInterval = -1 * [_initializedTime timeIntervalSinceNow];
    if (timeInterval > maxWaitTime) {
        return NO;
    } else if (!self.kitsInitialized) {
        return YES;
    } else {
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
        for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:@selector(shouldDelayMParticleUpload)] &&
                [kitRegister.wrapperInstance shouldDelayMParticleUpload]) {
                MPILogDebug(@"Delaying initial upload for kit: %@", kitRegister.name);
                return YES;
            }
        }
    }
    return NO;
}

@end
