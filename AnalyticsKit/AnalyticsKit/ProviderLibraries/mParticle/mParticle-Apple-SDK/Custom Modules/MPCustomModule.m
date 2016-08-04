//
//  MPCustomModule.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_customModuleId forKey:@"customModuleId"];
    
    if (_preferences) {
        [coder encodeObject:_preferences forKey:@"preferences"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _customModuleId = [coder decodeObjectForKey:@"customModuleId"];
        _preferences = [coder decodeObjectForKey:@"preferences"];
    }
    
    return self;
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
