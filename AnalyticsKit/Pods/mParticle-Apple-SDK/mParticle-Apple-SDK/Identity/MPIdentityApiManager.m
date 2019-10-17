//
//  MPIdentityApiManager.m
//

#import "MPIdentityApiManager.h"
#import "MPConnector.h"
#import "MPIConstants.h"
#import "MPNetworkCommunication.h"
#import "MPBackendController.h"
#import "mParticle.h"
#import "MPListenerController.h"

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end


@interface MPIdentityApiManager ()

@property (nonatomic, strong) NSString *context;

@end

@implementation MPIdentityApiManager

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:identifyRequest parameter2:completion];
    
    [[MParticle sharedInstance].backendController.networkCommunication identify:identifyRequest completion:^(MPIdentityHTTPBaseSuccessResponse *
       _Nonnull httpResponse, NSError * _Nullable error) {
                   completion(httpResponse, error);
     }];
}

- (void)loginRequest:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:loginRequest parameter2:completion];
    
    [[MParticle sharedInstance].backendController.networkCommunication login:loginRequest completion:^(MPIdentityHTTPBaseSuccessResponse *
                                                                                                             _Nonnull httpResponse, NSError * _Nullable error) {
        completion(httpResponse, error);
    }];
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:logoutRequest parameter2:completion];
    
    [[MParticle sharedInstance].backendController.networkCommunication logout:logoutRequest completion:^(MPIdentityHTTPBaseSuccessResponse *
                                                                                                             _Nonnull httpResponse, NSError * _Nullable error) {
        completion(httpResponse, error);
    }];
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:modifyRequest parameter2:completion];
    
    [[MParticle sharedInstance].backendController.networkCommunication modify:modifyRequest completion:^(MPIdentityHTTPModifySuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        completion(httpResponse, error);
    }];
}

@end
