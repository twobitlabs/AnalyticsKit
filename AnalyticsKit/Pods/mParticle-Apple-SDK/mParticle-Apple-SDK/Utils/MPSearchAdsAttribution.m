#import "MPSearchAdsAttribution.h"
#import "mParticle.h"

#if TARGET_OS_IOS == 1
    #import <iAd/ADClient.h>
#endif

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@end

@interface MPSearchAdsAttribution () {
    dispatch_queue_t messageQueue;
}

@property (nonatomic) NSDictionary *dictionary;

@end

@implementation MPSearchAdsAttribution

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dictionary = nil;
        messageQueue = [MParticle messageQueue];
    }
    return self;
}

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler {
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3 && !defined(MPARTICLE_APP_EXTENSIONS)
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
    
    __block BOOL called = NO;
    void(^onceCompletionBlock)(void) = ^(){
        if (!called) {
            called = YES;
            dispatch_async(self->messageQueue, ^{
                completionHandler();
            });
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        onceCompletionBlock();
    });
    
    __weak MPSearchAdsAttribution *weakSelf = self;
    int numRequests = 4;
    __block int numRequestsCompleted = 0;
    
    void (^requestBlock)(void) = ^{
        if (!called) {
            [MPClientSharedInstance performSelector:requestDetailsSelector withObject:^(NSDictionary *attributionDetails, NSError *error) {
                ++numRequestsCompleted;
                
                __strong MPSearchAdsAttribution *strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }

                if (!strongSelf.dictionary && attributionDetails && !error) {
                    NSDictionary* deepCopyDetails = nil;
                    @try {
                        deepCopyDetails = [NSKeyedUnarchiver unarchiveObjectWithData:
                                                         [NSKeyedArchiver archivedDataWithRootObject:attributionDetails]];
                    }
                    @catch (NSException *e) {
                        deepCopyDetails = [attributionDetails copy];
                    }

                    if (deepCopyDetails) {
                        strongSelf.dictionary = deepCopyDetails;
                    }
                    
                    onceCompletionBlock();
                }
                else if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                    onceCompletionBlock();
                }
                else if (numRequestsCompleted >= numRequests) {
                    onceCompletionBlock();
                }
            }];
        }
    };
    
    // Per Apple docs, "Handle any errors you receive and re-poll for data, if required"
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    
#pragma clang diagnostic pop
#else
    completionHandler();
#endif
}

- (nullable NSDictionary *)dictionaryRepresentation {
    return self.dictionary;
}

@end
