#import "MPKitConfiguration.h"
#include "MPHasher.h"
#import "MPIConstants.h"
#import "MPEventProjection.h"
#import "MPStateMachine.h"
#include "MessageTypeName.h"
#import "MPILogger.h"
#import "MPConsentSerialization.h"
#import "MParticle.h"

@interface MPKitConfiguration()
@property (nonatomic, strong) NSDictionary *configurationDictionary;
@end


@implementation MPKitConfiguration

@synthesize configurationDictionary = _configurationDictionary;

- (instancetype)initWithDictionary:(NSDictionary *)configurationDictionary {
    self = [super init];
    if (!self || MPIsNull(configurationDictionary)) {
        return nil;
    }
    
    NSData *ekConfigData = [NSJSONSerialization dataWithJSONObject:configurationDictionary options:0 error:nil];
    NSString *ekConfigString = [[NSString alloc] initWithData:ekConfigData encoding:NSUTF8StringEncoding];
    _configurationHash = @(mParticle::Hasher::hashFromString([ekConfigString cStringUsingEncoding:NSUTF8StringEncoding]));
    
    // Attribute value filtering
    NSDictionary *attributeValueFiltering = configurationDictionary[@"avf"];
    if (!MPIsNull(attributeValueFiltering)) {
        NSNumber *shouldIncludeMatches = !MPIsNull(attributeValueFiltering[@"i"]) ? attributeValueFiltering[@"i"] : nil;
        NSNumber *hashedAttribute = attributeValueFiltering[@"a"];
        NSNumber *hashedValue = attributeValueFiltering[@"v"];
        
        if (shouldIncludeMatches && hashedAttribute && hashedValue) {
            _attributeValueFilteringIsActive = YES;
            _attributeValueFilteringShouldIncludeMatches = [shouldIncludeMatches boolValue];
            _attributeValueFilteringHashedAttribute = [NSString stringWithFormat:@"%@", hashedAttribute];
            _attributeValueFilteringHashedValue = [NSString stringWithFormat:@"%@", hashedValue];
        }
    }
    
    // Filters
    [self setFilters:configurationDictionary[kMPRemoteConfigKitHashesKey]];
    
    // Configuration
    _configuration = configurationDictionary[@"as"];
    if (_configuration) {
        NSMutableDictionary *configDictionary = [_configuration mutableCopy];
        
        if (_addEventAttributeList) {
            configDictionary[@"eaa"] = _addEventAttributeList;
        }
        
        if (_removeEventAttributeList) {
            configDictionary[@"ear"] = _removeEventAttributeList;
        }
        
        if (_singleItemEventAttributeList) {
            configDictionary[@"eas"] = _singleItemEventAttributeList;
        }
        
        for (NSString *key in configDictionary.allKeys) {
            id value = configDictionary[key];
            if ((NSNull *)value == [NSNull null]) {
                [configDictionary removeObjectForKey:key];
            }
        }
        
        _configuration = [configDictionary copy];
    }
    
    // Projections
    [self configureProjections:configurationDictionary[@"pr"]];
    
    // Consent kit filter
    if (configurationDictionary[kMPConsentKitFilter]) {
        _consentKitFilter = [MPConsentSerialization filterFromDictionary:configurationDictionary[kMPConsentKitFilter]];
    }
    
    // Kit instance
    _bracketConfiguration = !MPIsNull(configurationDictionary[kMPRemoteConfigBracketKey]) ? configurationDictionary[kMPRemoteConfigBracketKey] : nil;
    
    _integrationId = !MPIsNull(configurationDictionary[@"id"]) ? configurationDictionary[@"id"] : nil;
    
    if (_integrationId != nil) {
        _configurationDictionary = configurationDictionary;
        _excludeAnonymousUsers = [configurationDictionary[kMPRemoteConfigExcludeAnonymousUsersKey] boolValue];
    } else {
        return nil;
    }
    
    return self;
}

- (BOOL)isEqual:(MPKitConfiguration *)object {
    return [_configurationHash isEqualToNumber:object.configurationHash];
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.configurationDictionary forKey:@"configurationDictionary"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSDictionary *configurationDictionary;
    
    @try {
        configurationDictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"configurationDictionary"];
    }
    
    @catch ( NSException *e) {
        configurationDictionary = nil;
        MPILogError(@"Exception decoding MPKitConfiguration Attributes: %@", [e reason]);
    }
    
    @finally {
        self = [self initWithDictionary:configurationDictionary];
    }
    
    self = [self initWithDictionary:configurationDictionary];
    if (!self) {
        return nil;
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPKitConfiguration *copyObject = [[MPKitConfiguration alloc] initWithDictionary:_configurationDictionary];

    return copyObject;
}

#pragma mark Public accessors
- (void)setFilters:(NSDictionary *)filters {
    if (_filters && [_filters isEqualToDictionary:filters]) {
        return;
    }
    
    if (!MPIsNull(filters)) {
        NSMutableDictionary *sanitizedFilters = [[NSMutableDictionary alloc] initWithCapacity:filters.count];
        [filters enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            if (!MPIsNull(obj)) {
                sanitizedFilters[key] = obj;
            }
        }];
        
        filters = sanitizedFilters.count > 0 ? [sanitizedFilters copy] : nil;
    } else {
        filters = nil;
    }
    
    _filters = filters;
    
    _eventTypeFilters = _filters[@"et"];
    _eventNameFilters = _filters[@"ec"];
    _eventAttributeFilters = _filters[@"ea"];
    _messageTypeFilters = _filters[@"mt"];
    _screenNameFilters = _filters[@"svec"];
    _screenAttributeFilters = _filters[@"svea"];
    _userIdentityFilters = _filters[@"uid"];
    _userAttributeFilters = _filters[@"ua"];
    _commerceEventAttributeFilters = _filters[@"cea"];
    _commerceEventEntityTypeFilters = _filters[@"ent"];
    _commerceEventAppFamilyAttributeFilters = _filters[@"afa"];
    _addEventAttributeList = _filters[@"eaa"];
    _removeEventAttributeList = _filters[@"ear"];
    _singleItemEventAttributeList = _filters[@"eas"];
    _consentRegulationFilters = _filters[kMPConsentRegulationFilters];
    _consentPurposeFilters = _filters[kMPConsentPurposeFilters];
}

#pragma mark Public methods

- (void)configureProjections:(NSArray *)projections {
    _defaultProjections = nil;
    
    if (MPIsNull(projections) || projections.count == 0) {
        _projections = nil;
        return;
    }
    
    auto numberOfMessageTypes = mParticle::MessageTypeName::size();
    vector<NSNumber *> configuredMessageTypeProjectionsVector;
    configuredMessageTypeProjectionsVector.reserve(numberOfMessageTypes);
    vector<MPEventProjection *> defaultProjectionsVector;
    defaultProjectionsVector.reserve(numberOfMessageTypes);
    vector<MPEventProjection *> projectionsVector;
    projectionsVector.reserve(projections.count - 1);
    
    for (NSUInteger i = 0; i < numberOfMessageTypes; ++i) {
        configuredMessageTypeProjectionsVector.push_back(@NO);
        defaultProjectionsVector.push_back((MPEventProjection *)[NSNull null]);
    }
    
    for (NSDictionary *projectionDictionary in projections) {
        MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:projectionDictionary];
        
        if (eventProjection) {
            configuredMessageTypeProjectionsVector[eventProjection.messageType] = @YES;
            
            if (eventProjection.isDefault) {
                defaultProjectionsVector[eventProjection.messageType] = eventProjection;
            } else {
                projectionsVector.push_back(eventProjection);
            }
        }
    }
    
    _configuredMessageTypeProjections = [NSArray arrayWithObjects:&configuredMessageTypeProjectionsVector[0] count:configuredMessageTypeProjectionsVector.size()];
    _defaultProjections = [NSArray arrayWithObjects:&defaultProjectionsVector[0] count:defaultProjectionsVector.size()];
    _projections = !projectionsVector.empty() ? [NSArray arrayWithObjects:&projectionsVector[0] count:projectionsVector.size()] : nil;
}

@end
