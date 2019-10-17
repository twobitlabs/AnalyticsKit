#import "FilteredMParticleUser.h"
#import "mParticle.h"
#import "MParticleUser.h"
#import "MPKitConfiguration.h"
#import "MPIHasher.h"

@interface FilteredMParticleUser ()

@property (nonatomic, strong) MParticleUser *user;

@property (nonatomic, strong) MPKitConfiguration *kitConfiguration;

@end

@implementation FilteredMParticleUser

- (instancetype)initWithMParticleUser:(MParticleUser *)user kitConfiguration:(MPKitConfiguration *)kitConfiguration {
    self = [super init];
    if (self) {
        _user = user;
        _kitConfiguration = kitConfiguration;
    }

    return self;
}

-(NSNumber *)userId {
    return self.user.userId;
}

-(BOOL)isLoggedIn {
    return self.user.isLoggedIn;
}

-(NSDictionary<NSNumber *, NSString *> *) userIdentities {
    NSDictionary<NSNumber *, NSString *> *unfilteredUserIdentities = self.user.userIdentities;
    NSMutableDictionary *userIdentities = [NSMutableDictionary dictionary];
    
    for (NSNumber* key in unfilteredUserIdentities) {
        id value = [unfilteredUserIdentities objectForKey:key];
        BOOL shouldFilter = NO;
        
        if (self.kitConfiguration) {
            NSString *identityTypeString = [key stringValue];
            shouldFilter = self.kitConfiguration.userIdentityFilters[identityTypeString] && [self.kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        }
        
        if (!shouldFilter) {
            [userIdentities setObject:value forKey:key];
        }
    }
    
    return userIdentities;
}

-(NSDictionary<NSString *, id> *) userAttributes {
    NSDictionary<NSString *, id> *unfilteredUserAttributes = self.user.userAttributes;
    NSMutableDictionary *userAttributes = [NSMutableDictionary dictionary];
    
    for (NSString* key in unfilteredUserAttributes) {
        id value = [unfilteredUserAttributes objectForKey:key];
        NSString *hashKey = [MPIHasher hashString:[key lowercaseString]];
        BOOL shouldFilter = NO;
        
        if (self.kitConfiguration) {
            shouldFilter = self.kitConfiguration.userAttributeFilters[hashKey] && [self.kitConfiguration.userAttributeFilters[hashKey] isEqualToNumber:@0];
        }
        
        if (!shouldFilter) {
            [userAttributes setObject:value forKey:key];
        }
    }
    
    return userAttributes;
}

@end
