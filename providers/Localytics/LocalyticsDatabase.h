//
//  LocalyticsDatabase.h
//  LocalyticsDemo
//
//  Created by jkaufman on 5/26/11.
//  Copyright 2011 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface LocalyticsDatabase : NSObject {
    sqlite3 *_databaseConnection;
    NSRecursiveLock *_dbLock;
    NSRecursiveLock *_transactionLock;
}

+ (LocalyticsDatabase *)sharedLocalyticsDatabase;

- (NSUInteger)databaseSize;
- (int) eventCount;
- (NSTimeInterval)createdTimestamp;

- (BOOL)beginTransaction:(NSString *)name;
- (BOOL)releaseTransaction:(NSString *)name;
- (BOOL)rollbackTransaction:(NSString *)name;

- (BOOL)incrementLastUploadNumber:(int *)uploadNumber;
- (BOOL)incrementLastSessionNumber:(int *)sessionNumber;

- (BOOL)addEventWithBlobString:(NSString *)blob;
- (BOOL)addCloseEventWithBlobString:(NSString *)blob;
- (BOOL)addFlowEventWithBlobString:(NSString *)blob;
- (BOOL)removeLastCloseAndFlowEvents;

- (BOOL)addHeaderWithSequenceNumber:(int)number blobString:(NSString *)blob rowId:(sqlite3_int64 *)insertedRowId;
- (int)unstagedEventCount;
- (BOOL)stageEventsForUpload:(sqlite3_int64)headerId;
- (NSString *)uploadBlobString;
- (BOOL)deleteUploadData;

- (NSTimeInterval)lastSessionStartTimestamp;
- (BOOL)setLastsessionStartTimestamp:(NSTimeInterval)timestamp;

- (BOOL)isOptedOut;
- (BOOL)setOptedOut:(BOOL)optOut;
- (NSString *) installId;

- (NSString *)customDimension:(int)dimension;
- (BOOL)setCustomDimension:(int)dimension value:(NSString *)value;

@end
