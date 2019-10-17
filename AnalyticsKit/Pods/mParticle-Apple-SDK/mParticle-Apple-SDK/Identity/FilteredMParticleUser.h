//
//  FilteredMParticleUser.h
//

#import <Foundation/Foundation.h>
#import "MPCart.h"

@class MParticleUser;
@class MPKitConfiguration;

@interface FilteredMParticleUser : NSObject

@property(readonly, strong, nonnull) NSNumber *userId;

/**
 Returns whether this user is currently logged in
 */
@property(readonly) BOOL isLoggedIn;

/**
 Gets current user identities (readonly)
 @returns A dictionary containing the collection of user identities
 @see MPUserIdentity
 */
@property (readonly, strong, nonnull) NSDictionary<NSNumber *, NSString *> *userIdentities;

/**
 Gets all user attributes.
 @returns A dictionary containing the collection of user attributes.
 */
@property (readonly, strong, nonnull) NSDictionary<NSString *, id> *userAttributes;

- (instancetype _Nonnull )initWithMParticleUser:(MParticleUser *_Nonnull)user kitConfiguration:(MPKitConfiguration *_Nonnull)kitConfiguration;

@end
