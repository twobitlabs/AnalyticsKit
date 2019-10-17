#import "MPIntegrationAttributes.h"
#import "MPILogger.h"
#import "MParticle.h"
#import "MPStateMachine.h"

@implementation MPIntegrationAttributes

- (nonnull instancetype)initWithIntegrationId:(nonnull NSNumber *)integrationId attributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes {
    
    if (![integrationId isKindOfClass:[NSNumber class]] || MPIsNull(attributes) || attributes.count == 0) {
        return nil;
    }
    
    __block BOOL validIntegrationAttributes = YES;
    Class NSStringClass = [NSString class];
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        validIntegrationAttributes = [key isKindOfClass:NSStringClass] && [obj isKindOfClass:NSStringClass];
        
        if (!validIntegrationAttributes) {
            MPILogError(@"Integration attributes must be a dictionary of string, string.");
            *stop = YES;
        }
    }];
    
    if (!validIntegrationAttributes) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _integrationId = integrationId;
        _attributes = attributes;
    }

    return self;
}

- (nonnull instancetype)initWithIntegrationId:(nonnull NSNumber *)integrationId attributesData:(nonnull NSData *)attributesData {
    NSError *error = nil;
    NSDictionary *attributes = nil;
    
    if (MPIsNull(attributesData)) {
        return nil;
    }
    
    @try {
        attributes = [NSJSONSerialization JSONObjectWithData:attributesData options:0 error:&error];
    } @catch (NSException *exception) {
    }
    
    if (!attributes && error != nil) {
        return nil;
    }
    
    self = [self initWithIntegrationId:integrationId attributes:attributes];
    return self;
}

#pragma mark MPDataModelProtocol
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary<NSString *, NSDictionary<NSString *, NSString*> *> *dictionary = @{[_integrationId stringValue]:_attributes};
    return dictionary;
}

- (NSString *)serializedString {
    NSDictionary *dictionaryRepresentation = [self dictionaryRepresentation];
    NSError *error = nil;
    NSData *dataRepresentation = nil;
    
    @try {
        dataRepresentation = [NSJSONSerialization dataWithJSONObject:dictionaryRepresentation options:0 error:&error];
    } @catch (NSException *exception) {
    }
    
    if (dataRepresentation.length == 0 && error != nil) {
        return nil;
    }
    
    NSString *stringRepresentation = [[NSString alloc] initWithData:dataRepresentation encoding:NSUTF8StringEncoding];
    return stringRepresentation;
}

@end
