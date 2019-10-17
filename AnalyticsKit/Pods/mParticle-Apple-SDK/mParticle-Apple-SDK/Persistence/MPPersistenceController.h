#import <Foundation/Foundation.h>
#import "MParticleUserNotification.h"

@class MPSegment;
@class MPMessage;
@class MPSession;
@class MPUpload;
@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPBreadcrumb;
@class MPIntegrationAttributes;
@class MPConsentState;

#if TARGET_OS_IOS == 1
    @class MParticleUserNotification;
#endif

@interface MPPersistenceController : NSObject

@property (nonatomic, readonly, getter = isDatabaseOpen) BOOL databaseOpen;

+ (nullable NSNumber *)mpId;
+ (void)setMpid:(nonnull NSNumber *)mpId;
+ (nullable MPConsentState *)consentStateForMpid:(nonnull NSNumber *)mpid;
+ (void)setConsentState:(nullable MPConsentState *)state forMpid:(nonnull NSNumber *)mpid;
- (nullable MPSession *)archiveSession:(nonnull MPSession *)session;
- (BOOL)closeDatabase;
- (void)resetDatabase;
- (void)deleteConsumerInfo;
- (void)deleteCookie:(nonnull MPCookie *)cookie;
- (void)deleteForwardRecordsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds;
- (void)deleteAllIntegrationAttributes;
- (void)deleteIntegrationAttributesForIntegrationId:(nonnull NSNumber *)integrationId;
- (void)deleteMessages:(nonnull NSArray<MPMessage *> *)messages;
- (void)deleteNetworkPerformanceMessages;
- (void)deletePreviousSession;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp;
- (void)deleteSegments;
- (void)deleteAllSessionsExcept:(nullable MPSession *)session;
- (void)deleteSession:(nonnull MPSession *)session;
- (void)deleteUpload:(nonnull MPUpload *)upload;
- (void)deleteUploadId:(int64_t)uploadId;
- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs;
- (nullable MPConsumerInfo *)fetchConsumerInfoForUserId:(NSNumber * _Nonnull)userId;
- (nullable NSArray<MPCookie *> *)fetchCookiesForUserId:(NSNumber * _Nonnull)userId;
- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords;
- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes;
- (nullable NSDictionary*)fetchIntegrationAttributesForId:(NSNumber * _Nonnull)integrationId;
- (nullable NSMutableDictionary *)fetchMessagesForUploading;
- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash;
- (nullable MPSession *)fetchPreviousSession;
- (nullable NSArray<MPSegment *> *)fetchSegments;
- (nullable MPMessage *)fetchSessionEndMessageInSession:(nonnull MPSession *)session;
- (nullable NSMutableArray<MPSession *> *)fetchSessions;
- (nullable NSArray<MPMessage *> *)fetchMessagesInSession:(nonnull MPSession *)session userId:(nonnull NSNumber *)userId;
- (nullable NSArray<MPMessage *> *)fetchUploadedMessagesInSession:(nonnull MPSession *)session;
- (nullable NSArray<MPUpload *> *)fetchUploads;
- (void)moveContentFromMpidZeroToMpid:(nonnull NSNumber *)mpid;
- (void)purgeMemory;
- (BOOL)openDatabase;
- (void)saveBreadcrumb:(nonnull MPMessage *)message;
- (void)saveConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)saveForwardRecord:(nonnull MPForwardRecord *)forwardRecord;
- (void)saveIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes;
- (void)saveMessage:(nonnull MPMessage *)message;
- (void)saveSegment:(nonnull MPSegment *)segment;
- (void)saveSession:(nonnull MPSession *)session;
- (void)saveUpload:(nonnull MPUpload *)upload;
- (void)updateConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)updateSession:(nonnull MPSession *)session;

@end

