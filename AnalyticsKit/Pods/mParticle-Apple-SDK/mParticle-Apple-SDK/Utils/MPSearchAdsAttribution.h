#import <Foundation/Foundation.h>

@interface MPSearchAdsAttribution : NSObject

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted;

@end
