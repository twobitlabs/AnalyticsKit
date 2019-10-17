#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"
#include "MPHasher.h"
#import "MParticle.h"
#import "MPBackendController.h"
#import "MPApplication.h"
#import "MPStateMachine.h"

@interface MPNotificationController() {
}

@end

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

#if TARGET_OS_IOS == 1
static NSData *deviceToken = nil;
#endif

@implementation MPNotificationController

#if TARGET_OS_IOS == 1

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    return self;
}

#pragma mark Public static methods
+ (NSData *)deviceToken {
#ifndef MP_UNIT_TESTING
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    deviceToken = userDefaults[kMPDeviceTokenKey];
#else
    deviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif
    
    return deviceToken;
}

+ (void)setDeviceToken:(NSData *)devToken {
    if ([MPNotificationController deviceToken] && [[MPNotificationController deviceToken] isEqualToData:devToken]) {
        return;
    }
    
    NSData *newDeviceToken = [devToken copy];
    NSData *oldDeviceToken = [deviceToken copy];
    
    deviceToken = devToken;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *deviceTokenDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSString *newTokenString = nil;
        NSString *oldTokenString = nil;
        if (newDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationDeviceTokenKey] = newDeviceToken;
            newTokenString = [MPIUserDefaults stringFromDeviceToken:newDeviceToken];
        }
        
        if (oldDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationOldDeviceTokenKey] = oldDeviceToken;
            oldTokenString = [[NSString alloc] initWithData:oldDeviceToken encoding:NSUTF8StringEncoding];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationDeviceTokenNotification
                                                            object:nil
                                                          userInfo:deviceTokenDictionary];
        
        if (oldTokenString && newTokenString) {
            [[MParticle sharedInstance].backendController.networkCommunication modifyDeviceID:@"push_token"
                                                                                        value:newTokenString
                                                                                     oldValue:oldTokenString];
        }
        
#ifndef MP_UNIT_TESTING
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        userDefaults[kMPDeviceTokenKey] = deviceToken;
        [userDefaults synchronize];
#endif
    });
}

#endif

@end
