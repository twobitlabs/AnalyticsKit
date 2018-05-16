//
//  FilteredMPIdentityApiRequest.m
//

#import "FilteredMPIdentityApiRequest.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MParticleUser.h"
#import "MPKitConfiguration.h"
#import "MPIdentityApiRequest.h"

@interface FilteredMPIdentityApiRequest ()

@property (nonatomic, strong) MPIdentityApiRequest *request;

@property (nonatomic, strong) MPKitConfiguration *kitConfiguration;

@end

@implementation FilteredMPIdentityApiRequest

- (instancetype)initWithIdentityRequest:(MPIdentityApiRequest *)request kitConfiguration:(MPKitConfiguration *)kitConfiguration {
    self = [super init];
    if (self) {
        _kitConfiguration = kitConfiguration;
        _request = request;
    }
    return self;
}

- (NSDictionary<NSNumber *,NSString *> *)userIdentities {
    NSDictionary<NSNumber *, NSString *> *unfilteredUserIdentities = self.request.userIdentities;
    NSMutableDictionary *filteredUserIdentities = [NSMutableDictionary dictionary];
    
    for (NSNumber* key in unfilteredUserIdentities) {
        id value = [unfilteredUserIdentities objectForKey:key];
        BOOL shouldFilter = NO;
        
        if (self.kitConfiguration) {
            NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", key.unsignedLongValue];
            shouldFilter = self.kitConfiguration.userIdentityFilters[identityTypeString] && [self.kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        }
        
        if (!shouldFilter) {
            [filteredUserIdentities setObject:value forKey:key];
        }
    }
    
    return filteredUserIdentities;
}

- (NSString *)email {
    return self.userIdentities[@(MPUserIdentityEmail)];
}

- (NSString *)customerId {
    return self.userIdentities[@(MPUserIdentityCustomerId)];
}

@end
