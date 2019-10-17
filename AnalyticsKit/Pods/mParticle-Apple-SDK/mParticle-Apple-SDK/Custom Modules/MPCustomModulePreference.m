#import "MPCustomModulePreference.h"
#import "MPIUserDefaults.h"
#import "MPAppboy.h"
#import "MPILogger.h"
#import "MPDateFormatter.h"
#import "MPPersistenceController.h"
#import "MParticle.h"

@interface MPCustomModulePreference()

@property (nonatomic, strong) NSString *location;

@end


@implementation MPCustomModulePreference

- (instancetype)initWithDictionary:(NSDictionary *)preferenceDictionary location:(NSString *)location moduleId:(NSNumber *)moduleId {
    self = [super init];

    _readKey = preferenceDictionary[kMPRemoteConfigCustomModuleReadKey];
    _writeKey = preferenceDictionary[kMPRemoteConfigCustomModuleWriteKey];

    if (!self || MPIsNull(moduleId) || MPIsNull(_readKey) || MPIsNull(_writeKey)) {
        return nil;
    }
    
    id temp = preferenceDictionary[kMPRemoteConfigCustomModuleDataTypeKey];
    if (!MPIsNull(temp) && [temp isKindOfClass:[NSNumber class]]) {
        _dataType = [(NSNumber *)temp intValue];
    } else {
        _dataType = MPDataTypeString;
    }
    
    _moduleId = [moduleId copy];

    NSArray *macroPlaceholders = @[@"%gn%", @"%oaid%", @"%dt%", @"%glsb%", @"%g%"];
    NSString *defaultValue = preferenceDictionary[kMPRemoteConfigCustomModuleDefaultKey];
    
    if ([macroPlaceholders containsObject:defaultValue]) {
        _defaultValue = [self defaultValueForMacroPlaceholder:defaultValue];
    } else {
        if (!MPIsNull(defaultValue) && [defaultValue isKindOfClass:[NSString class]]) {
            _defaultValue = defaultValue;
        } else {
            switch (_dataType) {
                case MPDataTypeString:
                    _defaultValue = @"";
                    break;
                    
                case MPDataTypeInt:
                case MPDataTypeLong:
                    _defaultValue = @"0";
                    break;
                    
                case MPDataTypeBool:
                    _defaultValue = @"false";
                    break;
                    
                case MPDataTypeFloat:
                    _defaultValue = @"0.0";
                    break;
            }
        }
    }
    
    _location = location;
    
    return self;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.defaultValue forKey:@"defaultValue"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.readKey forKey:@"readKey"];
    [coder encodeObject:self.value forKey:@"value"];
    [coder encodeObject:self.writeKey forKey:@"writeKey"];
    [coder encodeInteger:self.dataType forKey:@"dataType"];
    [coder encodeInt64:self.moduleId.longLongValue forKey:@"moduleId"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _defaultValue = [coder decodeObjectOfClass:[NSString class] forKey:@"defaultValue"];
        _location = [coder decodeObjectOfClass:[NSString class] forKey:@"location"];
        _readKey = [coder decodeObjectOfClass:[NSString class] forKey:@"readKey"];
        _value = [coder decodeObjectOfClass:[NSObject class] forKey:@"value"];
        _writeKey = [coder decodeObjectOfClass:[NSString class] forKey:@"writeKey"];
        _dataType = [coder decodeIntegerForKey:@"dataType"];
        _moduleId = @([coder decodeInt64ForKey:@"moduleId"]);
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Private methods
- (NSString *)appBoyJSONStringFromDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (dictionary[@"deviceIdentifier"]) {
        jsonDictionary[@"deviceIdentifier"] = dictionary[@"deviceIdentifier"];
    }
    
    if (dictionary[@"externalUserId"]) {
        jsonDictionary[@"externalUserId"] = dictionary[@"externalUserId"];
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    NSString *jsonString = nil;
    if (!error) {
        jsonString  = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

- (NSString *)defaultValueForMacroPlaceholder:(NSString *)macroPlaceholder __attribute__((no_sanitize("integer"))) {
    NSString *defaultValue = @"";
    
    if ([macroPlaceholder isEqualToString:@"%gn%"]) {
        defaultValue = [self uuidWithNoDashes];
    } else if ([macroPlaceholder isEqualToString:@"%oaid%"]) {
        NSString *uuidString = [self uuidWithNoDashes];
        
        const char *c_uuidString = [uuidString cStringUsingEncoding:NSASCIIStringEncoding];
        char pos0 = c_uuidString[0];
        char pos16 = c_uuidString[16];
        
        if (pos0 >= '8') {
            pos0 = (char)(arc4random_uniform(8) + '0');
        }
        
        if (pos16 >= '4') {
            pos16 = (char)(arc4random_uniform(4) + '0');
        }
        
        defaultValue = [[NSString alloc] initWithFormat:@"%c%@-%c%@", pos0, [uuidString substringWithRange:NSMakeRange(1, 15)], pos16, [uuidString substringWithRange:NSMakeRange(17, 15)]];
    } else if ([macroPlaceholder isEqualToString:@"%dt%"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss Z"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

        defaultValue = [dateFormatter stringFromDate:[NSDate date]];
    } else if ([macroPlaceholder isEqualToString:@"%glsb%"]) {
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuidRef);
        
        SInt64 lsbBytes[8] = {uuidBytes.byte8, uuidBytes.byte9, uuidBytes.byte10, uuidBytes.byte11,
                              uuidBytes.byte12, uuidBytes.byte13, uuidBytes.byte14, uuidBytes.byte15};
        
        SInt64 value = 0;
        int i = 8;
        while (i--) {
            value |= lsbBytes[i] << ((7 - i) * 8);
        }

        CFRelease(uuidRef);

        defaultValue = [@(value) stringValue];
    } else if ([macroPlaceholder isEqualToString:@"%g%"]) {
        defaultValue = [[NSUUID UUID] UUIDString];
    }
    
    return defaultValue;
}

- (NSString *)uuidWithNoDashes {
    NSMutableString *uuidString = [NSMutableString stringWithString:[[NSUUID UUID] UUIDString]];
    NSRange dashRange = [uuidString rangeOfString:@"-"];
    
    while (dashRange.location != NSNotFound) {
        [uuidString deleteCharactersInRange:dashRange];
        dashRange = [uuidString rangeOfString:@"-"];
    }
    
    return [uuidString copy];
}

#pragma mark Public methods
- (id)value {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    NSString *deprecatedKey = [NSString stringWithFormat:@"cms::%@", self.writeKey];
    NSString *customModuleKey = [NSString stringWithFormat:@"cms::%@::%@", self.moduleId, self.writeKey];
    NSNumber *mpId = [MPPersistenceController mpId];
    id valueWithDeprecatedKey = [userDefaults mpObjectForKey:deprecatedKey userId:mpId];
    if (valueWithDeprecatedKey) {
        _value = valueWithDeprecatedKey;
        [userDefaults setMPObject:_value forKey:customModuleKey userId:mpId];
        [userDefaults removeMPObjectForKey:deprecatedKey userId:mpId];
        return _value;
    }
    _value = [userDefaults mpObjectForKey:customModuleKey userId:mpId];
    if (_value) {
        return _value;
    }
    
    NSDictionary *userDefaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    NSArray *keys = [userDefaultsDictionary allKeys];

    if ([keys containsObject:self.readKey]) {
        if ([_moduleId isEqual:@(MPCustomModuleIdAppBoy)]) {
            NSData *appboyData = [[NSUserDefaults standardUserDefaults] objectForKey:_readKey];
            if (appboyData) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                id appboy = [NSKeyedUnarchiver unarchiveObjectWithData:appboyData];
#pragma clang diagnostic pop

                if ([appboy isKindOfClass:[NSDictionary class]]) {
                    _value = [self appBoyJSONStringFromDictionary:appboy];
                } else {
                    @try {
                        _value = [appboy jsonString];
                    } @catch (NSException *exception) {
                        MPILogError(@"Could not parse Appboy data with exception reason: %@", [exception reason]);
                    }
                }
            }
        } else {
            id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:_readKey];
            if (!MPIsNull(storedValue)) {
                _value = [storedValue isKindOfClass:[NSDate class]] ? [MPDateFormatter stringFromDateRFC3339:storedValue] : storedValue;
            }
        }
        
        if (!_value && _dataType != MPDataTypeString) {
            switch (_dataType) {
                case MPDataTypeInt:
                case MPDataTypeLong:
                    _value = @([[NSUserDefaults standardUserDefaults] integerForKey:_readKey]);
                    break;
                    
                case MPDataTypeBool:
                    _value = @([[NSUserDefaults standardUserDefaults] boolForKey:_readKey]);
                    break;
                    
                case MPDataTypeFloat:
                    _value = @([[NSUserDefaults standardUserDefaults] floatForKey:_readKey]);
                    break;
                    
                default:
                    _value = self.defaultValue;
                    break;
            }
        }
    } else {
        switch (self.dataType) {
            case MPDataTypeString:
                _value = self.defaultValue;
                break;
                
            case MPDataTypeInt:
            case MPDataTypeLong:
                _value = @([self.defaultValue integerValue]);
                break;
                
            case MPDataTypeBool:
                _value = [self.defaultValue isEqualToString:@"false"] || [self.defaultValue isEqualToString:@"NO"] || [self.defaultValue isEqualToString:@"0"] ? @NO : @YES;
                break;
                
            case MPDataTypeFloat:
                _value = @([self.defaultValue floatValue]);
                break;
        }
    }
    [userDefaults setMPObject:_value forKey:customModuleKey userId:mpId];
    
    return _value;
}

@end
