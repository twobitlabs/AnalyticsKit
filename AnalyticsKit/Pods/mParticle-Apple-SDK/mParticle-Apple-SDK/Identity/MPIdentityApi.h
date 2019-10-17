//
//  MPIdentityApi.h
//


#import <Foundation/Foundation.h>
#import "MParticleUser.h"
#import "MPIdentityApiRequest.h"
#import "MPAliasRequest.h"
#import "MPAliasResponse.h"
#import "FilteredMParticleUser.h"
#import "FilteredMPIdentityApiRequest.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Result object for identify, login and logout calls. Specifies the new or existing user resolved by the IDSync servers based on the device and user identities passed in.
 
 Note that device identities (e.g. IDFA, push token) will be added to identity requests automatically by the SDK.
 */
@interface MPIdentityApiResult : NSObject

/**
 Resolved user as a result of the Identity API request.
 */
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *user;

/**
 User that was active before identity request was sent, if applicable.
 */
@property(nonatomic, strong, readwrite, nullable) MParticleUser *previousUser;

@end

/**
 An object representing a single identity type that was changed for a given user. Part of the modify response object.
 */
@interface MPIdentityChange : NSObject

/**
 The user whose identity changed.
 */
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *changedUser;

/**
 The type of the identity that changed. (e.g. email, customer id, etc)
 */
@property(nonatomic) MPUserIdentity changedIdentity;

@end

/**
 Modify result, contains a list of identity changes associated with the response.
 */
@interface MPModifyApiResult : MPIdentityApiResult

/**
 A list of objects describing which users and identity types were updated by the modify request.
 */
@property(nonatomic, strong, readwrite, nonnull) NSArray<MPIdentityChange *> *identityChanges;

@end

/**
 The callback signature for identify, login and logout.
 */
typedef void (^MPIdentityApiResultCallback)(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error);

/**
 Callback for modify requests.
 */
typedef void (^MPModifyApiResultCallback)(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error);

/**
 A set of APIs for representing users and user state changes e.g. login, logout, etc.
 */
@interface MPIdentityApi : NSObject

/**
 The current user. All actions taken in the SDK will be associated with this user (e.g. logging events, setting attributes, etc.)
 */
@property(nonatomic, strong, readonly, nullable) MParticleUser *currentUser;

/**
 The device application stamp. This is a random identifier associated with this particular app as installed on this particular device.
 
 The value persists throughout the lifetime of the app being installed, even if the user changes.
 */
@property(nonatomic, strong, readonly, nonnull) NSString *deviceApplicationStamp;

/**
 Returns the user with the given MPID, or nil if no such user is known to the SDK.
 */
- (nullable MParticleUser *)getUser:(NSNumber *)mpId;

/**
 Returns all users known to the SDK, ordered by last seen date.
 
 The ordering is going backwards in time such that the most recently seen user is at index 0.
 */
- (nonnull NSArray<MParticleUser *> *)getAllUsers;

/**
 Requests that the server return a MPID for the current set of device and user identities.
 
 This method is called automatically by the SDK on startup and typically should not be called manually.
 */
- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion;

/**
 Performs an identify request without explicitly specifying a request object.
 */
- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion;

/**
 Indicates that the user has logged in, usually transitioning from anonymous.
 
 The completion handler for this method is typically where you will send an alias request.
 */
- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion;

/**
 Performs a login request without explicitly specifying a request object.
 */
- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion;

/**
 Indicates that the current user has logged out.
 */
- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion;

/**
 Performs a logout request without explicitly specifying a request object.
 */
- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion;

/**
 This method should only be used in certain uncommon circumstances, e.g. if the user modifies their account to update their email address.
 */
- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPModifyApiResultCallback)completion;

/**
 Performs an alias request to copy data from one user to another for a particular time period.
 
 @returns Whether preliminary local validation of the request succeeded.
 */
- (BOOL)aliasUsers:(MPAliasRequest *)aliasRequest;

@end

/**
 An object returned when an identity request fails for some reason. Passed to handler for both client and server errors.
 */
@interface MPIdentityHTTPErrorResponse : NSObject

/**
 The http response code for errors returned by the server according to RFC 2616 Section 10.
 */
@property (nonatomic) NSInteger httpCode;

/**
 A custom error code enumeration providing a detailed reason why the request failed.
 */
@property (nonatomic, assign) MPIdentityErrorResponseCode code;

/**
 A human readable description of the error.
 */
@property (nonatomic, nullable) NSString *message;

/**
 The raw `NSError` object returned by the system networking frameworks, if applicable.
 */
@property (nonatomic, nullable) NSError *innerError;

@end

NS_ASSUME_NONNULL_END
