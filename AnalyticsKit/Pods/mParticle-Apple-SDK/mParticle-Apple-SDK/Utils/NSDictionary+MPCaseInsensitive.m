#import "NSDictionary+MPCaseInsensitive.h"
#import "MPDateFormatter.h"
#import "MPILogger.h"
#import "MParticle.h"

@implementation NSDictionary(MPCaseInsensitive)

- (NSString *)caseInsensitiveKey:(NSString *)key {
    __block NSString *localKey = nil;

    @try {
        NSString *lowerCaseKey = [key lowercaseString];
        NSArray *keys = [self allKeys];
        [keys enumerateObjectsWithOptions:NSEnumerationConcurrent
                               usingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
                                   if ([lowerCaseKey isEqualToString:[aKey lowercaseString]]) {
                                       localKey = aKey;
                                       *stop = YES;
                                   }
                               }];
    } @catch (NSException *exception) {
        MPILogError(@"Exception retrieving case insentitive key: %@", [exception reason]);
    }

    if (!localKey) {
        localKey = key;
    }
    
    return localKey;
}

- (id)valueForCaseInsensitiveKey:(NSString *)key {
    __block id value = nil;

    @try {
        NSString *lowerCaseKey = [key lowercaseString];
        NSArray *keys = [self allKeys];
        [keys enumerateObjectsWithOptions:NSEnumerationConcurrent
                               usingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
                                   if ([lowerCaseKey isEqualToString:[aKey lowercaseString]]) {
                                       value = self[aKey];
                                       *stop = YES;
                                   }
                               }];
    } @catch (NSException *exception) {
        MPILogError(@"Exception retrieving case insentitive value: %@", [exception reason]);
    }

    return value;
}

- (NSDictionary<NSString *, NSString *> *)transformValuesToString {
    NSDictionary *originalDictionary = self;
    __block NSMutableDictionary<NSString *, NSString *> *transformedDictionary = [[NSMutableDictionary alloc] initWithCapacity:originalDictionary.count];
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    
    [originalDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:NSStringClass]) {
            transformedDictionary[key] = obj;
        } else if ([obj isKindOfClass:NSNumberClass]) {
            NSNumber *numberAttribute = (NSNumber *)obj;
            
            if (numberAttribute == (void *)kCFBooleanFalse || numberAttribute == (void *)kCFBooleanTrue) {
                transformedDictionary[key] = [numberAttribute boolValue] ? @"Y" : @"N";
            } else {
                transformedDictionary[key] = [numberAttribute stringValue];
            }
        } else if ([obj isKindOfClass:[NSDate class]]) {
            transformedDictionary[key] = [MPDateFormatter stringFromDateRFC3339:obj];
        } else if ([obj isKindOfClass:[NSData class]] && [(NSData *)obj length] > 0) {
            transformedDictionary[key] = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        } else {
            MPILogError(@"Data type is not supported as an attribute value: %@ - %@", obj, [[obj class] description]);
            NSAssert([obj isKindOfClass:[NSString class]], @"Data type is not supported as an attribute value");
            return;
        }
    }];
    
    return (NSDictionary *)transformedDictionary;
}

@end
