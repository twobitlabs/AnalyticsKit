#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPILogger.h"
#import "MPIConstants.h"
#import "MPGDPRConsent.h"
#import "MPConsentKitFilter.h"
#import "MParticle.h"

@implementation MPConsentSerialization

#pragma mark public methods

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, MPGDPRConsent *> *gdprStateDictionary = [state gdprConsentState];
    if (!gdprStateDictionary || gdprStateDictionary.count == 0) {
        return dictionary;
    }
    
    NSMutableDictionary *gdprDictionary = [NSMutableDictionary dictionary];
    for (NSString *purpose in gdprStateDictionary) {
        MPGDPRConsent *gdprConsent = gdprStateDictionary[purpose];
        NSMutableDictionary *gdprConsentDictionary = [NSMutableDictionary dictionary];
        
        if (gdprConsent.consented) {
            gdprConsentDictionary[kMPConsentStateGDPRConsented] = @YES;
        } else {
            gdprConsentDictionary[kMPConsentStateGDPRConsented] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[kMPConsentStateGDPRDocument] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[kMPConsentStateGDPRTimestamp] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[kMPConsentStateGDPRLocation] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[kMPConsentStateGDPRHardwareId] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[kMPConsentStateGDPR] = gdprDictionary;
    }
    return dictionary;
}

+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state {
    if (!state) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSDictionary<NSString *, MPGDPRConsent *> *gdprStateDictionary = [state gdprConsentState];
    if (!gdprStateDictionary || gdprStateDictionary.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *gdprDictionary = [NSMutableDictionary dictionary];
    for (NSString *purpose in gdprStateDictionary) {
        MPGDPRConsent *gdprConsent = gdprStateDictionary[purpose];
        NSMutableDictionary *gdprConsentDictionary = [NSMutableDictionary dictionary];
        
        if (gdprConsent.consented) {
            gdprConsentDictionary[kMPConsentStateGDPRConsentedKey] = @YES;
        } else {
            gdprConsentDictionary[kMPConsentStateGDPRConsentedKey] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[kMPConsentStateGDPRDocumentKey] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[kMPConsentStateGDPRTimestampKey] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[kMPConsentStateGDPRLocationKey] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[kMPConsentStateGDPRHardwareIdKey] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[kMPConsentStateGDPRKey] = gdprDictionary;
    }
    
    if (dictionary.count == 0) {
        return nil;
    }
    
    NSString *string = [self stringFromDictionary:dictionary];
    if (!string) {
        MPILogError(@"Failed to create string from consent dictionary=%@", dictionary);
        return nil;
    }
    return string;
}

+ (nullable MPConsentState *)consentStateFromString:(NSString *)string {
    MPConsentState *state = nil;
    NSDictionary *dictionary = [self dictionaryFromString:string];
    if (!dictionary) {
        MPILogError(@"Failed to create consent state from string=%@", string);
        return nil;
    }
    
    NSDictionary *gdprDictionary = dictionary[kMPConsentStateGDPRKey];
    if (!gdprDictionary) {
        return nil;
    }
    
    state = [[MPConsentState alloc] init];
    
    for (NSString *purpose in gdprDictionary) {
        NSDictionary *gdprConsentDictionary = gdprDictionary[purpose];
        MPGDPRConsent *gdprState = [[MPGDPRConsent alloc] init];
        
        if ([gdprConsentDictionary[kMPConsentStateGDPRConsentedKey] isEqual:@YES]) {
            gdprState.consented = YES;
        } else {
            gdprState.consented = NO;
        }
        
        if (gdprConsentDictionary[kMPConsentStateGDPRDocumentKey]) {
            gdprState.document = gdprConsentDictionary[kMPConsentStateGDPRDocumentKey];
        }
        
        if (gdprConsentDictionary[kMPConsentStateGDPRTimestampKey]) {
            NSNumber *timestamp = gdprConsentDictionary[kMPConsentStateGDPRTimestampKey];
            gdprState.timestamp = [NSDate dateWithTimeIntervalSince1970:(timestamp.doubleValue/1000)];
        }
        
        if (gdprConsentDictionary[kMPConsentStateGDPRLocationKey]) {
            gdprState.location = gdprConsentDictionary[kMPConsentStateGDPRLocationKey];
        }
        
        if (gdprConsentDictionary[kMPConsentStateGDPRHardwareIdKey]) {
            gdprState.hardwareId = gdprConsentDictionary[kMPConsentStateGDPRHardwareIdKey];
        }
        
        [state addGDPRConsentState:gdprState purpose:purpose];
    }
    
    return state;
}

#pragma mark private helpers

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string {
    const char *rawString = string.UTF8String;
    NSUInteger length = string.length;
    if (rawString == NULL || length == 0) {
        MPILogError(@"Empty or invalid UTF-8 C string when trying to convert string=%@", string);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:rawString length:length];
    if (!data) {
        MPILogError(@"Unable to create NSData with UTF-8 rawString=%s length=%@", rawString, @(length));
        return nil;
    }
    
    NSError *error = nil;
    id jsonObject = nil;
    @try {
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    } @catch(NSException *e) {
        MPILogError(@"Caught exception while creating dictionary from data: %@", data);
        return nil;
    }
    
    if (error) {
        MPILogError(@"Creating JSON object failed with error=%@ when trying to deserialize data=%@", error, data);
        return nil;
    }
    
    if (!jsonObject) {
        MPILogError(@"Unable to create JSON object from data=%@", data);
        return nil;
    }
    
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unable to create NSDictionary (got %@ instead) when trying to deserialize JSON data=%@", [jsonObject class], data);
        return nil;
    }
    
    NSDictionary *dictionary = (NSDictionary *)jsonObject;
    return dictionary;
}

+ (nullable NSString *)stringFromDictionary:(NSDictionary *)dictionary {
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    } @catch(NSException *e) {
        MPILogError(@"Caught exception while creating data from dictionary: %@", dictionary);
        return nil;
    }

    if (error) {
        MPILogError(@"NSJSONSerialization returned an error=%@ when trying to serialize dictionary=%@", error, dictionary);
        return nil;
    }
    if (!data) {
        MPILogError(@"Unable to create NSData with dictionary=%@", dictionary);
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string) {
        MPILogError(@"Unable to create UTF-8 string from JSON data=%@ dictionary=%@", data, dictionary);
        return nil;
    }
    return string;
}

+ (MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary {
    
    MPConsentKitFilter *filter = nil;
    
    if (configDictionary && [configDictionary isKindOfClass:[NSDictionary class]]) {
        
        filter = [[MPConsentKitFilter alloc] init];
        
        if (configDictionary[kMPConsentKitFilterIncludeOnMatch]  && [configDictionary[kMPConsentKitFilterIncludeOnMatch] isKindOfClass:[NSNumber class]]) {
            filter.shouldIncludeOnMatch = ((NSNumber *)configDictionary[kMPConsentKitFilterIncludeOnMatch]).boolValue;
        }
        
        NSDictionary *itemsArray = configDictionary[kMPConsentKitFilterItems];
        if (itemsArray && [itemsArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *items = [NSMutableArray array];
            
            for (NSDictionary *itemDictionary in itemsArray) {
                
                if ([itemDictionary isKindOfClass:[NSDictionary class]]) {
                    
                    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
                    
                    if (itemDictionary[kMPConsentKitFilterItemConsented] && [itemDictionary[kMPConsentKitFilterItemConsented] isKindOfClass:[NSNumber class]]) {
                        item.consented = ((NSNumber *)itemDictionary[kMPConsentKitFilterItemConsented]).boolValue;
                    }
                    
                    if (itemDictionary[kMPConsentKitFilterItemHash]  && [itemDictionary[kMPConsentKitFilterItemHash] isKindOfClass:[NSNumber class]]) {
                        item.javascriptHash = ((NSNumber *)itemDictionary[kMPConsentKitFilterItemHash]).intValue;
                    }
                    
                    [items addObject:item];
                    
                }
                
            }
            
            filter.filterItems = [items copy];
            
        }
    }
    
    return filter;
}

@end
