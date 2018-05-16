#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"

@interface MPIntegrationAttributes : MPDataModelAbstract <MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSNumber *kitCode;
@property (nonatomic, strong, nonnull) NSDictionary<NSString *, NSString *> *attributes;

- (nonnull instancetype)initWithKitCode:(nonnull NSNumber *)kitCode attributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes;
- (nonnull instancetype)initWithKitCode:(nonnull NSNumber *)kitCode attributesData:(nonnull NSData *)attributesData;

@end
