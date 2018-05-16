#import "MPMessageBuilder.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPStateMachine.h"
#import "MPDateFormatter.h"
#import <UIKit/UIKit.h>
#import "MPEnums.h"
#import "MPCurrentState.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPILogger.h"
#import "NSDictionary+MPCaseInsensitive.h"
#include "MessageTypeName.h"
#import "MPLocationManager.h"
#import "MPUserAttributeChange.h"
#import "MPUserIdentityChange.h"
#import "MPPersistenceController.h"

NSString *const launchInfoStringFormat = @"%@%@%@=%@";
NSString *const kMPHorizontalAccuracyKey = @"acc";
NSString *const kMPLatitudeKey = @"lat";
NSString *const kMPLongitudeKey = @"lng";
NSString *const kMPVerticalAccuracyKey = @"vacc";
NSString *const kMPRequestedAccuracy = @"racc";
NSString *const kMPDistanceFilter = @"mdst";
NSString *const kMPIsForegroung = @"fg";
NSString *const kMPUserAttributeWasDeletedKey = @"d";
NSString *const kMPUserAttributeNewValueKey = @"nv";
NSString *const kMPUserAttributeOldValueKey = @"ov";
NSString *const kMPUserAttributeNewlyAddedKey = @"na";
NSString *const kMPUserIdentityNewValueKey = @"ni";
NSString *const kMPUserIdentityOldValueKey = @"oi";

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
            
            if (messageType == MPMessageTypeSessionEnd) {
                NSArray *userIds = [_session.sessionUserIds componentsSeparatedByString:@","];
                
                NSMutableArray *userIdNumbers = [NSMutableArray array];
                [userIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSNumber *userId = @(obj.longLongValue);
                    if (userId && ![userId isEqual:@0]) {
                        [userIdNumbers addObject:userId];
                    }
                    
                }];
                
                if (userIdNumbers) {
                    messageDictionary[kMPSessionUserIdsKey] = userIdNumbers;
                }
            }
        }
    }
    
    NSString *presentedViewControllerDescription = nil;
    NSNumber *mainThreadFlag;
    if ([NSThread isMainThread]) {
#if !defined(MPARTICLE_APP_EXTENSIONS)
        UIViewController *presentedViewController = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
        presentedViewControllerDescription = presentedViewController ? [[presentedViewController class] description] : nil;
#else
        presentedViewControllerDescription = @"extension_message";
#endif
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

- (MPMessageBuilder *)withCurrentState {
    MPCurrentState *currentState = [[MPCurrentState alloc] init];
    messageDictionary[kMPStateInformationKey] = [currentState dictionaryRepresentation];
    
    return self;
}

- (MPMessageBuilder *)withUserAttributeChange:(nonnull MPUserAttributeChange *)userAttributeChange {
    messageDictionary[kMPUserAttributeWasDeletedKey] = userAttributeChange.deleted ? @YES : @NO;
    messageDictionary[kMPEventNameKey] = userAttributeChange.key;
    
    id oldValue = userAttributeChange.userAttributes[userAttributeChange.key];
    messageDictionary[kMPUserAttributeOldValueKey] = oldValue ? oldValue : [NSNull null];
    messageDictionary[kMPUserAttributeNewValueKey] = userAttributeChange.valueToLog && !userAttributeChange.deleted ? userAttributeChange.valueToLog : [NSNull null];
    messageDictionary[kMPUserAttributeNewlyAddedKey] = oldValue ? @NO : @YES;
    
    return self;
}

- (MPMessageBuilder *)withUserIdentityChange:(MPUserIdentityChange *)userIdentityChange {
    NSDictionary *dictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
    if (dictionary) {
        messageDictionary[kMPUserIdentityNewValueKey] = dictionary;
    }
    
    dictionary = [userIdentityChange.userIdentityOld dictionaryRepresentation];
    if (dictionary) {
        messageDictionary[kMPUserIdentityOldValueKey] = dictionary;
    }
    
    return self;
}


#pragma mark Public class methods
+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session commerceEvent:(MPCommerceEvent *)commerceEvent {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session commerceEvent:commerceEvent];
    [messageBuilder withCurrentState];
    return messageBuilder;
}

+ (nonnull MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(nonnull MPSession *)session userIdentityChange:(nonnull MPUserIdentityChange *)userIdentityChange {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session];
    [messageBuilder withUserIdentityChange:userIdentityChange];
    
    return messageBuilder;
}

+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary<NSString *, id> *)messageInfo {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session messageInfo:messageInfo];
    [messageBuilder withCurrentState];
    return messageBuilder;
}

+ (nonnull MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(nonnull MPSession *)session userAttributeChange:(nonnull MPUserAttributeChange *)userAttributeChange {
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:messageType session:session];
    [messageBuilder withUserAttributeChange:userAttributeChange];
    
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

- (MPMessage *)build {
    MPMessage *message = nil;
    
    messageDictionary[kMPMessageTypeKey] = _messageType;
    messageDictionary[kMPMessageIdKey] = uuid ? uuid : [[NSUUID UUID] UUIDString];
    
    NSNumber *userId = _session ? _session.userId : [MPPersistenceController mpId];

    message = [[MPMessage alloc] initWithSession:_session
                                     messageType:_messageType
                                     messageInfo:messageDictionary
                                    uploadStatus:MPUploadStatusBatch
                                            UUID:messageDictionary[kMPMessageIdKey]
                                       timestamp:_timestamp
                                          userId:userId];
    
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
    
    if (location && !isCrashReport && !isOptOutMessage) {
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
