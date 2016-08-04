//
//  MPMessageBuilder.m
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

#import "MPMessageBuilder.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPStateMachine.h"
#import "MPStandaloneMessage.h"
#import "MPDateFormatter.h"
#import <UIKit/UIKit.h>
#import "MPMediaTrack.h"
#import "MPEnums.h"
#import "MediaControl.h"
#import "MPCurrentState.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPILogger.h"
#import "NSDictionary+MPCaseInsensitive.h"
#include "MessageTypeName.h"
#import "MPLocationManager.h"

NSString *const launchInfoStringFormat = @"%@%@%@=%@";
NSString *const kMPHorizontalAccuracyKey = @"acc";
NSString *const kMPLatitudeKey = @"lat";
NSString *const kMPLongitudeKey = @"lng";
NSString *const kMPVerticalAccuracyKey = @"vacc";
NSString *const kMPRequestedAccuracy = @"racc";
NSString *const kMPDistanceFilter = @"mdst";
NSString *const kMPIsForegroung = @"fg";

@implementation MPMessageBuilder

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session {
    self = [super init];
    if (!self || !messageType) {
        return nil;
    }
    
    uuid = nil;
    _timestamp = [[NSDate date] timeIntervalSince1970];
    messageDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    messageDictionary[kMPTimestampKey] = MPMilliseconds(_timestamp);
    
    messageTypeValue = messageType;
    _messageType = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(static_cast<mParticle::MessageType>(messageType)).c_str() encoding:NSUTF8StringEncoding];
    
    _session = session;
    if (session) {
        if (messageType == MPMessageTypeSessionStart) {
            uuid = _session.uuid;
        } else {
            messageDictionary[kMPSessionIdKey] = _session.uuid;
            messageDictionary[kMPSessionStartTimestamp] = MPMilliseconds(_session.startTime);
            
            if (messageType == MPMessageTypeBreadcrumb) {
                messageDictionary[kMPSessionNumberKey] = _session.sessionNumber;
            }
        }
    }
    
    NSString *presentedViewControllerDescription = nil;
    NSNumber *mainThreadFlag;
    if ([NSThread isMainThread]) {
        UIViewController *presentedViewController = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
        presentedViewControllerDescription = presentedViewController ? [[presentedViewController class] description] : nil;
        mainThreadFlag = @YES;
    } else {
        presentedViewControllerDescription = @"off_thread";
        mainThreadFlag = @NO;
    }
    
    if (presentedViewControllerDescription) {
        messageDictionary[kMPPresentedViewControllerKey] = presentedViewControllerDescription;
    }
    messageDictionary[kMPMainThreadKey] = mainThreadFlag;
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session commerceEvent:(MPCommerceEvent *)commerceEvent {
    self = [self initWithMessageType:messageType session:session];
    if (self) {
        NSDictionary *commerceEventDictionary = [commerceEvent dictionaryRepresentation];
        if (commerceEventDictionary) {
            [messageDictionary addEntriesFromDictionary:commerceEventDictionary];
            
            NSDictionary *messageAttributes = messageDictionary[kMPAttributesKey];
            if (messageAttributes) {
                messageDictionary[kMPAttributesKey] = [messageAttributes transformValuesToString];
            }
        }
    }
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary<NSString *, id> *)messageInfo {
    self = [self initWithMessageType:messageType session:session];
    if (self) {
        if (messageInfo) {
            [messageDictionary addEntriesFromDictionary:messageInfo];
            
            NSDictionary *messageAttributes = messageDictionary[kMPAttributesKey];
            if (messageAttributes) {
                messageDictionary[kMPAttributesKey] = [messageAttributes transformValuesToString];
            }
        }
    }

    return self;
}

#pragma mark Private methods
- (BOOL)shouldBuildMessage {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    BOOL shouldBuildMessage = !stateMachine.optOut || messageTypeValue == MPMessageTypeOptOut;
    return shouldBuildMessage;
}

#pragma mark Public class methods
+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session commerceEvent:(MPCommerceEvent *)commerceEvent {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session commerceEvent:commerceEvent];
    return messageBuilder;
}

+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary<NSString *, id> *)messageInfo {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session messageInfo:messageInfo];
    return messageBuilder;
}

+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session mediaTrack:(MPMediaTrack *)mediaTrack mediaAction:(MPMediaAction)mediaAction {
    if (!mediaTrack) {
        return nil;
    }
    
    mParticle::MediaActionDescription actionDescription = mParticle::MediaControl::actionDescriptionForMediaAction(static_cast<mParticle::MediaAction>(mediaAction));
    
    NSDictionary *messageInfo = [mediaTrack dictionaryRepresentationWithEventName:[NSString stringWithCString:actionDescription.name.c_str() encoding:NSUTF8StringEncoding]
                                                                           action:[NSString stringWithCString:actionDescription.action.c_str() encoding:NSUTF8StringEncoding]];

    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session messageInfo:messageInfo];
    
    return messageBuilder;
}

#pragma mark Public instance methods
- (NSDictionary *)messageInfo {
    return messageDictionary;
}

- (MPMessageBuilder *)withLaunchInfo:(NSDictionary *)launchInfo {
    NSString *launchScheme = [launchInfo[UIApplicationLaunchOptionsURLKey] absoluteString];
    NSString *launchSource = launchInfo[UIApplicationLaunchOptionsSourceApplicationKey];
    
    if (launchScheme && launchSource) {
        NSRange range = [launchScheme rangeOfString:@"?"];
        NSString *sourcePrefix = (range.length > 0) ? @"&" : @"?";
        
        NSString *launchInfoString = [NSString stringWithFormat:launchInfoStringFormat, launchScheme, sourcePrefix, kMPLaunchSourceKey, launchSource];
        messageDictionary[kMPLaunchURLKey] = launchInfoString;
    }
    
    return self;
}

- (MPMessageBuilder *)withTimestamp:(NSTimeInterval)timestamp {
    _timestamp = timestamp;
    messageDictionary[kMPTimestampKey] = MPMilliseconds(_timestamp);
    
    return self;
}

- (MPMessageBuilder *)withStateTransition:(BOOL)sessionFinalized previousSession:(MPSession *)previousSession {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (stateMachine.launchInfo.sourceApplication) {
        messageDictionary[kMPLaunchSourceKey] = stateMachine.launchInfo.sourceApplication;
    }
    
    if (stateMachine.launchInfo.url) {
        messageDictionary[kMPLaunchURLKey] = [stateMachine.launchInfo.url absoluteString];
    }
    
    if (stateMachine.launchInfo.annotation) {
        messageDictionary[kMPLaunchParametersKey] = stateMachine.launchInfo.annotation;
    }
    
    messageDictionary[kMPLaunchNumberOfSessionInterruptionsKey] = previousSession ? @(previousSession.numberOfInterruptions) : @0;
    messageDictionary[kMPLaunchSessionFinalizedKey] = @(sessionFinalized);

    return self;
}

- (MPDataModelAbstract *)build {
    MPDataModelAbstract *message = nil;
    
    MPCurrentState *currentState = [[MPCurrentState alloc] init];
    messageDictionary[kMPStateInformationKey] = [currentState dictionaryRepresentation];
    
    messageDictionary[kMPMessageTypeKey] = _messageType;
    messageDictionary[kMPMessageIdKey] = uuid ? uuid : [[NSUUID UUID] UUIDString];

    if (_session) {
        message = [[MPMessage alloc] initWithSession:_session
                                         messageType:_messageType
                                         messageInfo:messageDictionary
                                        uploadStatus:MPUploadStatusBatch
                                                UUID:messageDictionary[kMPMessageIdKey]
                                           timestamp:_timestamp];
    } else {
        message = [[MPStandaloneMessage alloc] initWithMessageType:_messageType
                                                       messageInfo:messageDictionary
                                                      uploadStatus:MPUploadStatusBatch
                                                              UUID:messageDictionary[kMPMessageIdKey]
                                                         timestamp:_timestamp];
    }
    
    return message;
}

#if TARGET_OS_IOS == 1
- (MPMessageBuilder *)withLocation:(CLLocation *)location {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if ([MPStateMachine runningInBackground] && !stateMachine.locationManager.backgroundLocationTracking) {
        return self;
    }
    
    BOOL isCrashReport = messageTypeValue == MPMessageTypeCrashReport;
    BOOL isOptOutMessage = messageTypeValue == MPMessageTypeOptOut;
    
    if (location && [CLLocationManager authorizationStatus] && [CLLocationManager locationServicesEnabled] && !isCrashReport && !isOptOutMessage) {
        messageDictionary[kMPLocationKey] = @{kMPHorizontalAccuracyKey:@(location.horizontalAccuracy),
                                              kMPVerticalAccuracyKey:@(location.verticalAccuracy),
                                              kMPLatitudeKey:@(location.coordinate.latitude),
                                              kMPLongitudeKey:@(location.coordinate.longitude),
                                              kMPRequestedAccuracy:@(stateMachine.locationManager.requestedAccuracy),
                                              kMPDistanceFilter:@(stateMachine.locationManager.requestedDistanceFilter),
                                              kMPIsForegroung:@(!stateMachine.backgrounded)};
    }
    
    return self;
}
#endif

@end
