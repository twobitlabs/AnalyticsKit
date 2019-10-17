//
//  MPAliasRequest.h
//

#import <Foundation/Foundation.h>
#import "MParticleUser.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A request to copy data from one user to another, constrained to a particular time period.
 
 Note that this request will not automatically copy user attributes to the destination user--this must be done manually, if desired.
 */
@interface MPAliasRequest : NSObject

/**
 Creates a request specifying a source and destination user.
 
 Alias start and end times will be automatically inferred based on the sourceUser's `firstSeen` and `lastSeen` properties.
 
 If the first/last seen dates are earlier than the supported alias max time window, they will be adjusted automatically.
 
 You can obtain user objects by indexing into the array returned by `[MParticle.sharedInstance.identity getAllUsers]` or by calling `[MParticle.sharedInstance.identity getUser:<MPID>]`.
 
 Note that when using the latter method the user IDs must be known to the SDK or the call to `getUser:` will return nil.
 */
+ (MPAliasRequest *)requestWithSourceUser:(MParticleUser *)sourceUser destinationUser:(MParticleUser *)destinationUser;

/**
 Creates a request specifying source and destination MPIDs and explicitly providing start and end times.
 
 (MPID is also referred to as the `userId` property on `MParticleUser`.)
 
 Unlike the above method, these dates will be sent to the server without adjusting them to take into account the alias max time window.
 
 You can register a listener to get any errors that may be returned if the start/end times are outside the range accepted by the server. See `MPListenerController#onAliasRequestFinished:`.
 
 Additionally, to support any potential advanced use cases, this method does not require MPIDs to be known to the SDK to perform the alias request.
 */
+ (MPAliasRequest *)requestWithSourceMPID:(NSNumber *)sourceMPID destinationMPID:(NSNumber *)destinationMPID startTime:(NSDate *)startTime endTime:(NSDate *)endTime;

/**
 The MPID of the user that has existing data.
 */
@property (nonatomic, strong, readonly) NSNumber *sourceMPID;

/**
 The MPID of the user that should receive the copied data.
 */
@property (nonatomic, strong, readonly) NSNumber *destinationMPID;

/**
 The timestamp of the earliest data that should be copied, defaults to the source user's first seen timestamp.
 */
@property (nonatomic, strong, readonly) NSDate *startTime;

/**
 The timestamp of the latest data that should be copied, defaults to the source user's last seen timestamp.
 */
@property (nonatomic, strong, readonly) NSDate *endTime;

/**
 Whether the start/end times were automatically inferred from the source user's firstSeen and lastSeen properties
 */
@property (nonatomic, assign, readonly) BOOL usedFirstLastSeen;

@end

NS_ASSUME_NONNULL_END
