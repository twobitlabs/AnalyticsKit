//
//  MPIdentityApiManager.h
//

#import <Foundation/Foundation.h>
#import "MPIdentityApiRequest.h"
#import "MPIdentityDTO.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);

@interface MPIdentityApiManager : NSObject

- (void)identify:(nullable MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)loginRequest:(nullable MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(nullable MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;

@end

NS_ASSUME_NONNULL_END
