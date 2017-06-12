//
//  MPUploadBuilder.mm
//  mParticle
//
//  Created by Dalmo Cirne on 5/7/15.
//  Copyright (c) 2015 mParticle. All rights reserved.
//

#import "MPUploadBuilder.h"
#include <vector>
#import "MPMessage.h"
#import "MPSession.h"
#import "MPUpload.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "NSUserDefaults+mParticle.h"
#import "MPPersistenceController.h"
#import "MPCustomModule.h"
#import "MPStandaloneUpload.h"
#import "MPConsumerInfo.h"
#import "MPApplication.h"
#import "MPDevice.h"
#import "MPBags.h"
#import "MPBags+Internal.h"
#import "MPForwardRecord.h"
#import "MPDataModelAbstract.h"
#import "MPIntegrationAttributes.h"

using namespace std;

@interface MPUploadBuilder() {
    NSMutableDictionary<NSString *, id> *uploadDictionary;
}

@end

@implementation MPUploadBuilder

- (instancetype)initWithSession:(MPSession *)session messages:(nonnull NSArray<__kindof MPDataModelAbstract *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval {
    NSAssert(messages, @"Messages cannot be nil.");
    
    self = [super init];
    if (!self || !messages) {
        return nil;
    }
    
    _session = session;
    
    NSUInteger numberOfMessages = messages.count;
    NSMutableArray *messageDictionaries = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    _preparedMessageIds = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];

    [messages enumerateObjectsUsingBlock:^(MPMessage *message, NSUInteger idx, BOOL *stop) {
        [_preparedMessageIds addObject:@(message.messageId)];
        
        NSDictionary *messageDictionaryRepresentation = [message dictionaryRepresentation];
        if (messageDictionaryRepresentation) {
            [messageDictionaries addObject:messageDictionaryRepresentation];
        }
    }];
    
    NSNumber *ltv;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    ltv = userDefaults[kMPLifeTimeValueKey];
    if (!ltv) {
        ltv = @0;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    uploadDictionary = [@{kMPOptOutKey:@(stateMachine.optOut),
                          kMPUploadIntervalKey:@(uploadInterval),
                          kMPLifeTimeValueKey:ltv}
                        mutableCopy];

    if (messageDictionaries.count > 0) {
        uploadDictionary[kMPMessagesKey] = messageDictionaries;
    }

    if (sessionTimeout > 0) {
        uploadDictionary[kMPSessionTimeoutKey] = @(sessionTimeout);
    }
    
    if (stateMachine.customModules) {
        NSMutableDictionary *customModulesDictionary = [[NSMutableDictionary alloc] initWithCapacity:stateMachine.customModules.count];
        
        for (MPCustomModule *customModule in stateMachine.customModules) {
            customModulesDictionary[[customModule.customModuleId stringValue]] = [customModule dictionaryRepresentation];
        }
        
        uploadDictionary[kMPRemoteConfigCustomModuleSettingsKey] = customModulesDictionary;
    }
    
    uploadDictionary[kMPRemoteConfigMPIDKey] = stateMachine.consumerInfo.mpId;
    
    return self;
}

- (NSString *)description {
    NSString *description;
    
    if (_session) {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n Session Id: %lld\n UploadDictionary: %@", self.session.sessionId, uploadDictionary];
    } else {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n UploadDictionary: %@", uploadDictionary];
    }
    
    return description;
}

#pragma mark Public class methods
+ (MPUploadBuilder *)newBuilderWithMessages:(nonnull NSArray<__kindof MPDataModelAbstract *> *)messages uploadInterval:(NSTimeInterval)uploadInterval {
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithSession:nil messages:messages sessionTimeout:0 uploadInterval:uploadInterval];
    return uploadBuilder;
}

+ (MPUploadBuilder *)newBuilderWithSession:(MPSession *)session messages:(nonnull NSArray<__kindof MPDataModelAbstract *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval {
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithSession:session messages:messages sessionTimeout:sessionTimeout uploadInterval:uploadInterval];
    return uploadBuilder;
}

#pragma mark Public instance methods
- (void)build:(void (^)(MPDataModelAbstract *upload))completionHandler {
    [self buildAsync:YES completionHandler:completionHandler];
}

- (void)buildAsync:(BOOL)asyncBuild completionHandler:(void (^ _Nonnull)(MPDataModelAbstract * _Nullable upload))completionHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    uploadDictionary[kMPMessageTypeKey] = kMPMessageTypeRequestHeader;
    uploadDictionary[kMPmParticleSDKVersionKey] = kMParticleSDKVersion;
    uploadDictionary[kMPMessageIdKey] = [[NSUUID UUID] UUIDString];
    uploadDictionary[kMPTimestampKey] = MPMilliseconds([[NSDate date] timeIntervalSince1970]);
    uploadDictionary[kMPApplicationKey] = stateMachine.apiKey;
    
    MPApplication *application = [[MPApplication alloc] init];
    uploadDictionary[kMPApplicationInformationKey] = [application dictionaryRepresentation];
    
    MPDevice *device = [[MPDevice alloc] init];
    uploadDictionary[kMPDeviceInformationKey] = [device dictionaryRepresentation];
    
    NSDictionary *cookies = [stateMachine.consumerInfo cookiesDictionaryRepresentation];
    if (cookies) {
        uploadDictionary[kMPRemoteConfigCookiesKey] = cookies;
    }
    
    NSDictionary *productBags = [stateMachine.bags dictionaryRepresentation];
    if (productBags) {
        uploadDictionary[kMPProductBagKey] = productBags;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray<MPForwardRecord *> *forwardRecords = [persistence fetchForwardRecords];
    NSMutableArray<NSNumber *> *forwardRecordsIds = nil;
    
    if (forwardRecords) {
        NSUInteger numberOfRecords = forwardRecords.count;
        NSMutableArray *fsr = [[NSMutableArray alloc] initWithCapacity:numberOfRecords];
        forwardRecordsIds = [[NSMutableArray alloc] initWithCapacity:numberOfRecords];
        
        for (MPForwardRecord *forwardRecord in forwardRecords) {
            if (forwardRecord.dataDictionary) {
                [fsr addObject:forwardRecord.dataDictionary];
                [forwardRecordsIds addObject:@(forwardRecord.forwardRecordId)];
            }
        }
        
        if (fsr.count > 0) {
            uploadDictionary[kMPForwardStatsRecord] = fsr;
        }
    }
    
    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    if (integrationAttributesArray) {
        NSMutableDictionary *integrationAttributesDictionary = [[NSMutableDictionary alloc] initWithCapacity:integrationAttributesArray.count];
        
        for (MPIntegrationAttributes *integrationAttributes in integrationAttributesArray) {
            [integrationAttributesDictionary addEntriesFromDictionary:[integrationAttributes dictionaryRepresentation]];
        }
        
        uploadDictionary[MPIntegrationAttributesKey] = integrationAttributesDictionary;
    }
    
#ifdef SERVER_ECHO
    uploadDictionary[@"echo"] = @true;
#endif
    
    if (_session) { // MPUpload
        dispatch_block_t completeBuild = ^{
            MPUpload *upload = [[MPUpload alloc] initWithSession:_session uploadDictionary:uploadDictionary];
            
            completionHandler(upload);
            
            [persistence deleteForwardRecordsIds:forwardRecordsIds];
        };

#if TARGET_OS_IOS == 1
        void (^processUserNotificationCampaign)(NSArray<MParticleUserNotification *> *) = ^(NSArray<MParticleUserNotification *> *userNotificationCampaignHistory) {
            if (!userNotificationCampaignHistory) {
                return;
            }
            
            NSMutableDictionary *userNotificationCampaignHistoryDictionary = [[NSMutableDictionary alloc] initWithCapacity:userNotificationCampaignHistory.count];
            
            for (MParticleUserNotification *userNotification in userNotificationCampaignHistory) {
                if (userNotification.campaignId && userNotification.contentId) {
                    userNotificationCampaignHistoryDictionary[[userNotification.campaignId stringValue]] = @{kMPRemoteNotificationContentIdHistoryKey:userNotification.contentId,
                                                                                                             kMPRemoteNotificationTimestampHistoryKey:MPMilliseconds([userNotification.receiptTime timeIntervalSince1970])};
                }
            }
            
            if (userNotificationCampaignHistoryDictionary.count > 0) {
                uploadDictionary[kMPRemoteNotificationCampaignHistoryKey] = userNotificationCampaignHistoryDictionary;
            }
        };
        
        if (asyncBuild) {
            [persistence fetchUserNotificationCampaignHistory:^(NSArray<MParticleUserNotification *> *userNotificationCampaignHistory) {
                processUserNotificationCampaign(userNotificationCampaignHistory);
                completeBuild();
            }];
        } else {
            NSArray<MParticleUserNotification *> *userNotificationCampaignHistory = [persistence fetchUserNotificationCampaignHistorySync];
            processUserNotificationCampaign(userNotificationCampaignHistory);
            completeBuild();
        }
#else
        completeBuild();
#endif
    } else { // MPStandaloneUpload
        MPStandaloneUpload *standaloneUpload = [[MPStandaloneUpload alloc] initWithUploadDictionary:uploadDictionary];
        
        completionHandler(standaloneUpload);
    }
}

- (MPUploadBuilder *)withUserAttributes:(NSDictionary<NSString *, id> *)userAttributes deletedUserAttributes:(NSSet<NSString *> *)deletedUserAttributes {
    if ([userAttributes count] > 0) {
        NSMutableDictionary<NSString *, id> *userAttributesCopy = [userAttributes mutableCopy];
        if (!userAttributesCopy) {
            return self;
        }
        
        NSArray *keys = [userAttributesCopy allKeys];
        Class numberClass = [NSNumber class];
        
        for (NSString *key in keys) {
            id currentValue = userAttributesCopy[key];
            NSString *newValue = [currentValue isKindOfClass:numberClass] ? [(NSNumber *)currentValue stringValue] : currentValue;
            
            if (newValue) {
                userAttributesCopy[key] = newValue;
            }
        }
        
        if (userAttributesCopy.count > 0) {
            uploadDictionary[kMPUserAttributeKey] = userAttributesCopy;
        }
    }
    
    if (deletedUserAttributes.count > 0 && _session) {
        uploadDictionary[kMPUserAttributeDeletedKey] = [deletedUserAttributes allObjects];
    }
    
    return self;
}

- (MPUploadBuilder *)withUserIdentities:(NSArray<NSDictionary<NSString *, id> *> *)userIdentities {
    if (userIdentities.count > 0) {
        uploadDictionary[kMPUserIdentityArrayKey] = userIdentities;
    }
    
    return self;
}

@end
