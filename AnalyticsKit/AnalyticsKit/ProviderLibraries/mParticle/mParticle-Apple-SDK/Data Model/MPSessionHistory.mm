//
//  MPSessionHistory.mm
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

#import "MPSessionHistory.h"
#import "MPApplication.h"
#import "MPDevice.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#import "MPSession.h"
#import "MPConsumerInfo.h"
#include <vector>
#import "MPIConstants.h"

using namespace std;

@interface MPSessionHistory() {
    vector<NSDictionary *> sessionMessages;
}

@end

@implementation MPSessionHistory

- (instancetype)init {
    id invalidParameter = nil;
    return [self initWithSession:invalidParameter uploads:invalidParameter];
}

- (instancetype)initWithSession:(MPSession *)session uploads:(NSArray<MPUpload *> *)uploads {
    self = [super init];
    if (!self || !session || !uploads) {
        return nil;
    }
    
    _session = session;
    self.uploads = uploads;

    return self;
}

#pragma mark MPDataModelProtocol
- (NSDictionary *)dictionaryRepresentation {
    MPApplication *application = [[MPApplication alloc] init];
    MPDevice *device = [[MPDevice alloc] init];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSMutableDictionary *sessionHistoryDictionary = [@{kMPMessageTypeKey:kMPMessageTypeRequestHeader,
                                                       kMPTimestampKey:MPCurrentEpochInMilliseconds,
                                                       kMPmParticleSDKVersionKey:kMParticleSDKVersion,
                                                       kMPDeviceInformationKey:[device dictionaryRepresentation],
                                                       kMPApplicationInformationKey:[application dictionaryRepresentation],
                                                       kMPApplicationKey:stateMachine.apiKey,
                                                       kMPSessionIdKey:_session.uuid}
                                                     mutableCopy];
    
    if (!sessionMessages.empty()) {
        sessionHistoryDictionary[kMPSessionHistoryValue] = [NSArray arrayWithObjects:&sessionMessages[0] count:sessionMessages.size()];
    }
    
    if (_userAttributes.count > 0) {
        sessionHistoryDictionary[kMPUserAttributeKey] = _userAttributes;
    }
    
    if (_userIdentities.count > 0) {
        sessionHistoryDictionary[kMPUserIdentityArrayKey] = _userIdentities;
    }
    
    NSDictionary *cookies = [stateMachine.consumerInfo cookiesDictionaryRepresentation];
    if (cookies) {
        sessionHistoryDictionary[kMPRemoteConfigCookiesKey] = cookies;
    }
    
    return (NSDictionary *)sessionHistoryDictionary;
}

- (NSString *)serializedString {
    NSData *sessionHistoryData = [NSJSONSerialization dataWithJSONObject:[self dictionaryRepresentation] options:0 error:nil];
    NSString *serializedString = [[NSString alloc] initWithData:sessionHistoryData encoding:NSUTF8StringEncoding];
    return serializedString;
}

#pragma mark Public accessors
- (void)setUploads:(NSArray<MPUpload *> *)uploads {
    if (MPIsNull(uploads) || uploads.count == 0) {
        _uploads = nil;
        _uploadIds = nil;
        sessionMessages.clear();
        return;
    }
    
    _uploads = uploads;
    vector<NSNumber *> uploadIdsVector;
    
    for (MPUpload *upload in uploads) {
        uploadIdsVector.push_back(@(upload.uploadId));
        
        NSDictionary *uploadDictionary = [upload dictionaryRepresentation];
        NSArray *messagesArray = uploadDictionary[kMPMessagesKey];
        
        for (NSDictionary *coreMessageDictionary in messagesArray) {
            sessionMessages.push_back(coreMessageDictionary);
        }
    }
    
    if (!uploadIdsVector.empty()) {
        _uploadIds = [NSArray arrayWithObjects:&uploadIdsVector[0] count:uploadIdsVector.size()];
    }
}

@end
