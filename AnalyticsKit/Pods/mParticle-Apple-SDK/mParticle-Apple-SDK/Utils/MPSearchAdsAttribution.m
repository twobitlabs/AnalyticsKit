#import "MPSearchAdsAttribution.h"
#import "mParticle.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"

#if TARGET_OS_IOS == 1
#import <iAd/ADClient.h>
#endif

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@implementation MPSearchAdsAttribution

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted {
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3
    if (![MPStateMachine isAppExtension]) {
        Class MPClientClass = NSClassFromString(@"ADClient");
        if (!MPClientClass) {
            completionHandler();
            return;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL sharedClientSelector = NSSelectorFromString(@"sharedClient");
        if (![MPClientClass respondsToSelector:sharedClientSelector]) {
            completionHandler();
            return;
        }
        
        id MPClientSharedInstance = [MPClientClass performSelector:sharedClientSelector];
        if (!MPClientSharedInstance) {
            completionHandler();
            return;
        }
        
        SEL requestDetailsSelector = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");
        if (![MPClientSharedInstance respondsToSelector:requestDetailsSelector]) {
            completionHandler();
            return;
        }
        
        [MPClientSharedInstance performSelector:requestDetailsSelector withObject:^(NSDictionary *attributionDetails, NSError *error) {
            dispatch_async([MParticle messageQueue], ^{
                
                if (attributionDetails && !error) {
                    [MParticle sharedInstance].stateMachine.searchAdsInfo = [[attributionDetails mutableCopy] copy];
                    completionHandler();
                }
                else if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                    completionHandler();
                }
                else if ((requestsCompleted + 1) > SEARCH_ADS_ATTRIBUTION_MAX_RETRIES) {
                    completionHandler();
                } else {
                    // Per Apple docs, "Handle any errors you receive and re-poll for data, if required"
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self requestAttributionDetailsWithBlock:completionHandler requestsCompleted:(requestsCompleted + 1)];
                    });
                }
            });
        }];
#pragma clang diagnostic pop
    } else {
        completionHandler();
    }
#else
    completionHandler();
#endif
}

@end
