//
//  MPBackend.m
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

#import "MPBackendController.h"
#import "MPAppDelegateProxy.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPNetworkPerformance.h"
#import "NSUserDefaults+mParticle.h"
#import "MPBreadcrumb.h"
#import "MPExceptionHandler.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPMessageBuilder.h"
#import "MPStandaloneMessage.h"
#import "MPStandaloneUpload.h"
#import "MPEvent.h"
#import "MPEvent+Internal.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPHasher.h"
#import "MPUploadBuilder.h"
#import "MPILogger.h"
#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPResponseConfig.h"
#import "MPSessionHistory.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCart.h"
#import "MPCart+Dictionary.h"
#import "MPEvent+MessageType.h"
#include "MessageTypeName.h"
#import "MPKitContainer.h"
#import "MPUserAttributeChange.h"
#import "MPUserIdentityChange.h"
#import "MPSearchAdsAttribution.h"
#import "MPURLRequestBuilder.h"

#if TARGET_OS_IOS == 1
#import "MPLocationManager.h"
#endif

#define METHOD_EXEC_MAX_ATTEMPT 10

const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold = 1000;
const NSInteger kInvalidValue = 101;
const NSInteger kEmptyValueAttribute = 102;
const NSInteger kExceededNumberOfAttributesLimit = 103;
const NSInteger kExceededAttributeMaximumLength = 104;
const NSInteger kExceededKeyMaximumLength = 105;
const NSInteger kInvalidDataType = 106;

static NSArray *execStatusDescriptions;
static BOOL appBackgrounded = NO;

@interface MPBackendController() {
    MPAppDelegateProxy *appDelegateProxy;
    NSMutableSet<NSString *> *deletedUserAttributes;
    __weak MPSession *sessionBeingUploaded;
    NSNotification *didFinishLaunchingNotification;
    dispatch_queue_t backendQueue;
    dispatch_queue_t notificationsQueue;
    NSTimeInterval nextCleanUpTime;
    NSTimeInterval timeAppWentToBackground;
    NSTimeInterval backgroundStartTime;
    dispatch_source_t backgroundSource;
    dispatch_source_t uploadSource;
    UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
    dispatch_semaphore_t backendSemaphore;
    BOOL sdkIsLaunching;
    BOOL longSession;
    BOOL originalAppDelegateProxied;
    BOOL resignedActive;
    BOOL retrievingSegments;
}

@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *userIdentities;

@end


@implementation MPBackendController

@synthesize initializationStatus = _initializationStatus;
@synthesize session = _session;
@synthesize uploadInterval = _uploadInterval;

#if TARGET_OS_IOS == 1
@synthesize notificationController = _notificationController;
#endif

+ (void)initialize {
    execStatusDescriptions = @[@"Success", @"Fail", @"Missing Parameter", @"Feature Disabled Remotely", @"Feature Enabled Remotely", @"User Opted Out of Tracking", @"Data Already Being Fetched",
                               @"Invalid Data Type", @"Data is Being Uploaded", @"Server is Busy", @"Item Not Found", @"Feature is Disabled in Settings", @"Delayed Execution",
                               @"Continued Delayed Execution", @"SDK Has Not Been Started Yet", @"There is no network connectivity"];
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        nextCleanUpTime = [[NSDate date] timeIntervalSince1970];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        retrievingSegments = NO;
        _delegate = delegate;
        backgroundStartTime = 0;
        sdkIsLaunching = YES;
        longSession = NO;
        _initializationStatus = MPInitializationStatusNotStarted;
        resignedActive = NO;
        sessionBeingUploaded = nil;
        backgroundSource = nil;
        uploadSource = nil;
        originalAppDelegateProxied = NO;
        backendSemaphore = dispatch_semaphore_create(1);
        
        backendQueue = dispatch_queue_create("com.mParticle.BackendQueue", DISPATCH_QUEUE_SERIAL);
        notificationsQueue = dispatch_queue_create("com.mParticle.NotificationsQueue", DISPATCH_QUEUE_CONCURRENT);
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillTerminate:)
                                   name:UIApplicationWillTerminateNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleNetworkPerformanceNotification:)
                                   name:kMPNetworkPerformanceMeasurementNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleMemoryWarningNotification:)
                                   name:UIApplicationDidReceiveMemoryWarningNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleSignificantTimeChange:)
                                   name:UIApplicationSignificantTimeChangeNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleEventCounterLimitReached:)
                                   name:kMPEventCounterLimitReachedNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        
#if TARGET_OS_IOS == 1
        [notificationCenter addObserver:self
                               selector:@selector(handleDeviceTokenNotification:)
                                   name:kMPRemoteNotificationDeviceTokenNotification
                                 object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter removeObserver:self name:kMPNetworkPerformanceMeasurementNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:kMPEventCounterLimitReachedNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
#if TARGET_OS_IOS == 1
    [notificationCenter removeObserver:self name:kMPRemoteNotificationDeviceTokenNotification object:nil];
#endif
    
    [self endUploadTimer];
}

#pragma mark Accessors
- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (void)setInitializationStatus:(MPInitializationStatus)initializationStatus {
    _initializationStatus = initializationStatus;
}

- (MPNetworkCommunication *)networkCommunication {
    if (_networkCommunication) {
        return _networkCommunication;
    }
    
    [self willChangeValueForKey:@"networkCommunication"];
    _networkCommunication = [[MPNetworkCommunication alloc] init];
    [self didChangeValueForKey:@"networkCommunication"];
    
    return _networkCommunication;
}

- (MPSession *)session {
    dispatch_semaphore_wait(backendSemaphore, DISPATCH_TIME_FOREVER);
    
    bool isNewSession = NO;
    if (!_session) {
        [self willChangeValueForKey:@"session"];
        
        [self beginSession:nil];
        isNewSession = YES;
    }
    
    dispatch_semaphore_signal(backendSemaphore);

    if (isNewSession) {
        [self didChangeValueForKey:@"session"];
    }
    
    return _session;
}

- (NSMutableDictionary<NSString *, id> *)userAttributes {
    if (_userAttributes) {
        return _userAttributes;
    }
    
    _userAttributes = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userAttributes = userDefaults[kMPUserAttributeKey];
    if (userAttributes) {
        NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
        NSString *key;
        id value;
        Class NSStringClass = [NSString class];
        
        while ((key = [attributeEnumerator nextObject])) {
            value = userAttributes[key];
            
            if ([value isKindOfClass:NSStringClass]) {
                _userAttributes[key] = ![userAttributes[key] isEqualToString:kMPNullUserAttributeString] ? value : [NSNull null];
            } else {
                _userAttributes[key] = value;
            }
        }
    }
    
    return _userAttributes;
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentities {
    if (_userIdentities) {
        return _userIdentities;
    }
    
    _userIdentities = [[NSMutableArray alloc] initWithCapacity:10];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *userIdentityArray = userDefaults[kMPUserIdentityArrayKey];
    if (userIdentityArray) {
        [_userIdentities addObjectsFromArray:userIdentityArray];
    }
    
    return _userIdentities;
}

#pragma mark Private methods
- (void)beginBackgroundTask {
    __weak MPBackendController *weakSelf = self;
    
    if (backendBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        backendBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            MPILogDebug(@"SDK has ended background activity together with the app.");

            [MPStateMachine setRunningInBackground:NO];
            [[MPPersistenceController sharedInstance] purgeMemory];
            
            __strong MPBackendController *strongSelf = weakSelf;
            
            if (strongSelf) {
                [strongSelf endBackgroundTimer];
                
                strongSelf->_networkCommunication = nil;
                
                if (strongSelf->_session) {
                    [strongSelf broadcastSessionDidEnd:strongSelf->_session];
                    strongSelf->_session = nil;
                    
                    if (strongSelf.eventSet.count == 0) {
                        strongSelf->_eventSet = nil;
                    }
                }
                
                [strongSelf endBackgroundTask];
            }
        }];
    }
}

- (void)broadcastSessionDidBegin:(MPSession *)session {
    [self.delegate sessionDidBegin:session];
    
    __weak MPBackendController *weakSelf = self;
    double delay = _initializationStatus == MPInitializationStatusStarted ? 0 : 0.1;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), notificationsQueue, ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf) {
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidBeginNotification
                                                                object:strongSelf.delegate
                                                              userInfo:@{mParticleSessionId:@(session.sessionId)}];
        }
    });
}

- (void)broadcastSessionDidEnd:(MPSession *)session {
    [self.delegate sessionDidEnd:session];
    
    __weak MPBackendController *weakSelf = self;
    NSNumber *sessionId = @(session.sessionId);
    dispatch_async(notificationsQueue, ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf) {
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidEndNotification
                                                                object:strongSelf.delegate
                                                              userInfo:@{mParticleSessionId:sessionId}];
        }
    });
}

- (void)cleanUp {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (nextCleanUpTime < currentTime) {
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence deleteExpiredUserNotifications];
        [persistence deleteRecordsOlderThan:(currentTime - ONE_HUNDRED_EIGHTY_DAYS)];
        nextCleanUpTime = currentTime + TWENTY_FOUR_HOURS;
    }
}

- (void)endBackgroundTask {
    if (backendBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backendBackgroundTaskIdentifier];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)forceAppFinishedLaunching {
    sdkIsLaunching = NO;
}

- (void)logUserAttributeChange:(MPUserAttributeChange *)userAttributeChange {
    if (!userAttributeChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:static_cast<MPMessageType>(mParticle::MessageType::UserAttributeChange)
                                                                           session:self.session
                                                               userAttributeChange:userAttributeChange];
    if (userAttributeChange.timestamp) {
        [messageBuilder withTimestamp:[userAttributeChange.timestamp timeIntervalSince1970]];
    }
    
    MPDataModelAbstract *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (void)logUserIdentityChange:(MPUserIdentityChange *)userIdentityChange {
    if (!userIdentityChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:static_cast<MPMessageType>(mParticle::MessageType::UserIdentityChange)
                                                                           session:self.session
                                                                userIdentityChange:userIdentityChange];
    if (userIdentityChange.timestamp) {
        [messageBuilder withTimestamp:[userIdentityChange.timestamp timeIntervalSince1970]];
    }
    
    MPDataModelAbstract *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSNumber *previousSessionSuccessfullyClosed = nil;
    if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        NSDictionary *previousSessionStateDictionary = [NSDictionary dictionaryWithContentsOfFile:previousSessionStateFile];
        previousSessionSuccessfullyClosed = previousSessionStateDictionary[kMPASTPreviousSessionSuccessfullyClosedKey];
    }
    
    if (!previousSessionSuccessfullyClosed) {
        previousSessionSuccessfullyClosed = @YES;
    }
    
    return previousSessionSuccessfullyClosed;
}

- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSDictionary *previousSessionStateDictionary = @{kMPASTPreviousSessionSuccessfullyClosedKey:previousSessionSuccessfullyClosed};
    
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        [fileManager removeItemAtPath:previousSessionStateFile error:nil];
    }
    
    [previousSessionStateDictionary writeToFile:previousSessionStateFile atomically:YES];
}

- (void)processDidFinishLaunching:(NSNotification *)notification {
    NSString *astType = kMPASTInitKey;
    NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (stateMachine.installationType == MPInstallationTypeKnownInstall) {
        messageInfo[kMPASTIsFirstRunKey] = @YES;
        [self.delegate forwardLogInstall];
    } else if (stateMachine.installationType == MPInstallationTypeKnownUpgrade) {
        messageInfo[kMPASTIsUpgradeKey] = @YES;
        [self.delegate forwardLogUpdate];
    }
    
    messageInfo[kMPASTPreviousSessionSuccessfullyClosedKey] = [self previousSessionSuccessfullyClosed];
    
    NSDictionary *userInfo = [notification userInfo];
    BOOL sessionFinalized = YES;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        NSUserActivity *userActivity = userInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey][@"UIApplicationLaunchOptionsUserActivityKey"];
        
        if (userActivity) {
            stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
        }
    }
    
#if TARGET_OS_IOS == 1
    MParticleUserNotification *userNotification = nil;
    NSDictionary *pushNotificationDictionary = userInfo[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (pushNotificationDictionary) {
        NSError *error = nil;
        NSData *remoteNotificationData = [NSJSONSerialization dataWithJSONObject:pushNotificationDictionary options:0 error:&error];
        
        int64_t launchNotificationHash = 0;
        if (!error && remoteNotificationData.length > 0) {
            launchNotificationHash = mParticle::Hasher::hashFNV1a(static_cast<const char *>([remoteNotificationData bytes]), static_cast<int>([remoteNotificationData length]));
        }
        
        if (launchNotificationHash != 0 && [MPNotificationController launchNotificationHash] != 0 && launchNotificationHash != [MPNotificationController launchNotificationHash]) {
            astType = kMPASTForegroundKey;
            userNotification = [self.notificationController newUserNotificationWithDictionary:pushNotificationDictionary
                                                                             actionIdentifier:nil
                                                                                        state:kMPPushNotificationStateNotRunning];
            
            if (userNotification.redactedUserNotificationString) {
                messageInfo[kMPPushMessagePayloadKey] = userNotification.redactedUserNotificationString;
            }
            
            if (_session) {
                NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval backgroundedTime = (currentTime - _session.endTime) > 0 ? (currentTime - _session.endTime) : 0;
                sessionFinalized = backgroundedTime > self.sessionTimeout;
            }
        }
    }
    
    if (userNotification) {
        [self receivedUserNotification:userNotification];
    }
#endif
    
    messageInfo[kMPAppStateTransitionType] = astType;
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    messageBuilder = [messageBuilder withStateTransition:sessionFinalized previousSession:nil];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self saveMessage:message updateSession:YES];

    didFinishLaunchingNotification = nil;
    
    MPILogVerbose(@"Application Did Finish Launching");
}

- (void)processOpenSessionsIncludingCurrent:(BOOL)includeCurrentSession completionHandler:(void (^)(BOOL success))completionHandler {
    [self endUploadTimer];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchSessions:^(NSMutableArray<MPSession *> *sessions) {
        if (includeCurrentSession) {
            self.session.endTime = [[NSDate date] timeIntervalSince1970];
            [persistence updateSession:self.session];
        } else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %ld", self.session.sessionId];
            MPSession *currentSession = [[sessions filteredArrayUsingPredicate:predicate] lastObject];
            [sessions removeObject:currentSession];
            
            for (MPSession *openSession in sessions) {
                [self broadcastSessionDidEnd:openSession];
            }
        }
        
        [self uploadOpenSessions:sessions completionHandler:completionHandler];
    }];
}

- (void)processPendingArchivedMessages {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *crashLogsDirectoryPath = CRASH_LOGS_DIRECTORY_PATH;
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    NSArray *directoryPaths = @[crashLogsDirectoryPath, archivedMessagesDirectoryPath];
    NSArray *fileExtensions = @[@".log", @".arcmsg"];
    
    [directoryPaths enumerateObjectsUsingBlock:^(NSString *directoryPath, NSUInteger idx, BOOL *stop) {
        if (![fileManager fileExistsAtPath:directoryPath]) {
            return;
        }
        
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'", fileExtensions[idx]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        for (NSString *fileName in directoryContents) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            MPMessage *message = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            
            if (message) {
                [self saveMessage:message updateSession:NO];
            }
            
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }];
}

- (void)processPendingUploads {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    __weak MPBackendController *weakSelf = self;
    
    [persistence fetchUploadsExceptInSession:self.session
                           completionHandler:^(NSArray<MPUpload *> * _Nullable uploads) {
                               if (!uploads) {
                                   return;
                               }
                               
                               if ([MPStateMachine sharedInstance].dataRamped) {
                                   for (MPUpload *upload in uploads) {
                                       [persistence deleteUpload:upload];
                                   }
                                   
                                   return;
                               }
                               
                               __strong MPBackendController *strongSelf = weakSelf;
                               [strongSelf.networkCommunication upload:uploads
                                                                 index:0
                                                     completionHandler:^(BOOL success, MPUpload *upload, NSDictionary *responseDictionary, BOOL finished) {
                                                         if (!success) {
                                                             return;
                                                         }
                                                         
                                                         [persistence deleteUpload:upload];
                                                         
                                                         MPSession *previousSession = [persistence fetchPreviousSessionSync];
                                                         MPSessionHistory *sessionHistory = [[MPSessionHistory alloc] initWithSession:previousSession
                                                                                                                              uploads:uploads];
                                                         
                                                         if (!sessionHistory) {
                                                             return;
                                                         }

                                                         sessionHistory.userAttributes = self.userAttributes;
                                                         sessionHistory.userIdentities = self.userIdentities;

                                                         [strongSelf.networkCommunication uploadSessionHistory:sessionHistory
                                                                                             completionHandler:^(BOOL success) {
                                                                                                 if (!success) {
                                                                                                     return;
                                                                                                 }
                                                                                                 
                                                                                                 for (NSNumber *uploadId in sessionHistory.uploadIds) {
                                                                                                     [persistence deleteUploadId:[uploadId intValue]];
                                                                                                 }
                                                                                             }];
                                                     }];
                           }];
}

- (void)proxyOriginalAppDelegate {
    if (originalAppDelegateProxied) {
        return;
    }
    
    originalAppDelegateProxied = YES;
    
    UIApplication *application = [UIApplication sharedApplication];
    appDelegateProxy = [[MPAppDelegateProxy alloc] initWithOriginalAppDelegate:application.delegate];
    application.delegate = appDelegateProxy;
}

- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler {
    if (self.networkCommunication.inUse) {
        return;
    }
    
    __weak MPBackendController *weakSelf = self;
    
    [self.networkCommunication requestConfig:^(BOOL success, NSDictionary * _Nullable configurationDictionary) {
        if (!success) {
            if (completionHandler) {
                completionHandler(NO);
            }
            
            return;
        }
        
        __strong MPBackendController *strongSelf = weakSelf;
        
        MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configurationDictionary];
        [MPResponseConfig save:responseConfig];
        
        if (responseConfig.influencedOpenTimer && strongSelf) {
#if TARGET_OS_IOS == 1
            strongSelf.notificationController.influencedOpenTimer = [responseConfig.influencedOpenTimer doubleValue];
#endif
        }
        
        if ([[MPStateMachine sharedInstance].minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
            MPILogDebug(@"Throttling batches");
            
            if (completionHandler) {
                completionHandler(NO);
            }
        } else if (completionHandler) {
            completionHandler(YES);
        }
    }];
}

- (void)resetUserIdentitiesFirstTimeUseFlag {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", kMPIsFirstTimeUserIdentityHasBeenSet, @YES];
    NSArray *userIdentities = [self.userIdentities filteredArrayUsingPredicate:predicate];
    
    for (NSDictionary *userIdentity in userIdentities) {
        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] integerValue];
        
        [self setUserIdentity:userIdentity[kMPUserIdentityIdKey]
                 identityType:identityType
                      attempt:0
            completionHandler:^(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                
            }];
    }
}

- (void)setUserAttributeChange:(MPUserAttributeChange *)userAttributeChange attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user attribute cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusFail);
        }
        
        return;
    }
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            if ([MPStateMachine sharedInstance].optOut) {
                if (completionHandler) {
                    completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusOptOut);
                }
                
                return;
            }
            
            if (userAttributeChange.value && ![userAttributeChange.value isKindOfClass:[NSString class]] && ![userAttributeChange.value isKindOfClass:[NSNumber class]] && ![userAttributeChange.value isKindOfClass:[NSArray class]]) {
                if (completionHandler) {
                    completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
                }
                
                return;
            }
            
            dispatch_sync(backendQueue, ^{
                id<NSObject> userAttributeValue = nil;
                NSString *localKey = [self.userAttributes caseInsensitiveKey:userAttributeChange.key];
                NSError *error = nil;
                NSUInteger maxValueLength = userAttributeChange.isArray ? MAX_USER_ATTR_LIST_ENTRY_LENGTH : LIMIT_USER_ATTR_LENGTH;
                BOOL validAttributes = [self checkAttribute:userAttributeChange.userAttributes key:localKey value:userAttributeChange.value maxValueLength:maxValueLength error:&error];
                
                if (userAttributeChange.isArray) {
                    userAttributeValue = userAttributeChange.value;
                    userAttributeChange.deleted = error.code == kInvalidValue && self.userAttributes[localKey];
                } else {
                    if (!validAttributes && error.code == kInvalidValue) {
                        userAttributeValue = [NSNull null];
                        validAttributes = YES;
                        error = nil;
                    } else {
                        userAttributeValue = userAttributeChange.value;
                    }
                    
                    userAttributeChange.deleted = error.code == kEmptyValueAttribute && self.userAttributes[localKey];
                }
                
                if (validAttributes) {
                    self.userAttributes[localKey] = userAttributeValue;
                } else if (userAttributeChange.deleted) {
                    [self.userAttributes removeObjectForKey:localKey];
                    
                    if (!deletedUserAttributes) {
                        deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
                    }
                    [deletedUserAttributes addObject:userAttributeChange.key];
                } else {
                    if (completionHandler) {
                        completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
                    }
                    
                    return;
                }
                
                NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] initWithCapacity:self.userAttributes.count];
                NSEnumerator *attributeEnumerator = [self.userAttributes keyEnumerator];
                NSString *aKey;
                
                while ((aKey = [attributeEnumerator nextObject])) {
                    if ((NSNull *)self.userAttributes[aKey] == [NSNull null]) {
                        userAttributes[aKey] = kMPNullUserAttributeString;
                    } else {
                        userAttributes[aKey] = self.userAttributes[aKey];
                    }
                }

                if (userAttributeChange.changed) {
                    userAttributeChange.valueToLog = userAttributeValue;
                    [self logUserAttributeChange:userAttributeChange];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    userDefaults[kMPUserAttributeKey] = userAttributes;
                    [userDefaults synchronize];
                });
                
                if (completionHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSuccess);
                    });
                }
            });
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!userAttributeChange.timestamp) {
                userAttributeChange.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserAttributeChange:userAttributeChange attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            if (completionHandler) {
                MPExecStatus execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
                completionHandler(userAttributeChange.key, userAttributeChange.value, execStatus);
            }
        }
            break;
            
        case MPInitializationStatusNotStarted: {
            if (completionHandler) {
                completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSDKNotStarted);
            }
        }
            break;
    }
}

- (void)setUserIdentityChange:(MPUserIdentityChange *)userIdentityChange attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user identity cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, MPExecStatusFail);
        return;
    }
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            dispatch_sync(backendQueue, ^{
                NSNumber *identityTypeNumber = @(userIdentityChange.userIdentityNew.type);
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", kMPUserIdentityTypeKey, identityTypeNumber];
                NSDictionary *userIdentity = [[self.userIdentities filteredArrayUsingPredicate:predicate] lastObject];
                
                if (userIdentity &&
                    [userIdentity[kMPUserIdentityIdKey] caseInsensitiveCompare:userIdentityChange.userIdentityNew.value] == NSOrderedSame &&
                    ![userIdentity[kMPUserIdentityIdKey] isEqualToString:userIdentityChange.userIdentityNew.value])
                {
                    return;
                }
                
                BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
                    NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
                    BOOL foundMatch = [currentIdentityType isEqualToNumber:identityTypeNumber];
                    
                    if (foundMatch) {
                        *stop = YES;
                    }
                    
                    return foundMatch;
                };
                
                NSMutableDictionary<NSString *, id> *identityDictionary;
                NSUInteger existingEntryIndex;
                BOOL persistUserIdentities = NO;
                
                if (userIdentityChange.userIdentityNew.value == nil || [userIdentityChange.userIdentityNew.value isEqualToString:@""]) {
                    existingEntryIndex = [self.userIdentities indexOfObjectPassingTest:objectTester];
                    
                    if (existingEntryIndex != NSNotFound) {
                        identityDictionary = [self.userIdentities[existingEntryIndex] mutableCopy];
                        userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:identityDictionary];
                        userIdentityChange.userIdentityNew = nil;
                        
                        [self.userIdentities removeObjectAtIndex:existingEntryIndex];
                        persistUserIdentities = YES;
                    }
                } else {
                    identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
                    
                    NSError *error = nil;
                    if ([self checkAttribute:identityDictionary key:kMPUserIdentityIdKey value:userIdentityChange.userIdentityNew.value error:&error] &&
                        [self checkAttribute:identityDictionary key:kMPUserIdentityTypeKey value:[identityTypeNumber stringValue] error:&error]) {
                        
                        existingEntryIndex = [self.userIdentities indexOfObjectPassingTest:objectTester];
                        
                        if (existingEntryIndex == NSNotFound) {
                            userIdentityChange.userIdentityNew.dateFirstSet = [NSDate date];
                            userIdentityChange.userIdentityNew.isFirstTimeSet = YES;
                            
                            identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
                            
                            [self.userIdentities addObject:identityDictionary];
                        } else {
                            userIdentity = self.userIdentities[existingEntryIndex];
                            userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:userIdentity];
                            
                            NSNumber *timeIntervalMilliseconds = userIdentity[kMPDateUserIdentityWasFirstSet];
                            userIdentityChange.userIdentityNew.dateFirstSet = timeIntervalMilliseconds ? [NSDate dateWithTimeIntervalSince1970:([timeIntervalMilliseconds doubleValue] / 1000.0)] : [NSDate date];
                            userIdentityChange.userIdentityNew.isFirstTimeSet = NO;
                            
                            identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
                            
                            [self.userIdentities replaceObjectAtIndex:existingEntryIndex withObject:identityDictionary];
                        }
                        
                        persistUserIdentities = YES;
                    }
                }
                
                if (persistUserIdentities) {
                    if (userIdentityChange.changed) {
                        [self logUserIdentityChange:userIdentityChange];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        userDefaults[kMPUserIdentityArrayKey] = self.userIdentities;
                        [userDefaults synchronize];
                    });
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, MPExecStatusSuccess);
                });
            });
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!userIdentityChange.timestamp) {
                userIdentityChange.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserIdentityChange:userIdentityChange attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            MPExecStatus execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
            completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, execStatus);
        }
            break;
            
        case MPInitializationStatusNotStarted:
            completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, MPExecStatusSDKNotStarted);
            break;
    }
}

- (void)uploadBatchesFromSession:(MPSession *)session completionHandler:(void(^)(MPSession *uploadedSession))completionHandler {
    if ([sessionBeingUploaded isEqual:session]) {
        return;
    }
    
    const void (^completionHandlerCopy)(MPSession *) = [completionHandler copy];
    MPSession *uploadSession = [session copy];
    sessionBeingUploaded = uploadSession;
    __weak MPBackendController *weakSelf = self;
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchMessagesForUploadingInSession:uploadSession
                                  completionHandler:^(NSArray<MPMessage *> *messages) {
                                      if (!messages) {
                                          sessionBeingUploaded = nil;
                                          completionHandlerCopy(uploadSession);
                                          return;
                                      }
                                      
                                      __strong MPBackendController *strongSelf = weakSelf;
                                      MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:uploadSession messages:messages sessionTimeout:strongSelf.sessionTimeout uploadInterval:strongSelf.uploadInterval];
                                      
                                      if (!uploadBuilder || !strongSelf) {
                                          sessionBeingUploaded = nil;
                                          completionHandlerCopy(uploadSession);
                                          return;
                                      }
                                      
                                      [uploadBuilder withUserAttributes:strongSelf.userAttributes deletedUserAttributes:deletedUserAttributes];
                                      [uploadBuilder withUserIdentities:strongSelf.userIdentities];
                                      [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                          [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
                                          [strongSelf resetUserIdentitiesFirstTimeUseFlag];
                                          
                                          [persistence fetchUploadsInSession:session
                                                           completionHandler:^(NSArray<MPUpload *> *uploads) {
                                                               if (!uploads) {
                                                                   sessionBeingUploaded = nil;
                                                                   completionHandlerCopy(uploadSession);
                                                                   return;
                                                               }
                                                               
                                                               if ([MPStateMachine sharedInstance].dataRamped) {
                                                                   for (MPUpload *upload in uploads) {
                                                                       [persistence deleteUpload:upload];
                                                                   }
                                                                   
                                                                   [persistence deleteNetworkPerformanceMessages];
                                                                   [persistence deleteMessages:messages];
                                                                   return;
                                                               }
                                                               
                                                               [strongSelf.networkCommunication upload:uploads
                                                                                                 index:0
                                                                                     completionHandler:^(BOOL success, MPUpload *upload, NSDictionary *responseDictionary, BOOL finished) {
                                                                                         if (!success) {
                                                                                             return;
                                                                                         }
                                                                                         
                                                                                         [MPResponseEvents parseConfiguration:responseDictionary session:uploadSession];
                                                                                         
                                                                                         [persistence deleteUpload:upload];
                                                                                         
                                                                                         if (!finished) {
                                                                                             return;
                                                                                         }
                                                                                         
                                                                                         sessionBeingUploaded = nil;
                                                                                         completionHandlerCopy(uploadSession);
                                                                                     }];
                                                           }];
                                      }];
                                      
                                      deletedUserAttributes = nil;
                                  }];
}

- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(BOOL success))completionHandler {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    void (^invokeCompletionHandler)(BOOL) = ^(BOOL success) {
        if ([NSThread isMainThread]) {
            completionHandler(success);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success);
            });
        }
    };
    
    if (!openSessions || openSessions.count == 0) {
        [persistence deleteMessagesWithNoSession];
        invokeCompletionHandler(YES);
        return;
    }
    
    __block MPSession *session = [openSessions[0] copy];
    [openSessions removeObjectAtIndex:0];
    NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(session.foregroundTime),
                                          kMPSessionTotalLengthKey:MPMilliseconds(session.length)}
                                        mutableCopy];
    
    NSDictionary *sessionAttributesDictionary = [session.attributesDictionary transformValuesToString];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:session.endTime] build];
        
        [self saveMessage:message updateSession:NO];
        MPILogVerbose(@"Session Ended: %@", session.uuid);
    }
    
    __weak MPBackendController *weakSelf = self;
    
    [self requestConfig:^(BOOL uploadBatch) {
        if (!uploadBatch) {
            invokeCompletionHandler(NO);
            return;
        }
        
        __strong MPBackendController *strongSelf = weakSelf;
        
        if ([MPStateMachine sharedInstance].shouldUploadSessionHistory) {
            [strongSelf uploadBatchesFromSession:session
                               completionHandler:^(MPSession *uploadedSession) {
                                   session = nil;
                                   
                                   if (uploadedSession) {
                                       [strongSelf uploadSessionHistory:uploadedSession completionHandler:^(BOOL sessionHistorySuccess) {
                                           if (sessionHistorySuccess) {
                                               [strongSelf uploadOpenSessions:openSessions completionHandler:completionHandler];
                                           } else {
                                               invokeCompletionHandler(NO);
                                           }
                                       }];
                                   } else {
                                       invokeCompletionHandler(NO);
                                   }
                               }];
        } else {
            invokeCompletionHandler(NO);
        }
    }];
}

- (void)uploadSessionHistory:(MPSession *)session completionHandler:(void (^)(BOOL sessionHistorySuccess))completionHandler {
    if (!session) {
        return;
    }
    
    __weak MPBackendController *weakSelf = self;
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchUploadedMessagesInSession:session
              excludeNetworkPerformanceMessages:NO
                              completionHandler:^(NSArray<MPMessage *> *messages) {
                                  if (!messages) {
                                      if (completionHandler) {
                                          completionHandler(NO);
                                      }
                                      
                                      return;
                                  }
                                  
                                  __strong MPBackendController *strongSelf = weakSelf;
                                  
                                  MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:session
                                                                                                 messages:messages
                                                                                           sessionTimeout:strongSelf.sessionTimeout
                                                                                           uploadInterval:strongSelf.uploadInterval];
                                  
                                  if (!uploadBuilder || !strongSelf) {
                                      if (completionHandler) {
                                          completionHandler(NO);
                                      }
                                      
                                      return;
                                  }
                                  
                                  [uploadBuilder withUserAttributes:strongSelf.userAttributes deletedUserAttributes:deletedUserAttributes];
                                  [uploadBuilder withUserIdentities:strongSelf.userIdentities];
                                  [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                      [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
                                      
                                      [persistence fetchUploadsInSession:session
                                                       completionHandler:^(NSArray<MPUpload *> *uploads) {
                                                           MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
                                                           if (!stateMachine.shouldUploadSessionHistory || stateMachine.dataRamped) {
                                                               for (MPUpload *upload in uploads) {
                                                                   [persistence deleteUpload:upload];
                                                               }
                                                               
                                                               [persistence deleteMessages:messages];
                                                               [persistence deleteNetworkPerformanceMessages];
                                                               
                                                               [persistence archiveSession:session
                                                                         completionHandler:^(MPSession *archivedSession) {
                                                                             [persistence deleteSession:archivedSession];
                                                                             
                                                                             if (completionHandler) {
                                                                                 completionHandler(NO);
                                                                             }
                                                                         }];
                                                               
                                                               return;
                                                           }
                                                           
                                                           MPSessionHistory *sessionHistory = [[MPSessionHistory alloc] initWithSession:session uploads:uploads];
                                                           sessionHistory.userAttributes = self.userAttributes;
                                                           sessionHistory.userIdentities = self.userIdentities;
                                                           
                                                           if (!sessionHistory) {
                                                               if (completionHandler) {
                                                                   completionHandler(NO);
                                                               }
                                                               
                                                               return;
                                                           }
                                                           
                                                           [strongSelf.networkCommunication uploadSessionHistory:sessionHistory
                                                                                               completionHandler:^(BOOL success) {
                                                                                                   if (!success) {
                                                                                                       if (completionHandler) {
                                                                                                           completionHandler(NO);
                                                                                                       }
                                                                                                       
                                                                                                       return;
                                                                                                   }
                                                                                                   
                                                                                                   for (NSNumber *uploadId in sessionHistory.uploadIds) {
                                                                                                       [persistence deleteUploadId:[uploadId intValue]];
                                                                                                   }
                                                                                                   
                                                                                                   [persistence archiveSession:session
                                                                                                             completionHandler:^(MPSession *archivedSession) {
                                                                                                                 [persistence deleteSession:archivedSession];
                                                                                                                 [persistence deleteNetworkPerformanceMessages];
                                                                                                                 
                                                                                                                 if (completionHandler) {
                                                                                                                     completionHandler(YES);
                                                                                                                 }
                                                                                                             }];
                                                                                               }];
                                                       }];
                                  }];
                              }];
}

- (void)uploadStandaloneMessages {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray<MPStandaloneMessage *> *standaloneMessages = [persistence fetchStandaloneMessages];
    
    if (!standaloneMessages) {
        return;
    }
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMessages:standaloneMessages uploadInterval:self.uploadInterval];
    
    if (!uploadBuilder) {
        return;
    }
    
    [uploadBuilder withUserAttributes:self.userAttributes deletedUserAttributes:deletedUserAttributes];
    [uploadBuilder withUserIdentities:self.userIdentities];
    [uploadBuilder build:^(MPDataModelAbstract *standaloneUpload) {
        [persistence saveStandaloneUpload:(MPStandaloneUpload *)standaloneUpload];
        [persistence deleteStandaloneMessageIds:uploadBuilder.preparedMessageIds];
    }];
    
    NSArray<MPStandaloneUpload *> *standaloneUploads = [persistence fetchStandaloneUploads];
    if (!standaloneUploads) {
        return;
    }
    
    if ([MPStateMachine sharedInstance].dataRamped) {
        for (MPStandaloneUpload *standaloneUpload in standaloneUploads) {
            [persistence deleteStandaloneUpload:standaloneUpload];
        }
        
        return;
    }
    
    [self.networkCommunication standaloneUploads:standaloneUploads
                                           index:0
                               completionHandler:^(BOOL success, MPStandaloneUpload *standaloneUpload, NSDictionary *responseDictionary, BOOL finished) {
                                   if (!success) {
                                       return;
                                   }
                                   
                                   [MPResponseEvents parseConfiguration:responseDictionary session:nil];
                                   
                                   [persistence deleteStandaloneUpload:standaloneUpload];
                               }];
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (appBackgrounded || [MPStateMachine runningInBackground]) {
        return;
    }
    
    MPILogVerbose(@"Application Did Enter Background");
    
    appBackgrounded = YES;
    [MPStateMachine setRunningInBackground:YES];
    
    timeAppWentToBackground = [[NSDate date] timeIntervalSince1970];
    
    [self setPreviousSessionSuccessfullyClosed:@YES];
    [self cleanUp];
    [self endUploadTimer];
    
    NSMutableDictionary *messageInfo = [@{kMPAppStateTransitionType:kMPASTBackgroundKey} mutableCopy];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    if ([MPLocationManager trackingLocation] && ![MPStateMachine sharedInstance].locationManager.backgroundLocationTracking) {
        [[MPStateMachine sharedInstance].locationManager.locationManager stopUpdatingLocation];
    }
    
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self.session suspendSession];
    [self saveMessage:message updateSession:YES];
    [self beginBackgroundTask];

    [self uploadWithCompletionHandler:^{
        [self beginBackgroundTimer];
    }];
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    backgroundStartTime = 0;
    
    [self endBackgroundTimer];
    
    appBackgrounded = NO;
    [MPStateMachine setRunningInBackground:NO];
    resignedActive = NO;
    
    [self endBackgroundTask];
    
#if TARGET_OS_IOS == 1
    if ([MPLocationManager trackingLocation] && ![MPStateMachine sharedInstance].locationManager.backgroundLocationTracking) {
        [[MPStateMachine sharedInstance].locationManager.locationManager startUpdatingLocation];
    }
#endif
    
    [self requestConfig:nil];
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    didFinishLaunchingNotification = [notification copy];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];

    if (_session) {
        MPSession *sessionCopy = [_session copy];
        
        // App exit message
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:sessionCopy messageInfo:@{kMPAppStateTransitionType:kMPASTExitKey}];
        MPMessage *message = (MPMessage *)[messageBuilder build];
        
        [persistence saveMessage:message];
        
        // Session end message
        sessionCopy.endTime = [[NSDate date] timeIntervalSince1970];
        
        NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(sessionCopy.foregroundTime),
                                              kMPSessionTotalLengthKey:MPMilliseconds(sessionCopy.length),
                                              kMPEventCounterKey:@(sessionCopy.eventCounter)}
                                            mutableCopy];
        
        NSDictionary *sessionAttributesDictionary = [sessionCopy.attributesDictionary transformValuesToString];
        if (sessionAttributesDictionary) {
            messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
        }
        
        messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:sessionCopy messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:sessionCopy.endTime] build];
        [persistence saveMessage:message];
        
        // Generate the upload batch
        NSArray<MPMessage *> *messages = [persistence fetchMessagesForUploadingInSession:sessionCopy];
        if (messages) {
            MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:sessionCopy
                                                                           messages:messages
                                                                     sessionTimeout:self.sessionTimeout
                                                                     uploadInterval:self.uploadInterval];
            
            [uploadBuilder withUserAttributes:self.userAttributes deletedUserAttributes:deletedUserAttributes];
            [uploadBuilder withUserIdentities:self.userIdentities];
            [uploadBuilder buildAsync:NO completionHandler:^(MPDataModelAbstract * _Nullable upload) {
                [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
            }];
        }
        
        // Archive session
        MPSession *archivedSession = [persistence archiveSessionSync:sessionCopy];
        if (archivedSession) {
            [persistence deleteSessionSync:archivedSession];
        }
    }
    
    // Close the database
    if (persistence.databaseOpen) {
        [persistence closeDatabase];
    }

    [self endBackgroundTask];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
    self.userAttributes = nil;
    self.userIdentities = nil;
}

- (void)handleNetworkPerformanceNotification:(NSNotification *)notification {
    if (!_session) {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    MPNetworkPerformance *networkPerformance = userInfo[kMPNetworkPerformanceKey];
    
    [self logNetworkPerformanceMeasurement:networkPerformance attempt:0 completionHandler:nil];
}

- (void)handleSignificantTimeChange:(NSNotification *)notification {
    if (_session) {
        [self beginSession:nil];
    }
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    if (sdkIsLaunching || [MPStateMachine sharedInstance].optOut) {
        sdkIsLaunching = NO;
        return;
    }
    
    if (resignedActive) {
        resignedActive = NO;
        return;
    }
    
    BOOL sessionExpired = _session == nil;
    if (!sessionExpired) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        _session.backgroundTime += currentTime - timeAppWentToBackground;
        timeAppWentToBackground = 0.0;
        _session.endTime = currentTime;
        [[MPPersistenceController sharedInstance] updateSession:_session];
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:@{kMPAppStateTransitionType:kMPASTForegroundKey}];
    messageBuilder = [messageBuilder withStateTransition:sessionExpired previousSession:nil];
#if TARGET_OS_IOS == 1
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    [self saveMessage:message updateSession:YES];
    
    [self beginUploadTimer];

    MPILogVerbose(@"Application Did Become Active");
}

- (void)handleEventCounterLimitReached:(NSNotification *)notification {
    MPILogDebug(@"The event limit has been exceeded for this session. Automatically begining a new session.");
    [self beginSession:nil];
}

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    resignedActive = YES;
}

#pragma mark Timers
- (void)beginBackgroundTimer {
    __weak MPBackendController *weakSelf = self;
    
    backgroundSource = [self createSourceTimer:(MINIMUM_SESSION_TIMEOUT + 0.1)
                                  eventHandler:^{
                                      NSTimeInterval backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
                                      __strong MPBackendController *strongSelf = weakSelf;
                                      if (!strongSelf) {
                                          return;
                                      }
                                      
                                      strongSelf->longSession = backgroundTimeRemaining > kMPRemainingBackgroundTimeMinimumThreshold;
                                      
                                      if (!strongSelf->longSession) {
                                          NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                                          
                                          void(^processSession)(NSTimeInterval) = ^(NSTimeInterval timeout) {
                                              [strongSelf endBackgroundTimer];
                                              strongSelf.session.backgroundTime += timeout;
                                              
                                              [strongSelf processOpenSessionsIncludingCurrent:YES
                                                                            completionHandler:^(BOOL success) {
                                                                                [MPStateMachine setRunningInBackground:NO];
                                                                                [strongSelf broadcastSessionDidEnd:strongSelf->_session];
                                                                                strongSelf->_session = nil;
                                                                                
                                                                                if (strongSelf.eventSet.count == 0) {
                                                                                    strongSelf->_eventSet = nil;

                                                                                }
                                                                                
                                                                                MPILogDebug(@"SDK has ended background activity.");
                                                                                [strongSelf endBackgroundTask];
                                                                            }];
                                          };
                                          
                                          if ((MINIMUM_SESSION_TIMEOUT + 0.1) >= strongSelf.sessionTimeout) {
                                              processSession(strongSelf.sessionTimeout);
                                          } else if (backgroundStartTime == 0) {
                                              backgroundStartTime = currentTime;
                                          } else if ((currentTime - backgroundStartTime) >= strongSelf.sessionTimeout) {
                                              processSession(currentTime - timeAppWentToBackground);
                                          }
                                      } else {
                                          backgroundStartTime = 0;

                                          if (!strongSelf->uploadSource) {
                                              [strongSelf beginUploadTimer];
                                          }
                                      }
                                  } cancelHandler:^{
                                      __strong MPBackendController *strongSelf = weakSelf;
                                      if (strongSelf) {
                                          strongSelf->backgroundSource = nil;
                                      }
                                  }];
}

- (void)beginUploadTimer {
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (strongSelf->uploadSource) {
            dispatch_source_cancel(strongSelf->uploadSource);
            strongSelf->uploadSource = nil;
        }
        
        strongSelf->uploadSource = [strongSelf createSourceTimer:strongSelf.uploadInterval
                                                    eventHandler:^{
                                                        [strongSelf uploadWithCompletionHandler:nil];
                                                    } cancelHandler:^{
                                                        strongSelf->uploadSource = nil;
                                                    }];
    });
}

- (dispatch_source_t)createSourceTimer:(uint64_t)interval eventHandler:(dispatch_block_t)eventHandler cancelHandler:(dispatch_block_t)cancelHandler {
    dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, backendQueue);
    
    if (sourceTimer) {
        dispatch_source_set_timer(sourceTimer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(sourceTimer, eventHandler);
        dispatch_source_set_cancel_handler(sourceTimer, cancelHandler);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), backendQueue, ^{
            dispatch_resume(sourceTimer);
        });
    }
    
    return sourceTimer;
}

- (void)endBackgroundTimer {
    if (backgroundSource) {
        dispatch_source_cancel(backgroundSource);
    }
}

- (void)endUploadTimer {
    if (uploadSource) {
        dispatch_source_cancel(uploadSource);
    }
}

#pragma mark Public accessors
- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    if (sessionTimeout == _sessionTimeout) {
        return;
    }
    
    _sessionTimeout = MIN(MAX(sessionTimeout, MINIMUM_SESSION_TIMEOUT), MAXIMUM_SESSION_TIMEOUT);
}

- (NSTimeInterval)uploadInterval {
    if (_uploadInterval == 0.0) {
        _uploadInterval = [MPStateMachine environment] == MPEnvironmentDevelopment ? DEFAULT_DEBUG_UPLOAD_INTERVAL : DEFAULT_UPLOAD_INTERVAL;
    }
    
    return _uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    if (uploadInterval == _uploadInterval) {
        return;
    }
    
    _uploadInterval = MAX(uploadInterval, 1.0);
    
#if TARGET_OS_TV == 1
    _uploadInterval = MIN(_uploadInterval, DEFAULT_UPLOAD_INTERVAL);
#endif
    
    if (uploadSource) {
        [self beginUploadTimer];
    }
}

#pragma mark Public methods
- (void)beginSession:(void (^)(MPSession *session, MPSession *previousSession, MPExecStatus execStatus))completionHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        if (completionHandler) {
            completionHandler(nil, nil, MPExecStatusOptOut);
        }
        
        return;
    }
    
    if (_session) {
        [self endSession];
    }
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchPreviousSession:^(MPSession *previousSession) {
        NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSInteger previousSessionLength = 0;
        if (previousSession) {
            previousSessionLength = trunc(previousSession.length);
            messageInfo[kMPPreviousSessionIdKey] = previousSession.uuid;
            messageInfo[kMPPreviousSessionStartKey] = MPMilliseconds(previousSession.startTime);
        }
        
        messageInfo[kMPPreviousSessionLengthKey] = @(previousSessionLength);
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionStart session:_session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:stateMachine.location];
#endif
        MPMessage *message = (MPMessage *)[[messageBuilder withTimestamp:_session.startTime] build];
        
        [self saveMessage:message updateSession:YES];
        
        if (completionHandler) {
            completionHandler(_session, previousSession, MPExecStatusSuccess);
        }
    }];
    
    [persistence saveSession:_session];
    
    stateMachine.currentSession = _session;
    
    [self broadcastSessionDidBegin:_session];
    
    MPILogVerbose(@"New Session Has Begun: %@", _session.uuid);
}

- (void)endSession {
    if (_session == nil || [MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    _session.endTime = [[NSDate date] timeIntervalSince1970];
    
    MPSession *endSession = [_session copy];
    NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(endSession.foregroundTime),
                                          kMPSessionTotalLengthKey:MPMilliseconds(endSession.length),
                                          kMPEventCounterKey:@(endSession.eventCounter)}
                                        mutableCopy];
    
    NSDictionary *sessionAttributesDictionary = [endSession.attributesDictionary transformValuesToString];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    MPMessage *message = [persistence fetchSessionEndMessageInSession:endSession];
    
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:endSession messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:endSession.endTime] build];
        
        [self saveMessage:message updateSession:NO];
    }
    
    [persistence archiveSession:endSession completionHandler:nil];
    
    __weak MPBackendController *weakSelf = self;
    
    [self requestConfig:^(BOOL uploadBatch) {
        if (!uploadBatch) {
            return;
        }
        
        __strong MPBackendController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf uploadBatchesFromSession:endSession
                           completionHandler:^(MPSession *uploadedSession) {
                               if (!strongSelf) {
                                   return;
                               }
                               
                               [strongSelf uploadSessionHistory:uploadedSession completionHandler:nil];
                           }];
    }];
    
    [self broadcastSessionDidEnd:endSession];
    _session = nil;
    
    MPILogVerbose(@"Session Ended: %@", endSession.uuid);
}

- (void)beginTimedEvent:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Timed events cannot begin prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            [event beginTiming];
            [self.eventSet addObject:event];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf beginTimedEvent:event attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(event, execStatus);
}

- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error {
    return [self checkAttribute:attributesDictionary key:key value:value maxValueLength:LIMIT_ATTR_LENGTH error:error];
}

- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error {
    static NSString *attributeValidationErrorDomain = @"Attribute Validation";
    NSString *errorMessage = nil;
    Class NSStringClass = [NSString class];
    
    if (!value) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'value' parameter is invalid.";
    }
    
    if ([value isKindOfClass:NSStringClass]) {
        if ([value isEqualToString:@""]) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kEmptyValueAttribute userInfo:nil];
            }
            
            errorMessage = @"The 'value' parameter is an empty string.";
        }
        
        if (((NSString *)value).length > maxValueLength) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = [NSString stringWithFormat:@"The parameter: %@ is longer than the maximum allowed.", value];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *values = (NSArray *)value;
        if (values.count > MAX_USER_ATTR_LIST_SIZE) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = @"The 'values' parameter contains more entries than the maximum allowed.";
        }

        if (!errorMessage) {
            for (id entryValue in values) {
                if (![entryValue isKindOfClass:NSStringClass]) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidDataType userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"All user attribute entries in the array must be of type string. Error entry: %@", entryValue];
                    
                    break;
                } else if (((NSString *)entryValue).length > maxValueLength) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"The values entry: %@ is longer than the maximum allowed.", entryValue];
                    
                    break;
                }
            }
        }
    }
    
    if (attributesDictionary.count >= LIMIT_ATTR_COUNT) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededNumberOfAttributesLimit userInfo:nil];
        }
        
        errorMessage = @"There are more attributes than the maximum number allowed.";
    }

    if (MPIsNull(key)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter cannot be nil.";
    } else if (key.length > LIMIT_NAME) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededKeyMaximumLength userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter is longer than the maximum allowed length.";
    }

    if (errorMessage == nil) {
        return YES;
    } else {
        MPILogError(@"%@", errorMessage);
        return NO;
    }
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Cannot fetch event name prior to starting the mParticle SDK.\n****\n");
    
    if (_initializationStatus != MPInitializationStatusStarted) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (MPExecStatus)fetchSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(void (^)(NSArray *segments, NSTimeInterval elapsedTime, NSError *error))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Segments cannot be fetched prior to starting the mParticle SDK.\n****\n");
    
    if (self.networkCommunication.retrievingSegments) {
        return MPExecStatusDataBeingFetched;
    }
    
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    
    NSArray *(^validSegments)(NSArray *segments) = ^(NSArray *segments) {
        NSMutableArray *validSegments = [[NSMutableArray alloc] initWithCapacity:segments.count];
        
        for (MPSegment *segment in segments) {
            if (!segment.expired && (endpointId == nil || [segment.endpointIds containsObject:endpointId])) {
                [validSegments addObject:segment];
            }
        }
        
        if (validSegments.count == 0) {
            validSegments = nil;
        }
        
        return [validSegments copy];
    };
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.networkCommunication requestSegmentsWithTimeout:timeout
                                        completionHandler:^(BOOL success, NSArray *segments, NSTimeInterval elapsedTime, NSError *error) {
                                            if (!error) {
                                                if (success && segments.count > 0) {
                                                    [persistence deleteSegments];
                                                }
                                                
                                                for (MPSegment *segment in segments) {
                                                    [persistence saveSegment:segment];
                                                }
                                                
                                                completionHandler(validSegments(segments), elapsedTime, error);
                                            } else {
                                                MPNetworkError networkError = (MPNetworkError)error.code;
                                                
                                                switch (networkError) {
                                                    case MPNetworkErrorTimeout: {
                                                        NSArray *persistedSegments = [persistence fetchSegments];
                                                        completionHandler(validSegments(persistedSegments), timeout, nil);
                                                    }
                                                        break;
                                                        
                                                    case MPNetworkErrorDelayedSegemnts:
                                                        if (success && segments.count > 0) {
                                                            [persistence deleteSegments];
                                                        }
                                                        
                                                        for (MPSegment *segment in segments) {
                                                            [persistence saveSegment:segment];
                                                        }
                                                        break;
                                                }
                                            }
                                        }];
    
    return MPExecStatusSuccess;
}

- (NSString *)execStatusDescription:(MPExecStatus)execStatus {
    if (execStatus >= execStatusDescriptions.count) {
        return nil;
    }
    
    NSString *description = execStatusDescriptions[execStatus];
    return description;
}

- (NSNumber *)incrementSessionAttribute:(MPSession *)session key:(NSString *)key byValue:(NSNumber *)value {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Incrementing session attribute cannot happen prior to starting the mParticle SDK.\n****\n");
    
    if (!session) {
        return nil;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    id currentValue = session.attributesDictionary[localKey];
    if (!currentValue && [value isKindOfClass:[NSNumber class]]) {
        [self setSessionAttribute:session key:localKey value:value];
        return value;
    }

    if (![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    session.attributesDictionary[localKey] = newValue;
    
    [[MPPersistenceController sharedInstance] updateSession:session];
    
    return (NSNumber *)newValue;
}

- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSNumber class]], @"'value' must be a number.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Incrementing user attribute cannot happen prior to starting the mParticle SDK.\n****\n");
    
    NSString *localKey = [self.userAttributes caseInsensitiveKey:key];
    if (!localKey) {
        [self setUserAttribute:key value:value attempt:0 completionHandler:nil];
        return value;
    }
    
    id currentValue = self.userAttributes[localKey];
    if (currentValue && ![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    } else if (MPIsNull(currentValue)) {
        currentValue = @0;
    }
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    self.userAttributes[localKey] = newValue;
    
    NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] initWithCapacity:self.userAttributes.count];
    NSEnumerator *attributeEnumerator = [self.userAttributes keyEnumerator];
    NSString *aKey;
    
    while ((aKey = [attributeEnumerator nextObject])) {
        if ((NSNull *)self.userAttributes[aKey] == [NSNull null]) {
            userAttributes[aKey] = kMPNullUserAttributeString;
        } else {
            userAttributes[aKey] = self.userAttributes[aKey];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        userDefaults[kMPUserAttributeKey] = userAttributes;
        [userDefaults synchronize];
    });
    
    return (NSNumber *)newValue;
}

- (void)leaveBreadcrumb:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Breadcrumbs cannot be left prior to starting the mParticle SDK.\n****\n");
    
    event.messageType = MPMessageTypeBreadcrumb;
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            NSDictionary *messageInfo = [event breadcrumbDictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
            if (event.timestamp) {
                [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
            }
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            if ([self.eventSet containsObject:event]) {
                [_eventSet removeObject:event];
            }
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!event.timestamp) {
                event.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf leaveBreadcrumb:event attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(event, execStatus);
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent attempt:(NSUInteger)attempt completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Commerce Events cannot be logged prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(commerceEvent, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCommerceEvent session:self.session commerceEvent:commerceEvent];
            if (commerceEvent.timestamp) {
                [messageBuilder withTimestamp:[commerceEvent.timestamp timeIntervalSince1970]];
            }
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            [self.session incrementCounter];
            
            // Update cart
            NSArray *products = nil;
            if (commerceEvent.action == MPCommerceEventActionAddToCart) {
                products = [commerceEvent addedProducts];
                
                if (products) {
                    [[MPCart sharedInstance] addProducts:products logEvent:NO updateProductList:YES];
                    [commerceEvent resetLatestProducts];
                } else {
                    MPILogWarning(@"Commerce event products were not added to the cart.");
                }
            } else if (commerceEvent.action == MPCommerceEventActionRemoveFromCart) {
                products = [commerceEvent removedProducts];
                
                if (products) {
                    [[MPCart sharedInstance] removeProducts:products logEvent:NO updateProductList:YES];
                    [commerceEvent resetLatestProducts];
                } else {
                    MPILogWarning(@"Commerce event products were not removed from the cart.");
                }
            }
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!commerceEvent.timestamp) {
                commerceEvent.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logCommerceEvent:commerceEvent attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(commerceEvent, execStatus);
}

- (void)logError:(NSString *)message exception:(NSException *)exception topmostContext:(id)topmostContext eventInfo:(NSDictionary *)eventInfo attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *message, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Errors or exceptions cannot be logged prior to starting the mParticle SDK.\n****\n");
    
    NSString *execMessage = exception ? exception.name : message;
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(execMessage, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            NSMutableDictionary *messageInfo = [@{kMPCrashWasHandled:@"true",
                                                  kMPCrashingSeverity:@"error"}
                                                mutableCopy];
            
            if (exception) {
                NSData *liveExceptionReportData = [MPExceptionHandler generateLiveExceptionReport];
                if (liveExceptionReportData) {
                    messageInfo[kMPPLCrashReport] = [liveExceptionReportData base64EncodedStringWithOptions:0];
                }
                
                messageInfo[kMPErrorMessage] = exception.reason;
                messageInfo[kMPCrashingClass] = exception.name;
                
                NSArray *callStack = [exception callStackSymbols];
                if (callStack) {
                    messageInfo[kMPStackTrace] = [callStack componentsJoinedByString:@"\n"];
                }
                
                NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [[MPPersistenceController sharedInstance] fetchBreadcrumbs];
                if (fetchedbreadcrumbs) {
                    NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
                    for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
                        [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
                    }
                    
                    NSString *messageTypeBreadcrumbKey = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding];
                    messageInfo[messageTypeBreadcrumbKey] = breadcrumbs;
                    
                    NSNumber *sessionNumber = self.session.sessionNumber;
                    if (sessionNumber) {
                        messageInfo[kMPSessionNumberKey] = sessionNumber;
                    }
                }
            } else {
                messageInfo[kMPErrorMessage] = message;
            }
            
            if (topmostContext) {
                messageInfo[kMPTopmostContext] = [[topmostContext class] description];
            }
            
            if (eventInfo.count > 0) {
                messageInfo[kMPAttributesKey] = eventInfo;
            }
            
            NSDictionary *appImageInfo = [MPExceptionHandler appImageInfo];
            if (appImageInfo) {
                [messageInfo addEntriesFromDictionary:appImageInfo];
            }
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *errorMessage = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:errorMessage updateSession:YES];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logError:message exception:exception topmostContext:topmostContext eventInfo:eventInfo attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(execMessage, execStatus);
}

- (void)logEvent:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Events cannot be logged prior to starting the mParticle SDK.\n****\n");
    
    event.messageType = MPMessageTypeEvent;
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            [event endTiming];
            
            NSDictionary<NSString *, id> *messageInfo = [event dictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
            if (event.timestamp) {
                [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
            }
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            if ([self.eventSet containsObject:event]) {
                [_eventSet removeObject:event];
            }
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!event.timestamp) {
                event.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logEvent:event attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(event, execStatus);
}

- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance attempt:(NSUInteger)attempt completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Network performance measurement cannot be logged prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        if (completionHandler) {
            completionHandler(networkPerformance, MPExecStatusFail);
        }
        
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            NSDictionary *messageInfo = [networkPerformance dictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeNetworkPerformance session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logNetworkPerformanceMeasurement:networkPerformance attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    if (completionHandler) {
        completionHandler(networkPerformance, execStatus);
    }
}

- (void)logScreen:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Screens cannot be logged prior to starting the mParticle SDK.\n****\n");
    
    event.messageType = MPMessageTypeScreenView;
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            [event endTiming];
            
            if (event.type != MPEventTypeNavigation) {
                event.type = MPEventTypeNavigation;
            }
            
            NSDictionary *messageInfo = [event screenDictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
            if (event.timestamp) {
                [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
            }
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            if ([self.eventSet containsObject:event]) {
                [_eventSet removeObject:event];
            }
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            if (!event.timestamp) {
                event.timestamp = [NSDate date];
            }
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logScreen:event attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(event, execStatus);
}

- (void)profileChange:(MPProfileChange)profile attempt:(NSUInteger)attempt completionHandler:(void (^)(MPProfileChange profile, MPExecStatus execStatus))completionHandler {
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(profile, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            NSDictionary *profileChangeDictionary = nil;
            
            switch (profile) {
                case MPProfileChangeLogout:
                    profileChangeDictionary = @{kMPProfileChangeTypeKey:@"logout"};
                    break;
                    
                default:
                    return;
                    break;
            }
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeProfile session:self.session messageInfo:profileChangeDictionary];
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf profileChange:profile attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(profile, execStatus);
}

- (void)setOptOut:(BOOL)optOutStatus attempt:(NSUInteger)attempt completionHandler:(void (^)(BOOL optOut, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting opt out cannot happen prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(optOutStatus, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            [MPStateMachine sharedInstance].optOut = optOutStatus;
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeOptOut session:self.session messageInfo:@{kMPOptOutStatus:(optOutStatus ? @"true" : @"false")}];
#if TARGET_OS_IOS == 1
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            if (optOutStatus) {
                [self endSession];
            }
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setOptOut:optOutStatus attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(optOutStatus, execStatus);
}

- (MPExecStatus)setSessionAttribute:(MPSession *)session key:(NSString *)key value:(id)value {
    NSAssert(session != nil, @"session cannot be nil.");
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]], @"'value' must be a string or number.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting session attribute cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (!session) {
        return MPExecStatusMissingParam;
    } else if (![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSNumber class]]) {
        return MPExecStatusInvalidDataType;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    NSError *error = nil;
    BOOL validAttributes = [self checkAttribute:session.attributesDictionary key:localKey value:value error:&error];
    if (!validAttributes || [session.attributesDictionary[localKey] isEqual:value]) {
        return MPExecStatusInvalidDataType;
    }
    
    session.attributesDictionary[localKey] = value;
    
    [[MPPersistenceController sharedInstance] updateSession:session];
    
    return MPExecStatusSuccess;
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate registerForSilentNotifications:(BOOL)registerForSilentNotifications completionHandler:(dispatch_block_t)completionHandler {
    sdkIsLaunching = YES;
    _initializationStatus = MPInitializationStatusStarting;
    
    if (proxyAppDelegate) {
        [self proxyOriginalAppDelegate];
    }
    
#if TARGET_OS_IOS == 1
    if (registerForSilentNotifications) {
        [self.notificationController registerForSilentNotifications];
    }
#endif
    
    [MPKitContainer sharedInstance];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = apiKey;
    stateMachine.secret = secret;
    stateMachine.installationType = installationType;
    [MPStateMachine setRunningInBackground:NO];

    [MPURLRequestBuilder tryToCaptureUserAgent];
    
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(backendQueue, ^{
        void (^initializeSDK)() = ^{
            static dispatch_once_t initializationToken;
            
            dispatch_once(&initializationToken, ^{
                _initializationStatus = MPInitializationStatusStarted;
                MPILogDebug(@"SDK %@ has started", kMParticleSDKVersion);
                
                if (firstRun) {
                    [self uploadWithCompletionHandler:nil];
                }
            });
        };
        
        __strong MPBackendController *strongSelf = weakSelf;

        [stateMachine.searchAttribution requestAttributionDetailsWithBlock:^{
            if (firstRun) {
                MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeFirstRun session:strongSelf.session messageInfo:nil];
                MPMessage *message = (MPMessage *)[messageBuilder build];
                message.uploadStatus = MPUploadStatusBatch;
                
                [strongSelf saveMessage:message updateSession:YES];
                [strongSelf uploadWithCompletionHandler:nil];

                MPILogDebug(@"Application First Run");
            }
            
            [strongSelf processPendingUploads];
            [strongSelf processOpenSessionsIncludingCurrent:NO completionHandler:^(BOOL success) {}];
            [strongSelf processDidFinishLaunching:strongSelf->didFinishLaunchingNotification];
            
            initializeSDK();
            
            [strongSelf beginUploadTimer];
        }];
        
        [strongSelf processPendingArchivedMessages];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            initializeSDK();
            
            [MPResponseConfig restore];
            
            completionHandler();
        });
    });
}

- (void)saveMessage:(MPDataModelAbstract *)abstractMessage updateSession:(BOOL)updateSession {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    if ([abstractMessage isKindOfClass:[MPMessage class]]) {
        MPMessage *message = (MPMessage *)abstractMessage;
        MPMessageType messageTypeCode = (MPMessageType)mParticle::MessageTypeName::messageTypeForName(string([message.messageType UTF8String]));
        if (messageTypeCode == MPMessageTypeBreadcrumb) {
            [persistence saveBreadcrumb:message session:self.session];
        } else {
            [persistence saveMessage:message];
        }
        
        MPILogVerbose(@"Source Event Id: %@", message.uuid);
        
        if (updateSession) {
            if (self.session.persisted) {
                self.session.endTime = [[NSDate date] timeIntervalSince1970];
                [persistence updateSession:self.session];
            } else {
                [persistence saveSession:self.session];
            }
        }
        
        __weak MPBackendController *weakSelf = self;
        dispatch_async(backendQueue, ^{
            MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
            BOOL shouldUpload = [stateMachine.triggerMessageTypes containsObject:message.messageType];
            
            if (!shouldUpload && stateMachine.triggerEventTypes) {
                NSError *error = nil;
                NSDictionary *messageDictionary = [message dictionaryRepresentation];
                NSString *eventName = messageDictionary[kMPEventNameKey];
                NSString *eventType = messageDictionary[kMPEventTypeKey];
                
                if (!error && eventName && eventType) {
                    NSString *hashedEvent = [NSString stringWithCString:mParticle::Hasher::hashEvent([eventName cStringUsingEncoding:NSUTF8StringEncoding], [eventType cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                               encoding:NSUTF8StringEncoding];
                    
                    shouldUpload = [stateMachine.triggerEventTypes containsObject:hashedEvent];
                }
            }
            
            if (shouldUpload) {
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf uploadWithCompletionHandler:nil];
            }
        });
    } else if ([abstractMessage isKindOfClass:[MPStandaloneMessage class]]) {
        [persistence saveStandaloneMessage:(MPStandaloneMessage *)abstractMessage];
        [self uploadWithCompletionHandler:nil];
    }
}

- (MPExecStatus)uploadWithCompletionHandler:(void (^ _Nullable)())completionHandler {
    if (_initializationStatus != MPInitializationStatusStarted) {
        if (completionHandler) {
            completionHandler();
        }
        
        return MPExecStatusDelayedExecution;
    }
    
    __weak MPBackendController *weakSelf = self;
    dispatch_block_t uploadTask = ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        [strongSelf requestConfig:^(BOOL uploadBatch) {
            if (!uploadBatch) {
                if (completionHandler) {
                    completionHandler();
                }
                
                return;
            }
            
            MPSession *session = strongSelf->_session;
            MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
            BOOL shouldTryToUploadSessionMessages = (session != nil) ? [persistence countMesssagesForUploadInSession:session] > 0 : NO;
            BOOL shouldTryToUploadStandaloneMessages = [persistence countStandaloneMessages] > 0;
            
            if (shouldTryToUploadSessionMessages) {
                [strongSelf uploadBatchesFromSession:session
                                   completionHandler:^(MPSession *uploadedSession) {
                                       if (shouldTryToUploadStandaloneMessages) {
                                           [strongSelf uploadStandaloneMessages];
                                       }
                                       
                                       if (completionHandler) {
                                           completionHandler();
                                       }
                                   }];
            } else if (shouldTryToUploadStandaloneMessages) {
                [strongSelf uploadStandaloneMessages];

                if (completionHandler) {
                    completionHandler();
                }
            }
        }];
    };
    
    if ([NSThread isMainThread]) {
        uploadTask();
    } else {
        dispatch_async(dispatch_get_main_queue(), uploadTask);
    }
    
    return MPExecStatusSuccess;
}

- (void)setUserAttribute:(NSString *)key value:(id)value attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    NSAssert(validKey, @"'key' must be a string.");
    NSAssert(value == nil || (value != nil && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])), @"'value' must be either nil, string, or number.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user attribute cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[self.userAttributes copy] key:keyCopy value:value];
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted:
            [self setUserAttributeChange:userAttributeChange attempt:attempt completionHandler:completionHandler];
            break;
            
        case MPInitializationStatusStarting: {
            userAttributeChange.timestamp = [NSDate date];

            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserAttributeChange:userAttributeChange attempt:(attempt + 1) completionHandler:completionHandler];
            });
        }
            break;
            
        case MPInitializationStatusNotStarted: {
            if (completionHandler) {
                completionHandler(keyCopy, value, MPExecStatusSDKNotStarted);
            }
        }
            break;
    }
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values attempt:(NSUInteger)attempt completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    NSAssert(validKey, @"'key' must be a string.");
    NSAssert(values == nil || (values != nil && ([values isKindOfClass:[NSArray class]])), @"'values' must be either nil or array.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user attribute cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[self.userAttributes copy] key:keyCopy value:values];
    userAttributeChange.isArray = YES;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted:
            [self setUserAttributeChange:userAttributeChange attempt:attempt completionHandler:completionHandler];
            break;
            
        case MPInitializationStatusStarting: {
            userAttributeChange.timestamp = [NSDate date];
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserAttributeChange:userAttributeChange attempt:(attempt + 1) completionHandler:completionHandler];
            });
        }
            break;
            
        case MPInitializationStatusNotStarted: {
            if (completionHandler) {
                completionHandler(keyCopy, values, MPExecStatusSDKNotStarted);
            }
        }
            break;
    }
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user identity cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(identityString, identityType, MPExecStatusFail);
        return;
    }
    
    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:identityType
                                                                                     value:identityString];
    
    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew userIdentities:self.userIdentities];
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted:
            [self setUserIdentityChange:userIdentityChange attempt:attempt completionHandler:completionHandler];
            break;
            
        case MPInitializationStatusStarting: {
            userIdentityChange.timestamp = [NSDate date];
            
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserIdentityChange:userIdentityChange attempt:(attempt + 1) completionHandler:completionHandler];
            });
        }
            break;
            
        case MPInitializationStatusNotStarted:
            completionHandler(identityString, identityType, MPExecStatusSDKNotStarted);
            break;
    }
}

#if TARGET_OS_IOS == 1
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    NSAssert(self.initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Location tracking cannot begin prior to starting the mParticle SDK.\n****\n");
    
    if ([[MPStateMachine sharedInstance].locationTrackingMode isEqualToString:kMPRemoteConfigForceFalse]) {
        return MPExecStatusDisabledRemotely;
    }
    
    MPLocationManager *locationManager = [[MPLocationManager alloc] initWithAccuracy:accuracy distanceFilter:distance authorizationRequest:authorizationRequest];
    [MPStateMachine sharedInstance].locationManager = locationManager ? : nil;
    
    return MPExecStatusSuccess;
}

- (MPExecStatus)endLocationTracking {
    NSAssert(self.initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Location tracking cannot end prior to starting the mParticle SDK.\n****\n");
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if ([stateMachine.locationTrackingMode isEqualToString:kMPRemoteConfigForceTrue]) {
        return MPExecStatusEnabledRemotely;
    }
    
    [stateMachine.locationManager endLocationTracking];
    stateMachine.locationManager = nil;
    
    return MPExecStatusSuccess;
}

- (MPNotificationController *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    [self willChangeValueForKey:@"notificationController"];
    _notificationController = [[MPNotificationController alloc] initWithDelegate:self];
    [self didChangeValueForKey:@"notificationController"];
    
    return _notificationController;
}

- (void)setNotificationController:(MPNotificationController *)notificationController {
    _notificationController = notificationController;
}

- (void)handleDeviceTokenNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSData *deviceToken = userInfo[kMPRemoteNotificationDeviceTokenKey];
    NSData *oldDeviceToken = userInfo[kMPRemoteNotificationOldDeviceTokenKey];
    
    if ((!deviceToken && !oldDeviceToken) || [deviceToken isEqualToData:oldDeviceToken]) {
        return;
    }
    
    NSData *logDeviceToken;
    NSString *status;
    BOOL pushNotificationsEnabled = deviceToken != nil;
    if (pushNotificationsEnabled) {
        logDeviceToken = deviceToken;
        status = @"true";
    } else if (!pushNotificationsEnabled && oldDeviceToken) {
        logDeviceToken = oldDeviceToken;
        status = @"false";
    }
    
    NSMutableDictionary *messageInfo = [@{kMPDeviceTokenKey:[NSString stringWithFormat:@"%@", logDeviceToken],
                                          kMPPushStatusKey:status}
                                        mutableCopy];
    
    UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    NSUInteger notificationTypes = userNotificationSettings.types;
    messageInfo[kMPDeviceSupportedPushNotificationTypesKey] = @(notificationTypes);
    
    if ([MPStateMachine sharedInstance].deviceTokenType.length > 0) {
        messageInfo[kMPDeviceTokenTypeKey] = [MPStateMachine sharedInstance].deviceTokenType;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushRegistration session:self.session messageInfo:messageInfo];
    MPDataModelAbstract *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
    
    if (deviceToken) {
        MPILogDebug(@"Set Device Token: %@", deviceToken);
    } else {
        MPILogDebug(@"Reset Device Token: %@", oldDeviceToken);
    }
}

#pragma mark MPNotificationControllerDelegate
- (void)receivedUserNotification:(MParticleUserNotification *)userNotification {
    switch (userNotification.command) {
        case MPUserNotificationCommandAlertUserLocalTime:
            [self.notificationController scheduleNotification:userNotification];
            break;
            
        case MPUserNotificationCommandConfigRefresh:
            [self requestConfig:nil];
            break;
            
            
        case MPUserNotificationCommandDoNothing:
            return;
            break;
            
        default:
            break;
    }
    
    if (userNotification.shouldPersist) {
        if (userNotification.userNotificationId) {
            [[MPPersistenceController sharedInstance] updateUserNotification:userNotification];
        } else {
            [[MPPersistenceController sharedInstance] saveUserNotification:userNotification];
        }
    }
    
    NSMutableDictionary *messageInfo = [@{kMPDeviceTokenKey:[NSString stringWithFormat:@"%@", [MPNotificationController deviceToken]],
                                          kMPPushNotificationStateKey:userNotification.state,
                                          kMPPushMessageProviderKey:kMPPushMessageProviderValue,
                                          kMPPushMessageTypeKey:userNotification.type}
                                        mutableCopy];
    
    if (userNotification.redactedUserNotificationString) {
        messageInfo[kMPPushMessagePayloadKey] = userNotification.redactedUserNotificationString;
    }
    
    if (userNotification.actionIdentifier) {
        messageInfo[kMPPushNotificationActionIdentifierKey] = userNotification.actionIdentifier;
        messageInfo[kMPPushNotificationCategoryIdentifierKey] = userNotification.categoryIdentifier;
    }
    
    if (userNotification.actionTitle) {
        messageInfo[kMPPushNotificationActionTileKey] = userNotification.actionTitle;
    }
    
    if (userNotification.behavior > 0) {
        messageInfo[kMPPushNotificationBehaviorKey] = @(userNotification.behavior);
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:_session messageInfo:messageInfo];
    messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].location];
    MPDataModelAbstract *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:(_session != nil)];
}
#endif

@end
