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
#import "MPMediaTrackContainer.h"
#import "MPMediaTrack.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPHasher.h"
#import "MediaControl.h"
#import "MPMediaTrack+Internal.h"
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
    dispatch_queue_t backendQueue;
    dispatch_queue_t notificationsQueue;
    NSTimeInterval nextCleanUpTime;
    NSTimeInterval timeAppWentToBackground;
    NSTimeInterval backgroundStartTime;
    dispatch_source_t backgroundSource;
    dispatch_source_t uploadSource;
    UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
    BOOL sdkIsLaunching;
    BOOL longSession;
    BOOL originalAppDelegateProxied;
    BOOL resignedActive;
    BOOL retrievingSegments;
}

@property (nonatomic, strong) MPMediaTrackContainer *mediaTrackContainer;
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

- (MPMediaTrackContainer *)mediaTrackContainer {
    if (_mediaTrackContainer) {
        return _mediaTrackContainer;
    }
    
    [self willChangeValueForKey:@"mediaTrackContainer"];
    _mediaTrackContainer = [[MPMediaTrackContainer alloc] initWithCapacity:1];
    [self didChangeValueForKey:@"mediaTrackContainer"];
    
    return _mediaTrackContainer;
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
    if (_session) {
        return _session;
    }
    
    [self beginSession:nil];
    
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
- (NSDictionary *)attributesDictionaryForSession:(MPSession *)session {
    NSUInteger attributeCount = session.attributesDictionary.count;
    if (attributeCount == 0) {
        return nil;
    }
    
    NSMutableDictionary *attributesDictionary = [[NSMutableDictionary alloc] initWithCapacity:attributeCount];
    NSEnumerator *attributeEnumerator = [session.attributesDictionary keyEnumerator];
    NSString *key;
    id value;
    Class NSNumberClass = [NSNumber class];
    
    while ((key = [attributeEnumerator nextObject])) {
        value = session.attributesDictionary[key];
        attributesDictionary[key] = [value isKindOfClass:NSNumberClass] ? [(NSNumber *)value stringValue] : value;
    }
    
    return [attributesDictionary copy];
}

- (void)beginBackgroundTask {
    __weak MPBackendController *weakSelf = self;
    
    if (backendBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        backendBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            __strong MPBackendController *strongSelf = weakSelf;
            
            [MPStateMachine setRunningInBackground:NO];
            [[MPPersistenceController sharedInstance] purgeMemory];
            MPILogDebug(@"SDK has become dormant with the app.");
            
            if (strongSelf) {
                [strongSelf endBackgroundTimer];
                
                strongSelf->_networkCommunication = nil;
                
                if (strongSelf->_session) {
                    [strongSelf broadcastSessionDidEnd:strongSelf->_session];
                    strongSelf->_session = nil;
                    
                    if (strongSelf.eventSet.count == 0) {
                        strongSelf->_eventSet = nil;
                    }
                    
                    if (strongSelf.mediaTrackContainer.count == 0) {
                        strongSelf->_mediaTrackContainer = nil;
                    }
                }
                
                [[UIApplication sharedApplication] endBackgroundTask:strongSelf->backendBackgroundTaskIdentifier];
                strongSelf->backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
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
    [self.mediaTrackContainer pruneMediaTracks];
    
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
    
    if (!openSessions || openSessions.count == 0) {
        [persistence deleteMessagesWithNoSession];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES);
        });
        
        return;
    }
    
    __block MPSession *session = [openSessions[0] copy];
    [openSessions removeObjectAtIndex:0];
    NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(session.foregroundTime),
                                          kMPSessionTotalLengthKey:MPMilliseconds(session.length)}
                                        mutableCopy];
    
    NSDictionary *sessionAttributesDictionary = [self attributesDictionaryForSession:session];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        if ([MPLocationManager trackingLocation]) {
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
        }
#endif
        message = (MPMessage *)[[messageBuilder withTimestamp:session.endTime] build];
        
        [self saveMessage:message updateSession:NO];
        MPILogVerbose(@"Session Ended: %@", session.uuid);
    }
    
    __weak MPBackendController *weakSelf = self;
    
    [self requestConfig:^(BOOL uploadBatch) {
        if (!uploadBatch) {
            return;
        }
        
        __strong MPBackendController *strongSelf = weakSelf;
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        BOOL shouldTryToUploadSessionMessages = (session != nil) ? [persistence countMesssagesForUploadInSession:session] > 0 : NO;
        
        if (shouldTryToUploadSessionMessages) {
            [strongSelf uploadBatchesFromSession:session
                               completionHandler:^(MPSession *uploadedSession) {
                                   session = nil;
                                   
                                   if (uploadedSession) {
                                       [self uploadSessionHistory:uploadedSession completionHandler:^(BOOL sessionHistorySuccess) {
                                           if (sessionHistorySuccess) {
                                               [self uploadOpenSessions:openSessions completionHandler:completionHandler];
                                           } else {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   completionHandler(NO);
                                               });
                                           }
                                       }];
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           completionHandler(NO);
                                       });
                                   }
                               }];
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
    
    appBackgrounded = YES;
    [MPStateMachine setRunningInBackground:YES];
    
    timeAppWentToBackground = [[NSDate date] timeIntervalSince1970];
    
    [self setPreviousSessionSuccessfullyClosed:@YES];
    [self cleanUp];
    [self endUploadTimer];
    
    NSMutableDictionary *messageInfo = [@{kMPAppStateTransitionType:kMPASTBackgroundKey} mutableCopy];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
    if ([MPLocationManager trackingLocation]) {
        if (![MPStateMachine sharedInstance].locationManager.backgroundLocationTracking) {
            [[MPStateMachine sharedInstance].locationManager.locationManager stopUpdatingLocation];
        }
        
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
    }
#endif
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    [self.session suspendSession];
    [self saveMessage:message updateSession:YES];
    
    MPILogVerbose(@"Application Did Enter Background");
    
    [self upload];
    [self beginBackgroundTimer];
    [self beginBackgroundTask];
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
    dispatch_async(dispatch_get_main_queue(), ^{
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
        if ([MPLocationManager trackingLocation]) {
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
        }
#endif
        messageBuilder = [messageBuilder withStateTransition:sessionFinalized previousSession:nil];
        MPMessage *message = (MPMessage *)[messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
        
        MPILogVerbose(@"Application Did Finish Launching");
    });
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:_session messageInfo:@{kMPAppStateTransitionType:kMPASTExitKey}];
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:archivedMessagesDirectoryPath]) {
        [fileManager createDirectoryAtPath:archivedMessagesDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *messagePath = [archivedMessagesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%.0f.arcmsg", message.uuid, message.timestamp]];
    BOOL messageArchived = [NSKeyedArchiver archiveRootObject:message toFile:messagePath];
    if (!messageArchived) {
        MPILogError(@"Application Will Terminate message not archived.");
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    if (persistence.databaseOpen) {
        if (_session) {
            _session.endTime = [[NSDate date] timeIntervalSince1970];
            [persistence updateSession:_session];
        }
        
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
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval backgroundedTime = (currentTime - _session.endTime) > 0 ? (currentTime - _session.endTime) : 0;
    BOOL sessionExpired = backgroundedTime > self.sessionTimeout && !longSession;
    
    void (^appStateTransition)(MPSession *, MPSession *, BOOL) = ^(MPSession *session, MPSession *previousSession, BOOL sessionExpired) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:session messageInfo:@{kMPAppStateTransitionType:kMPASTForegroundKey}];
        messageBuilder = [messageBuilder withStateTransition:sessionExpired previousSession:previousSession];
#if TARGET_OS_IOS == 1
        if ([MPLocationManager trackingLocation]) {
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
        }
#endif
        
        MPMessage *message = (MPMessage *)[messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
        
        MPILogVerbose(@"Application Did Become Active");
    };
    
    if (sessionExpired) {
        [self beginSession:^(MPSession *session, MPSession *previousSession, MPExecStatus execStatus) {
            [self processOpenSessionsIncludingCurrent:NO completionHandler:^(BOOL success) {
                [self beginUploadTimer];
            }];
            
            appStateTransition(session, previousSession, sessionExpired);
        }];
    } else {
        self.session.backgroundTime += currentTime - timeAppWentToBackground;
        timeAppWentToBackground = 0.0;
        _session.endTime = currentTime;
        [[MPPersistenceController sharedInstance] updateSession:_session];
        
        appStateTransition(self.session, nil, sessionExpired);
        [self beginUploadTimer];
    }
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
                                      
                                      if (backgroundTimeRemaining < kMPRemainingBackgroundTimeMinimumThreshold) {
                                          NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                                          
                                          void(^processSession)(NSTimeInterval) = ^(NSTimeInterval timeout) {
                                              dispatch_source_cancel(strongSelf->backgroundSource);
                                              strongSelf->longSession = NO;
                                              
                                              strongSelf.session.backgroundTime += timeout;
                                              
                                              [strongSelf processOpenSessionsIncludingCurrent:YES
                                                                            completionHandler:^(BOOL success) {
                                                                                [MPStateMachine setRunningInBackground:NO];
                                                                                [strongSelf broadcastSessionDidEnd:strongSelf->_session];
                                                                                strongSelf->_session = nil;
                                                                                
                                                                                if (strongSelf.eventSet.count == 0) {
                                                                                    strongSelf->_eventSet = nil;
                                                                                }
                                                                                
                                                                                if (strongSelf.mediaTrackContainer.count == 0) {
                                                                                    strongSelf->_mediaTrackContainer = nil;
                                                                                }
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
                                          longSession = YES;
                                          
                                          if (!uploadSource) {
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
                                                        [strongSelf upload];
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
    
    [self willChangeValueForKey:@"session"];
    
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
        MPMessage *message = (MPMessage *)[[messageBuilder withTimestamp:_session.startTime] build];
        
        [self saveMessage:message updateSession:YES];
        
        if (completionHandler) {
            completionHandler(_session, previousSession, MPExecStatusSuccess);
        }
    }];
    
    [persistence saveSession:_session];
    
    stateMachine.currentSession = _session;
    
    [self didChangeValueForKey:@"session"];
    
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
    
    NSDictionary *sessionAttributesDictionary = [self attributesDictionaryForSession:endSession];
    if (sessionAttributesDictionary) {
        messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    MPMessage *message = [persistence fetchSessionEndMessageInSession:endSession];
    
    if (!message) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:endSession messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
        if ([MPLocationManager trackingLocation]) {
            messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
        }
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
        
        [strongSelf uploadBatchesFromSession:endSession
                           completionHandler:^(MPSession *uploadedSession) {
                               [self uploadSessionHistory:uploadedSession completionHandler:nil];
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
    if (!localKey) {
        [self setSessionAttribute:session key:localKey value:value];
        return value;
    }
    
    id currentValue = session.attributesDictionary[localKey];
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
    if (![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
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
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
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
    
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(backendQueue, ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (firstRun) {
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeFirstRun session:strongSelf.session messageInfo:nil];
            MPMessage *message = (MPMessage *)[messageBuilder build];
            message.uploadStatus = MPUploadStatusBatch;
            
            [strongSelf saveMessage:message updateSession:YES];
            
            MPILogDebug(@"Application First Run");
        }
        
        [strongSelf processPendingArchivedMessages];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf->_initializationStatus = MPInitializationStatusStarted;
            MPILogDebug(@"SDK %@ has started", kMParticleSDKVersion);
            
            [MPResponseConfig restore];
            
            [strongSelf processOpenSessionsIncludingCurrent:NO completionHandler:^(BOOL success) {
                if (firstRun) {
                    [strongSelf upload];
                }
                
                [strongSelf beginUploadTimer];
            }];
            
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
                [strongSelf upload];
            }
        });
    } else if ([abstractMessage isKindOfClass:[MPStandaloneMessage class]]) {
        [persistence saveStandaloneMessage:(MPStandaloneMessage *)abstractMessage];
        [self upload];
    }
}

- (MPExecStatus)upload {
    if (_initializationStatus != MPInitializationStatusStarted) {
        return MPExecStatusDelayedExecution;
    }
    
    __weak MPBackendController *weakSelf = self;
    dispatch_block_t uploadTask = ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        [strongSelf requestConfig:^(BOOL uploadBatch) {
            if (!uploadBatch) {
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
                                   }];
            } else if (shouldTryToUploadStandaloneMessages) {
                [strongSelf uploadStandaloneMessages];
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
    NSString *keyCopy = [key copy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    NSAssert(validKey, @"'key' must be a string.");
    NSAssert(value == nil || (value != nil && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])), @"'value' must be either nil, or string or number.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user attribute cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusFail);
        }
        
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            if ([MPStateMachine sharedInstance].optOut) {
                if (completionHandler) {
                    completionHandler(keyCopy, value, MPExecStatusOptOut);
                }
                
                return;
            }
            
            if (value && ![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSNumber class]]) {
                if (completionHandler) {
                    completionHandler(keyCopy, value, MPExecStatusInvalidDataType);
                }
                
                return;
            }
            
            NSString *localKey = [self.userAttributes caseInsensitiveKey:keyCopy];
            NSError *error = nil;
            BOOL validAttributes = [self checkAttribute:self.userAttributes key:localKey value:value maxValueLength:LIMIT_USER_ATTR_LENGTH error:&error];
            
            id<NSObject> userAttributeValue;
            if (!validAttributes && error.code == kInvalidValue) {
                userAttributeValue = [NSNull null];
                validAttributes = YES;
                error = nil;
            } else {
                userAttributeValue = value;
            }
            
            if (validAttributes) {
                self.userAttributes[localKey] = userAttributeValue;
            } else if (error.code == kEmptyValueAttribute && self.userAttributes[localKey]) {
                [self.userAttributes removeObjectForKey:localKey];
                
                if (!deletedUserAttributes) {
                    deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
                }
                [deletedUserAttributes addObject:keyCopy];
            } else {
                if (completionHandler) {
                    completionHandler(keyCopy, value, MPExecStatusInvalidDataType);
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                userDefaults[kMPUserAttributeKey] = userAttributes;
                [userDefaults synchronize];
            });
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserAttribute:keyCopy value:value attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    if (completionHandler) {
        completionHandler(keyCopy, value, execStatus);
    }
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values attempt:(NSUInteger)attempt completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key copy];
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
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusFail);
        }
        
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            if ([MPStateMachine sharedInstance].optOut) {
                if (completionHandler) {
                    completionHandler(keyCopy, values, MPExecStatusOptOut);
                }
                
                return;
            }
            
            if (values && ![values isKindOfClass:[NSArray class]]) {
                if (completionHandler) {
                    completionHandler(keyCopy, nil, MPExecStatusInvalidDataType);
                }
                
                return;
            }
            
            NSString *localKey = [self.userAttributes caseInsensitiveKey:keyCopy];
            NSError *error = nil;
            BOOL validAttributes = [self checkAttribute:self.userAttributes key:localKey value:values maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];

            if (validAttributes) {
                self.userAttributes[localKey] = values;
            } else if (error.code == kInvalidValue && self.userAttributes[localKey]) {
                [self.userAttributes removeObjectForKey:localKey];
                
                if (!deletedUserAttributes) {
                    deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
                }
                [deletedUserAttributes addObject:keyCopy];
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                userDefaults[kMPUserAttributeKey] = userAttributes;
                [userDefaults synchronize];
            });
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserAttribute:keyCopy values:values attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    if (completionHandler) {
        completionHandler(keyCopy, values, execStatus);
    }
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Setting user identity cannot be done prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(identityString, identityType, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            NSNumber *identityTypeNumnber = @(identityType);
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", kMPUserIdentityTypeKey, identityTypeNumnber];
            NSDictionary *userIdentity = [[self.userIdentities filteredArrayUsingPredicate:predicate] lastObject];
            
            if (userIdentity &&
                [[userIdentity[kMPUserIdentityIdKey] lowercaseString] isEqualToString:[identityString lowercaseString]] &&
                ![userIdentity[kMPUserIdentityIdKey] isEqualToString:identityString])
            {
                return;
            }
            
            BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
                NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
                BOOL foundMatch = [currentIdentityType isEqualToNumber:identityTypeNumnber];
                
                if (foundMatch) {
                    *stop = YES;
                }
                
                return foundMatch;
            };
            
            NSUInteger existingEntryIndex;
            BOOL persistUserIdentities = NO;
            if (identityString == nil || [identityString isEqualToString:@""]) {
                existingEntryIndex = [self.userIdentities indexOfObjectPassingTest:objectTester];
                
                if (existingEntryIndex != NSNotFound) {
                    [self.userIdentities removeObjectAtIndex:existingEntryIndex];
                    persistUserIdentities = YES;
                }
            } else {
                NSMutableDictionary *identityDictionary = [NSMutableDictionary dictionary];
                identityDictionary[kMPUserIdentityTypeKey] = identityTypeNumnber;
                identityDictionary[kMPUserIdentityIdKey] = identityString;
                
                NSError *error = nil;
                if ([self checkAttribute:identityDictionary key:kMPUserIdentityIdKey value:identityString error:&error] &&
                    [self checkAttribute:identityDictionary key:kMPUserIdentityTypeKey value:[identityTypeNumnber stringValue] error:&error]) {
                    
                    existingEntryIndex = [self.userIdentities indexOfObjectPassingTest:objectTester];
                    
                    if (existingEntryIndex == NSNotFound) {
                        identityDictionary[kMPDateUserIdentityWasFirstSet] = MPCurrentEpochInMilliseconds;
                        identityDictionary[kMPIsFirstTimeUserIdentityHasBeenSet] = @YES;
                        
                        [self.userIdentities addObject:identityDictionary];
                    } else {
                        NSDictionary *userIdentity = self.userIdentities[existingEntryIndex];
                        identityDictionary[kMPDateUserIdentityWasFirstSet] = userIdentity[kMPDateUserIdentityWasFirstSet] ? userIdentity[kMPDateUserIdentityWasFirstSet] : MPCurrentEpochInMilliseconds;
                        identityDictionary[kMPIsFirstTimeUserIdentityHasBeenSet] = @NO;
                        
                        [self.userIdentities replaceObjectAtIndex:existingEntryIndex withObject:identityDictionary];
                    }
                    
                    persistUserIdentities = YES;
                }
            }
            
            if (persistUserIdentities) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    userDefaults[kMPUserIdentityArrayKey] = self.userIdentities;
                    [userDefaults synchronize];
                });
            }
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf setUserIdentity:identityString identityType:identityType attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(identityString, identityType, execStatus);
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
    
    if ([[MPStateMachine sharedInstance].locationTrackingMode isEqualToString:kMPRemoteConfigForceTrue]) {
        return MPExecStatusEnabledRemotely;
    }
    
    [[MPStateMachine sharedInstance].locationManager endLocationTracking];
    [MPStateMachine sharedInstance].locationManager = nil;
    
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
    
    NSUInteger notificationTypes;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        notificationTypes = userNotificationSettings.types;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
#pragma clang diagnostic pop
    }
    
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
    if ([MPLocationManager trackingLocation]) {
        messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
    }
    MPDataModelAbstract *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:(_session != nil)];
}
#endif

#pragma mark Public media traking methods
- (void)beginPlaying:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Media track cannot play prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(mediaTrack, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            if (mediaTrack.playbackRate == 0.0) {
                mediaTrack.playbackRate = 1.0;
            }
            
            if (![self.mediaTrackContainer containsTrack:mediaTrack]) {
                [self.mediaTrackContainer addTrack:mediaTrack];
            }
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                                   session:self.session
                                                                                mediaTrack:mediaTrack
                                                                               mediaAction:MPMediaActionPlay];
            
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf beginPlaying:mediaTrack attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(mediaTrack, execStatus);
}

- (MPExecStatus)discardMediaTrack:(MPMediaTrack *)mediaTrack {
    [self.mediaTrackContainer removeTrack:mediaTrack];
    
    return MPExecStatusSuccess;
}

- (void)endPlaying:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Media track cannot end prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(mediaTrack, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            if (mediaTrack.playbackRate != 0.0) {
                mediaTrack.playbackRate = 0.0;
            }
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                                   session:self.session
                                                                                mediaTrack:mediaTrack
                                                                               mediaAction:MPMediaActionStop];
            
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf endPlaying:mediaTrack attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(mediaTrack, execStatus);
}

- (void)logMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Media track cannot log metadata prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(mediaTrack, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                                   session:self.session
                                                                                mediaTrack:mediaTrack
                                                                               mediaAction:MPMediaActionMetadata];
            
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logMetadataWithMediaTrack:mediaTrack attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(mediaTrack, execStatus);
}

- (void)logTimedMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Media track cannot log timed metadata prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(mediaTrack, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                                   session:self.session
                                                                                mediaTrack:mediaTrack
                                                                               mediaAction:MPMediaActionMetadata];
            
#if TARGET_OS_IOS == 1
            if ([MPLocationManager trackingLocation]) {
                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            }
#endif
            MPMessage *message = (MPMessage *)[messageBuilder build];
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf logTimedMetadataWithMediaTrack:mediaTrack attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(mediaTrack, execStatus);
}

- (NSArray *)mediaTracks {
    NSArray *mediaTracks = [self.mediaTrackContainer allMediaTracks];
    return mediaTracks;
}

- (MPMediaTrack *)mediaTrackWithChannel:(NSString *)channel {
    MPMediaTrack *mediaTrack = [self.mediaTrackContainer trackWithChannel:channel];
    return mediaTrack;
}

- (void)updatePlaybackPosition:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler {
    NSAssert(_initializationStatus != MPInitializationStatusNotStarted, @"\n****\n  Media track cannot update playback position prior to starting the mParticle SDK.\n****\n");
    
    if (attempt > METHOD_EXEC_MAX_ATTEMPT) {
        completionHandler(mediaTrack, MPExecStatusFail);
        return;
    }
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    switch (_initializationStatus) {
        case MPInitializationStatusStarted: {
            // At the moment we will only forward playback position to kits but not log a message
            //            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
            //                                                                                   session:self.session
            //                                                                                mediaTrack:mediaTrack
            //                                                                               mediaAction:MPMediaActionPlaybackPosition];
            //
            //#if TARGET_OS_IOS == 1
            //            if ([MPLocationManager trackingLocation]) {
            //                messageBuilder = [messageBuilder withLocation:[MPStateMachine sharedInstance].locationManager.location];
            //            }
            //#endif
            //            MPMessage *message = (MPMessage *)[messageBuilder build];
            //
            //            [self saveMessage:message updateSession:YES];
            //
            //            [self.session incrementCounter];
            
            execStatus = MPExecStatusSuccess;
        }
            break;
            
        case MPInitializationStatusStarting: {
            __weak MPBackendController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong MPBackendController *strongSelf = weakSelf;
                [strongSelf updatePlaybackPosition:mediaTrack attempt:(attempt + 1) completionHandler:completionHandler];
            });
            
            execStatus = attempt == 0 ? MPExecStatusDelayedExecution : MPExecStatusContinuedDelayedExecution;
        }
            break;
            
        case MPInitializationStatusNotStarted:
            execStatus = MPExecStatusSDKNotStarted;
            break;
    }
    
    completionHandler(mediaTrack, execStatus);
}

@end
