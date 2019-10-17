//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"

@interface MPIdentityApiRequest ()
@property (nonatomic) NSMutableDictionary *mutableUserIdentities;
@end

@implementation MPIdentityApiRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableUserIdentities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    if (MPIsNull(identityString)) {
        [_mutableUserIdentities setObject:(NSString *)[NSNull null]
                            forKey:@(identityType)];
    } else if ([identityString length] > 0) {
        [_mutableUserIdentities setObject:identityString
                            forKey:@(identityType)];
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
    
    [_mutableUserIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
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
    if (![MPStateMachine isAppExtension]) {
        NSString *deviceToken = [[NSString alloc] initWithData:[MPNotificationController deviceToken] encoding:NSUTF8StringEncoding];
        if (deviceToken && [deviceToken length] > 0) {
            knownIdentities[@"push_token"] = deviceToken;
        }
    }
#endif
    
    return knownIdentities;
}

- (NSString *)email {
    return _mutableUserIdentities[@(MPUserIdentityEmail)];
}

- (void)setEmail:(NSString *)email {
    [self setUserIdentity:email identityType:MPUserIdentityEmail];
}

- (NSString *)customerId {
    return _mutableUserIdentities[@(MPUserIdentityCustomerId)];
}

- (void)setCustomerId:(NSString *)customerId {
    [self setUserIdentity:customerId identityType:MPUserIdentityCustomerId];
}

- (NSDictionary *)userIdentities {
    return [_mutableUserIdentities copy];
}

@end
