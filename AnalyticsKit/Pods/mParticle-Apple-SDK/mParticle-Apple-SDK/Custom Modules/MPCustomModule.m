#import "MPCustomModule.h"
#import "MPIConstants.h"
#import "MPCustomModulePreference.h"

@interface MPCustomModule()

@property (nonatomic, strong) NSDictionary *dictionaryRepresentation;

@end


@implementation MPCustomModule

- (instancetype)initWithDictionary:(NSDictionary *)customModuleDictionary {
    self = [super init];
    if (self) {
        _customModuleId = customModuleDictionary[kMPRemoteConfigCustomModuleIdKey];
        NSArray *preferences = customModuleDictionary[kMPRemoteConfigCustomModulePreferencesKey];
        Class arrayClass = [NSArray class];
        if (MPIsNull(_customModuleId) || ![_customModuleId isKindOfClass:[NSNumber class]] || MPIsNull(preferences) || ![preferences isKindOfClass:arrayClass]) {
            return nil;
        }
        
        NSMutableArray<MPCustomModulePreference *> *localPreferences = [[NSMutableArray alloc] initWithCapacity:preferences.count];
        NSString *location;
        NSArray *preferenceSettings;
        MPCustomModulePreference *preference;
        for (NSDictionary *preferenceDictionary in preferences) {
            if (MPIsNull(preferenceDictionary) || ![preferenceDictionary isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            id temp = preferenceDictionary[kMPRemoteConfigCustomModuleLocationKey];
            location = !MPIsNull(temp) ? (NSString *)temp : @"NSUserDefaults";
            
            temp = preferenceDictionary[kMPRemoteConfigCustomModulePreferenceSettingsKey];
            preferenceSettings = !MPIsNull(temp) && [temp isKindOfClass:arrayClass] ? (NSArray *)temp : nil;
            
            for (NSDictionary *preferenceSettingDictionary in preferenceSettings) {
                preference = [[MPCustomModulePreference alloc] initWithDictionary:preferenceSettingDictionary location:location moduleId:_customModuleId];
                
                if (preference) {
                    [localPreferences addObject:preference];
                }
            }
        }
        
        if (localPreferences.count == 0) {
            localPreferences = nil;
        }
        _preferences = (NSArray *)localPreferences;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MPCustomModule\n %@", [self dictionaryRepresentation]];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [[self dictionaryRepresentation] isEqualToDictionary:[(MPCustomModule *)object dictionaryRepresentation]];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPCustomModule *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_customModuleId = [_customModuleId copy];
        copyObject->_preferences = [_preferences copy];
    }
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_customModuleId forKey:@"customModuleId"];
    
    if (_preferences) {
        [coder encodeObject:_preferences forKey:@"preferences"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _customModuleId = [coder decodeObjectOfClass:[NSNumber class] forKey:@"customModuleId"];
        _preferences = [coder decodeObjectOfClass:[NSArray<MPCustomModulePreference *> class] forKey:@"preferences"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public
- (NSDictionary *)dictionaryRepresentation {
    if (_dictionaryRepresentation) {
        return _dictionaryRepresentation;
    }
    
    NSMutableDictionary *customModuleDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.preferences.count];
    for (MPCustomModulePreference *preference in self.preferences) {
        customModuleDictionary[preference.writeKey] = preference.value;
    }

    _dictionaryRepresentation = [customModuleDictionary copy];
    
    return _dictionaryRepresentation;
}

@end
