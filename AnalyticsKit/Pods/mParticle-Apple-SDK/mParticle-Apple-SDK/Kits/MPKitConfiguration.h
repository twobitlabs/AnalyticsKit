#import <Foundation/Foundation.h>

@class MPEventProjection;
@class MPConsentKitFilter;

@interface MPKitConfiguration : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, strong, readonly, nonnull) NSNumber *configurationHash;
@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *filters;
@property (nonatomic, strong, readonly, nullable) NSDictionary *bracketConfiguration;
@property (nonatomic, strong, readonly, nullable) NSArray<NSNumber *> *configuredMessageTypeProjections;
@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *defaultProjections;
@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *projections;
@property (nonatomic, strong, readonly, nullable) NSNumber *integrationId;

@property (nonatomic, assign) BOOL attributeValueFilteringIsActive;
@property (nonatomic, assign) BOOL attributeValueFilteringShouldIncludeMatches;
@property (nonatomic, strong, nullable) NSString *attributeValueFilteringHashedAttribute;
@property (nonatomic, strong, nullable) NSString *attributeValueFilteringHashedValue;

@property (nonatomic, weak, readonly, nullable) NSDictionary *eventTypeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *eventNameFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *eventAttributeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *messageTypeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *screenNameFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *screenAttributeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *userIdentityFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *userAttributeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *commerceEventAttributeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *commerceEventEntityTypeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *commerceEventAppFamilyAttributeFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *addEventAttributeList;
@property (nonatomic, weak, readonly, nullable) NSDictionary *removeEventAttributeList;
@property (nonatomic, weak, readonly, nullable) NSDictionary *singleItemEventAttributeList;
@property (nonatomic, weak, readonly, nullable) NSDictionary *consentRegulationFilters;
@property (nonatomic, weak, readonly, nullable) NSDictionary *consentPurposeFilters;
@property (nonatomic, strong, readonly, nullable) MPConsentKitFilter *consentKitFilter;
@property (nonatomic, readonly) BOOL excludeAnonymousUsers;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)configurationDictionary;

@end
