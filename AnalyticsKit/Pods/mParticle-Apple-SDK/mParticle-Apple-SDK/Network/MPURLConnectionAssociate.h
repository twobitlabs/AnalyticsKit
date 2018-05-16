#import <Foundation/Foundation.h>

@class MPNetworkPerformance;

@interface MPURLConnectionAssociate : NSObject

@property (nonatomic, strong) id delegate;
@property (nonatomic, strong) MPNetworkPerformance *networkPerformance;

@end
