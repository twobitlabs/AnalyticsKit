//
//  MPConsumerInfo.mm
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

#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "NSUserDefaults+mParticle.h"
#include "MPHasher.h"
#import "MPDateFormatter.h"
#import "MPPersistenceController.h"
#import "NSString+MPPercentEscape.h"

NSString *const kMPCKContent = @"c";
NSString *const kMPCKDomain = @"d";
NSString *const kMPCKExpiration = @"e";

#pragma mark - MPCookie
@implementation MPCookie

- (instancetype)initWithName:(NSString *)name configuration:(NSDictionary *)configuration {
    self = [super init];
    BOOL validName = !MPIsNull(name) && [name isKindOfClass:[NSString class]];
    BOOL validConfiguration = !MPIsNull(configuration) && [configuration isKindOfClass:[NSDictionary class]];
    
    if (!self || !validName || !validConfiguration) {
        return nil;
    }
    
    _cookieId = 0;
    self.content = !MPIsNull(configuration[kMPCKContent]) ? configuration[kMPCKContent] : nil;
    self.domain = !MPIsNull(configuration[kMPCKDomain]) ? configuration[kMPCKDomain] : nil;
    self.expiration = !MPIsNull(configuration[kMPCKExpiration]) ? configuration[kMPCKExpiration] : nil;
    self.name = name;
    
    return self;
}

- (BOOL)isEqual:(MPCookie *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPCookie class]]) {
        return NO;
    }
    
    BOOL isEqual = [_name isEqualToString:object.name];
    
//    if (isEqual && _content && object.content) {
//        isEqual = [_content isEqualToString:object.content];
//    } else if (isEqual && (_content || object.content)) {
//        return NO;
//    }
//    
//    if (isEqual && _domain && object.domain) {
//        isEqual = [_domain isEqualToString:object.domain];
//    } else if (isEqual && (_domain || object.domain)) {
//        return NO;
//    }
//    
//    if (isEqual && _expiration && object.expiration) {
//        isEqual = [_expiration isEqualToString:object.expiration];
//    } else if (isEqual && (_expiration || object.expiration)) {
//        return NO;
//    }
    
    return isEqual;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];

    if (_content) {
        [coder encodeObject:_content forKey:@"content"];
    }
    
    if (_domain) {
        [coder encodeObject:_domain forKey:@"domain"];
    }
    
    if (_expiration) {
        [coder encodeObject:_expiration forKey:@"expiration"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *name = [coder decodeObjectForKey:@"name"];
    
    NSMutableDictionary *configuration = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSString *value = [coder decodeObjectForKey:@"content"];
    if (value) {
        configuration[kMPCKContent] = value;
    }
    
    value = [coder decodeObjectForKey:@"domain"];
    if (value) {
        configuration[kMPCKDomain] = value;
    }
    
    value = [coder decodeObjectForKey:@"expiration"];
    if (value) {
        configuration[kMPCKExpiration] = value;
    }
    
    self = [self initWithName:name configuration:configuration];
    
    return self;
}

#pragma mark Public accessors
- (BOOL)expired {
    if (MPIsNull(_expiration)) {
        return YES;
    }
    
    NSDate *now = [NSDate date];
    NSDate *cookieDate = [MPDateFormatter dateFromStringRFC3339:_expiration];
    
    BOOL expired = [cookieDate compare:now] == NSOrderedAscending;
    return expired;
}

- (void)setContent:(NSString *)content {
    _content = content ? [content percentEscape] : nil;
}

- (void)setDomain:(NSString *)domain {
    _domain = domain ? [domain percentEscape] : nil;
}

- (void)setExpiration:(NSString *)expiration {
    _expiration = expiration ? [expiration percentEscape] : nil;
}

- (void)setName:(NSString *)name {
    NSAssert(name, @"Name cannot be nil");
    
    _name = [name percentEscape];
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *cookieDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (_content) {
        cookieDictionary[kMPCKContent] = _content;
    }
    
    if (_domain) {
        cookieDictionary[kMPCKDomain] = _domain;
    }

    if (_expiration) {
        cookieDictionary[kMPCKExpiration] = _expiration;
    }
    
    if (cookieDictionary.count == 0) {
        return (NSDictionary *)nil;
    }
    
    return (NSDictionary *)cookieDictionary;
}

@end

#pragma mark - MPConsumerInfo
@interface MPConsumerInfo () {
    dispatch_semaphore_t semaphore;
}

@end

@implementation MPConsumerInfo

@synthesize cookies = _cookies;
@synthesize mpId = _mpId;
@synthesize uniqueIdentifier = _uniqueIdentifier;

- (id)init {
    self = [super init];
    if (self) {
        _consumerInfoId = 0;
        semaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.cookies) {
        [coder encodeObject:_cookies forKey:@"cookies"];
    }
    
    if (self.mpId) {
        [coder encodeObject:_mpId forKey:@"mpId"];
    }

    if (self.uniqueIdentifier) {
        [coder encodeObject:_uniqueIdentifier forKey:@"uniqueIdentifier"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _cookies = [coder decodeObjectForKey:@"cookies"];
        _mpId = [coder decodeObjectForKey:@"mpId"];
        _uniqueIdentifier = [coder decodeObjectForKey:@"uniqueIdentifier"];
    }
    
    return self;
}

#pragma mark Private methods
- (NSNumber *)generateMpId {
    int64_t mpId = 0;
    while (!mpId) {
        NSString *uuidString = [[NSUUID UUID] UUIDString];
        NSData *uuidData = [uuidString dataUsingEncoding:NSUTF8StringEncoding];
        
        mpId = mParticle::Hasher::hashFNV1a((const char *)[uuidData bytes], (int)[uuidData length]);
    }
    
    NSNumber *generatedMpId;
    if (sizeof(void *) == 4) { // 32-bit
        generatedMpId = [NSNumber numberWithLongLong:mpId];
    } else if (sizeof(void *) == 8) { // 64-bit
        generatedMpId = [NSNumber numberWithLong:mpId];
    }
    
    return generatedMpId;
}

- (void)configureCookiesWithDictionary:(NSDictionary *)cookiesDictionary {
    if (MPIsNull(cookiesDictionary)) {
        return;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    NSMutableArray<MPCookie *> *cookies = [[NSMutableArray alloc] init];
    NSArray<MPCookie *> *fetchedCookies = [persistence fetchCookies];
    if (fetchedCookies) {
        [cookies addObjectsFromArray:fetchedCookies];
    }

    NSDictionary *localCookiesDictionary = [self localCookiesDictionary];
    if (localCookiesDictionary) {
        NSMutableDictionary *mCookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:(localCookiesDictionary.count + cookiesDictionary.count)];
        [mCookiesDictionary addEntriesFromDictionary:localCookiesDictionary];
        [mCookiesDictionary addEntriesFromDictionary:cookiesDictionary];
        cookiesDictionary = (NSDictionary *)mCookiesDictionary;
    }
    
    NSArray *keys = [cookiesDictionary allKeys];
    for (NSString *aKey in keys) {
        if (MPIsNull(aKey)) {
            continue;
        }
        
        MPCookie *cookie = [[MPCookie alloc] initWithName:aKey configuration:cookiesDictionary[aKey]];
        
        if (cookie) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", cookie.name];
            MPCookie *existingCookie = [[cookies filteredArrayUsingPredicate:predicate] firstObject];
            
            if (existingCookie) {
                existingCookie.content = cookie.content;
                existingCookie.domain = cookie.domain;
                existingCookie.expiration = cookie.expiration;
            } else {
                [cookies addObject:cookie];
            }
        }
    }
    
    _cookies = (NSArray *)cookies;
}

- (NSDictionary *)localCookiesDictionary {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *localCookies = userDefaults[kMPRemoteConfigCookiesKey];
    
    if (!localCookies) {
        return nil;
    }
    
    NSMutableDictionary *cookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:localCookies.count];
    NSString *key;
    
    NSEnumerator *cookiesEnumerator = [localCookies keyEnumerator];
    while ((key = [cookiesEnumerator nextObject])) {
        NSDictionary *cookieDictionary = localCookies[key];
        cookiesDictionary[key] = cookieDictionary;
    }
    
    [userDefaults removeMPObjectForKey:kMPRemoteConfigCookiesKey];
    
    return cookiesDictionary;
}

#pragma mark Public accessors
- (NSNumber *)mpId {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // If we don't have the id, create it.
    if (!_mpId) {
        [self willChangeValueForKey:@"mpId"];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *mpIdString = userDefaults[kMPRemoteConfigMPIDKey];
        
        if (mpIdString) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [userDefaults removeMPObjectForKey:kMPRemoteConfigMPIDKey];
            });
            
            if (sizeof(void *) == 4) { // 32-bit
                _mpId = [NSNumber numberWithLongLong:(long long)[mpIdString longLongValue]];
            } else if (sizeof(void *) == 8) { // 64-bit
                _mpId = [NSNumber numberWithLong:(long)[mpIdString longLongValue]];
            }
            
            if ([_mpId isEqualToNumber:@0]) {
                _mpId = [self generateMpId];
            }
        } else {
            _mpId = [self generateMpId];
        }
        
        [self didChangeValueForKey:@"mpId"];
    }

    dispatch_semaphore_signal(semaphore);
    
    return _mpId;
}

- (void)setMpId:(NSNumber *)mpId {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (MPIsNull(mpId)) {
        dispatch_semaphore_signal(semaphore);
        return;
    }
    
    if ([mpId isEqualToNumber:@0]) {
        _mpId = [self generateMpId];
    } else {
        _mpId = mpId;
    }
    
    dispatch_semaphore_signal(semaphore);
}

- (NSString *)uniqueIdentifier {
    if (_uniqueIdentifier) {
        return _uniqueIdentifier;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userDefaults[kMPRemoteConfigUniqueIdentifierKey]) {
        _uniqueIdentifier = userDefaults[kMPRemoteConfigUniqueIdentifierKey];
        [userDefaults removeMPObjectForKey:kMPRemoteConfigUniqueIdentifierKey];

        if (MPIsNull(_uniqueIdentifier)) {
            _uniqueIdentifier = nil;
        }
    }
    
    return _uniqueIdentifier;
}

- (void)setUniqueIdentifier:(NSString *)uniqueIdentifier {
    if (MPIsNull(uniqueIdentifier)) {
        return;
    }
    
    _uniqueIdentifier = [uniqueIdentifier percentEscape];
}

#pragma mark Public methods
- (NSDictionary *)cookiesDictionaryRepresentation {
    if (self.cookies.count == 0) {
        return (NSDictionary *)nil;
    }
    
    NSMutableDictionary *cookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.cookies.count];
    
    for (MPCookie *cookie in _cookies) {
        NSDictionary *cookieDictionary = [cookie dictionaryRepresentation];

        if (cookieDictionary) {
            cookiesDictionary[cookie.name] = cookieDictionary;
        }
    }
    
    if (cookiesDictionary.count == 0) {
        return (NSDictionary *)nil;
    }
    
    return (NSDictionary *)cookiesDictionary;
}

- (void)updateWithConfiguration:(NSDictionary *)configuration {
    if (MPIsNull(configuration) || ![configuration isKindOfClass:[NSDictionary class]] || configuration.count == 0) {
        return;
    }
    
    [self configureCookiesWithDictionary:configuration[kMPRemoteConfigCookiesKey]];
    self.mpId = !MPIsNull(configuration[kMPRemoteConfigMPIDKey]) ? configuration[kMPRemoteConfigMPIDKey] : nil;
    self.uniqueIdentifier = !MPIsNull(configuration[kMPRemoteConfigUniqueIdentifierKey]) ? configuration[kMPRemoteConfigUniqueIdentifierKey] : nil; // Unique Identifier ("das")
}

@end
