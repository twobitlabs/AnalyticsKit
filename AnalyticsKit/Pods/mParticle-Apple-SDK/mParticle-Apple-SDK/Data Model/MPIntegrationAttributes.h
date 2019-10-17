#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"

@interface MPIntegrationAttributes : MPDataModelAbstract <MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSNumber *integrationId;
@property (nonatomic, strong, nonnull) NSDictionary<NSString *, NSString *> *attributes;

- (nonnull instancetype)initWithIntegrationId:(nonnull NSNumber *)integrationId attributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes;
- (nonnull instancetype)initWithIntegrationId:(nonnull NSNumber *)integrationId attributesData:(nonnull NSData *)attributesData;

@end
