#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MPSurrogateAppDelegate;

#if TARGET_OS_IOS == 1
@class MPNotificationController;
#endif

@interface MPAppDelegateProxy : NSProxy <UIApplicationDelegate>

@property (nonatomic, strong) id originalAppDelegate;
@property (nonatomic, strong) MPSurrogateAppDelegate *surrogateAppDelegate;

- (instancetype)initWithOriginalAppDelegate:(id)originalAppDelegate;

@end
