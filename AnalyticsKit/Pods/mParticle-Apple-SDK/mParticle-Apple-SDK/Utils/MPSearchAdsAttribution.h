#import <Foundation/Foundation.h>

@interface MPSearchAdsAttribution : NSObject

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler;
- (nullable NSDictionary *)dictionaryRepresentation;

@end
