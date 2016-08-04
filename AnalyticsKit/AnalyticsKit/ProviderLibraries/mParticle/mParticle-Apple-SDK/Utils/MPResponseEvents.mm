//
//  MPResponseEvents.mm
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "NSUserDefaults+mParticle.h"
#import "MPSession.h"

@implementation MPResponseEvents

+ (void)parseConfiguration:(NSDictionary *)configuration session:(MPSession *)session {
    if (MPIsNull(configuration) || MPIsNull(configuration[kMPMessageTypeKey])) {
        return;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];

    // Consumer Information
    if (session) {
        MPConsumerInfo *consumerInfo = [MPStateMachine sharedInstance].consumerInfo;
        [consumerInfo updateWithConfiguration:configuration[kMPRemoteConfigConsumerInfoKey]];
        [persistence updateConsumerInfo:consumerInfo];
        [persistence fetchConsumerInfo:^(MPConsumerInfo *consumerInfo) {
            [MPStateMachine sharedInstance].consumerInfo = consumerInfo;
        }];
    }
    
    // LTV
    NSNumber *increasedLTV = !MPIsNull(configuration[kMPIncreasedLifeTimeValueKey]) ? configuration[kMPIncreasedLifeTimeValueKey] : nil;
    if (increasedLTV) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSNumber *ltv = userDefaults[kMPLifeTimeValueKey];
        
        if (ltv) {
            ltv = @([ltv doubleValue] + [increasedLTV doubleValue]);
        } else {
            ltv = increasedLTV;
        }
        
        userDefaults[kMPLifeTimeValueKey] = ltv;
    }
}

@end
