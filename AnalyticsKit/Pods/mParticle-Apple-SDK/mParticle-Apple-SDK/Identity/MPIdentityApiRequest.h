//
//  MPIdentityApiRequest.h
//

#import <Foundation/Foundation.h>
#import "MParticleUser.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Main identity request object, used to resolve a set of user identities to a resulting MPID.
 
 (Device identities are also taken into account and will be added automatically by the SDK.)
 */
@interface MPIdentityApiRequest : NSObject

+ (MPIdentityApiRequest *)requestWithEmptyUser;
+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *) user;

- (void)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;

@property (nonatomic, strong, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSString *customerId;
@property (nonatomic, strong, nullable, readonly) NSDictionary *userIdentities;
@property (nonatomic, copy, nullable) void (^onUserAlias)(MParticleUser *previousUser, MParticleUser *newUser) __attribute__((deprecated("Use mParticleIdentityStateChangeListenerNotification")));

@end

NS_ASSUME_NONNULL_END
