//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"

@implementation MPIdentityApiRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userIdentities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    if (!identityString || [identityString length] > 0) {
        if (!identityString) {
            identityString = (NSString *)[NSNull null];
        }
        
        [_userIdentities setObject:identityString forKey:@(identityType)];
    }
}

+ (MPIdentityApiRequest *)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *) user {
    MPIdentityApiRequest *request = [[self alloc] init];
    [user.userIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        MPUserIdentity identityType = [key intValue];
        [request setUserIdentity:obj identityType:identityType];
    }];

    return request;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *knownIdentities = [NSMutableDictionary dictionary];
    
    [_userIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
        MPUserIdentity identityType = [key intValue];
        switch (identityType) {
            case MPUserIdentityCustomerId:
                knownIdentities[@"customerid"] = obj;
                break;
                
            case MPUserIdentityEmail:
                knownIdentities[@"email"] = obj;
                break;
                
            case MPUserIdentityFacebook:
                knownIdentities[@"facebook"] = obj;
                break;
                
            case MPUserIdentityFacebookCustomAudienceId:
                knownIdentities[@"facebookcustomaudienceid"] = obj;
                break;
                
            case MPUserIdentityGoogle:
                knownIdentities[@"google"] = obj;
                break;
                
            case MPUserIdentityMicrosoft:
                knownIdentities[@"microsoft"] = obj;
                break;
                
            case MPUserIdentityOther:
                knownIdentities[@"other"] = obj;
                break;
                
            case MPUserIdentityOther2:
                knownIdentities[@"other2"] = obj;
                break;
                
            case MPUserIdentityOther3:
                knownIdentities[@"other3"] = obj;
                break;
                
            case MPUserIdentityOther4:
                knownIdentities[@"other4"] = obj;
                break;
                
            case MPUserIdentityTwitter:
                knownIdentities[@"twitter"] = obj;
                break;
                
            case MPUserIdentityYahoo:
                knownIdentities[@"yahoo"] = obj;
                break;
            default:
                break;
        }
    }];
    
    MPDevice *device = [[MPDevice alloc] init];
    
    NSString *advertiserId = device.advertiserId;
    if (advertiserId) {
        knownIdentities[@"ios_idfa"] = advertiserId;
    }
    
    NSString *vendorId = device.vendorId;
    if (vendorId) {
        knownIdentities[@"ios_idfv"] = vendorId;
    }
    
#if TARGET_OS_IOS == 1
#if !defined(MPARTICLE_APP_EXTENSIONS)
    NSString *deviceToken = [[NSString alloc] initWithData:[MPNotificationController deviceToken] encoding:NSUTF8StringEncoding];
    if (deviceToken && [deviceToken length] > 0) {
        knownIdentities[@"push_token"] = deviceToken;
    }
#endif
#endif
    
    return knownIdentities;
}

- (NSString *)email {
    return _userIdentities[@(MPUserIdentityEmail)];
}

- (void)setEmail:(NSString *)email {
    [self setUserIdentity:email identityType:MPUserIdentityEmail];
}

- (NSString *)customerId {
    return _userIdentities[@(MPUserIdentityCustomerId)];
}

- (void)setCustomerId:(NSString *)customerId {
    [self setUserIdentity:customerId identityType:MPUserIdentityCustomerId];
}

@end
