#import "MPIntegrationAttributes.h"
#import "MPKitInstanceValidator.h"
#import "MPILogger.h"

@implementation MPIntegrationAttributes

- (nonnull instancetype)initWithKitCode:(nonnull NSNumber *)kitCode attributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes {
    BOOL validKitCode = [MPKitInstanceValidator isValidKitCode:kitCode];
    
    __block BOOL validIntegrationAttributes = !MPIsNull(attributes) && attributes.count > 0;
    
    if (validKitCode && validIntegrationAttributes) {
        Class NSStringClass = [NSString class];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            validIntegrationAttributes = [key isKindOfClass:NSStringClass] && [obj isKindOfClass:NSStringClass];
            
            if (!validIntegrationAttributes) {
                MPILogError(@"Integration attributes must be a dictionary of string, string.");
                *stop = YES;
            }
        }];
    }

    if (!validKitCode || !validIntegrationAttributes) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _kitCode = kitCode;
        _attributes = attributes;
    }

    return self;
}

- (nonnull instancetype)initWithKitCode:(nonnull NSNumber *)kitCode attributesData:(nonnull NSData *)attributesData {
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
    
    self = [self initWithKitCode:kitCode attributes:attributes];
    return self;
}

#pragma mark MPDataModelProtocol
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary<NSString *, NSDictionary<NSString *, NSString*> *> *dictionary = @{[_kitCode stringValue]:_attributes};
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
