#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPSession.h"

@implementation MPResponseEvents

+ (void)parseConfiguration:(nonnull NSDictionary *)configuration {
    if (MPIsNull(configuration) || MPIsNull(configuration[kMPMessageTypeKey])) {
        return;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];

    // Consumer Information
    MPConsumerInfo *consumerInfo = [MPStateMachine sharedInstance].consumerInfo;
    [consumerInfo updateWithConfiguration:configuration[kMPRemoteConfigConsumerInfoKey]];
    [persistence updateConsumerInfo:consumerInfo];
    MPConsumerInfo *persistenceInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    if (persistenceInfo.cookies != nil) {
        [MPStateMachine sharedInstance].consumerInfo.cookies = persistenceInfo.cookies;
    }
}

@end
