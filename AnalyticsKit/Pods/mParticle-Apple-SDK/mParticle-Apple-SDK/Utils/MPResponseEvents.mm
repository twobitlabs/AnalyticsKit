#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPSession.h"
#import "MParticle.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@implementation MPResponseEvents

+ (void)parseConfiguration:(nonnull NSDictionary *)configuration {
    if (MPIsNull(configuration) || MPIsNull(configuration[kMPMessageTypeKey])) {
        return;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;

    // Consumer Information
    MPConsumerInfo *consumerInfo = [MParticle sharedInstance].stateMachine.consumerInfo;
    [consumerInfo updateWithConfiguration:configuration[kMPRemoteConfigConsumerInfoKey]];
    [persistence updateConsumerInfo:consumerInfo];
    MPConsumerInfo *persistenceInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    if (persistenceInfo.cookies != nil) {
        [MParticle sharedInstance].stateMachine.consumerInfo.cookies = persistenceInfo.cookies;
    }
}

@end
