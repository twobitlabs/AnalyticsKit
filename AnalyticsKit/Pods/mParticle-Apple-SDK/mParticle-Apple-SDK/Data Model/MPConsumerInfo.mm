#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPIUserDefaults.h"
#include "MPHasher.h"
#import "MPDateFormatter.h"
#import "MPPersistenceController.h"
#import "NSString+MPPercentEscape.h"
#import "mParticle.h"

NSString *const kMPCKContent = @"c";
NSString *const kMPCKDomain = @"d";
NSString *const kMPCKExpiration = @"e";

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;

@end

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
    return isEqual;
}

#pragma mark NSSecureCoding
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
    NSString *value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"content"];
    if (value) {
        configuration[kMPCKContent] = value;
    }
    
    value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"domain"];
    if (value) {
        configuration[kMPCKDomain] = value;
    }
    
    value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"expiration"];
    if (value) {
        configuration[kMPCKExpiration] = value;
    }
    
    self = [self initWithName:name configuration:configuration];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
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
@implementation MPConsumerInfo

@synthesize cookies = _cookies;
@synthesize uniqueIdentifier = _uniqueIdentifier;

- (id)init {
    self = [super init];
    if (self) {
        _consumerInfoId = 0;
    }
    
    return self;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.cookies) {
        [coder encodeObject:_cookies forKey:@"cookies"];
    }
    if (self.uniqueIdentifier) {
        [coder encodeObject:_uniqueIdentifier forKey:@"uniqueIdentifier"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _cookies = [coder decodeObjectOfClass:[NSArray<MPCookie *> class] forKey:@"cookies"];
        _uniqueIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"uniqueIdentifier"];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Private methods
- (void)configureCookiesWithDictionary:(NSDictionary *)cookiesDictionary {
    if (MPIsNull(cookiesDictionary)) {
        return;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSMutableArray<MPCookie *> *cookies = [[NSMutableArray alloc] init];
    NSArray<MPCookie *> *fetchedCookies = [persistence fetchCookiesForUserId:[MPPersistenceController mpId]];
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
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSDictionary *localCookies = [userDefaults mpObjectForKey:kMPRemoteConfigCookiesKey userId:[MPPersistenceController mpId]];
    
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

- (NSString *)uniqueIdentifier {
    if (_uniqueIdentifier) {
        return _uniqueIdentifier;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
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

- (NSString *)deviceApplicationStamp {
    __block NSString *value = nil;
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    value = userDefaults[kMPDeviceApplicationStampStorageKey];
    
    if (!value) {
        [self.cookies enumerateObjectsUsingBlock:^(MPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cookie.name isEqualToString:@"uid"]) {
                NSString *content = cookie.content;
                NSString *dummyURL = [NSString stringWithFormat:@"https://example.com/?%@", content];
                NSArray *queryItems = [[NSURLComponents alloc] initWithString:dummyURL].queryItems;
                [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([item.name isEqualToString:@"g"]) {
                        value = item.value;
                    }
                }];
            }
        }];
        if (!value) {
            value = [NSUUID UUID].UUIDString;
        }
        userDefaults[kMPDeviceApplicationStampStorageKey] = value;
        [userDefaults synchronize];
    }
    
    return value;
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
}

@end
