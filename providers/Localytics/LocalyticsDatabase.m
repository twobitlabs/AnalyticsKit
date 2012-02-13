//
//  LocalyticsDatabase.m
//  LocalyticsDemo
//
//  Created by jkaufman on 5/26/11.
//  Copyright 2011 Localytics. All rights reserved.
//

#import "LocalyticsDatabase.h"

#define LOCALYTICS_DIR              @".localytics"	// Name for the directory in which Localytics database is stored
#define LOCALYTICS_DB               @"localytics"	// File name for the database (without extension)
#define BUSY_TIMEOUT                30              // Maximum time SQlite will busy-wait for the database to unlock before returning SQLITE_BUSY

@interface LocalyticsDatabase ()
    - (int)schemaVersion;
    - (void)createSchema;
    - (void)upgradeToSchemaV2;
    - (void)moveDbToCaches;
@end

@implementation LocalyticsDatabase

// The singleton database object.
static LocalyticsDatabase *_sharedLocalyticsDatabase = nil;

+ (NSString *)localyticsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);    
    return  [[paths objectAtIndex:0] stringByAppendingPathComponent:LOCALYTICS_DIR];
}

+ (NSString *)localyticsDatabasePath {
    NSString *path = [[LocalyticsDatabase localyticsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", LOCALYTICS_DB]];
    return path;
}

#pragma mark Singleton Class
+ (LocalyticsDatabase *)sharedLocalyticsDatabase {
	@synchronized(self) {
		if (_sharedLocalyticsDatabase == nil) {
			_sharedLocalyticsDatabase = [[self alloc] init];
		}
	}
	return _sharedLocalyticsDatabase;
}

- (LocalyticsDatabase *)init {
	if((self = [super init])) {
        
        // Ensure that database access is not concurrent and that only one thread has an open
        // transaction at any given time.
        _dbLock = [[NSRecursiveLock alloc] init];
        _transactionLock = [[NSRecursiveLock alloc] init];
        
        // Mover any data that a previous library may have left in the documents directory
        [self moveDbToCaches];
        
        // Create directory structure for Localytics.
        NSString *directoryPath = [LocalyticsDatabase localyticsDirectoryPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // Attempt to open database. It will be created if it does not exist, already.
        [_dbLock lock];
        NSString *dbPath = [LocalyticsDatabase localyticsDatabasePath];
        int code =  sqlite3_open([dbPath UTF8String], &_databaseConnection);

        // If we were unable to open the database, it is likely corrupted. Clobber it and move on.
        if (code != SQLITE_OK) {
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
            code =  sqlite3_open([dbPath UTF8String], &_databaseConnection);
        }
        [_dbLock unlock];

        // Check db connection, creating schema if necessary.
        if (code == SQLITE_OK) {
            sqlite3_busy_timeout(_databaseConnection, BUSY_TIMEOUT); // Defaults to 0, otherwise.
            if ([self schemaVersion] == 0) {
                [self createSchema];
            }
        }

        // Perform any Migrations if necessary
        if ([self schemaVersion] < 2) {
            [self upgradeToSchemaV2];
        }
    }
    
	return self;
}

#pragma mark - Database 

- (BOOL)beginTransaction:(NSString *)name {
    [_dbLock lock];
    [_transactionLock lock];
    const char *sql = [[NSString stringWithFormat:@"SAVEPOINT %@", name] cStringUsingEncoding:NSUTF8StringEncoding];
    int code = sqlite3_exec(_databaseConnection, sql, NULL, NULL, NULL);
    [_dbLock unlock];
    return code == SQLITE_OK;
}

- (BOOL)releaseTransaction:(NSString *)name {
    [_dbLock lock];
    const char *sql = [[NSString stringWithFormat:@"RELEASE SAVEPOINT %@", name] cStringUsingEncoding:NSUTF8StringEncoding];
    int code = sqlite3_exec(_databaseConnection, sql, NULL, NULL, NULL);
    [_transactionLock unlock];
    [_dbLock unlock];
    return code == SQLITE_OK;
}

- (BOOL)rollbackTransaction:(NSString *)name {
    [_dbLock lock];
    const char *sql = [[NSString stringWithFormat:@"ROLLBACK SAVEPOINT %@", name] cStringUsingEncoding:NSUTF8StringEncoding];
    int code = sqlite3_exec(_databaseConnection, sql, NULL, NULL, NULL);
    [_transactionLock unlock];
    [_dbLock unlock];
    return code == SQLITE_OK;
}

- (int)schemaVersion {
    [_dbLock lock];
    int version = 0;
    const char *sql = "SELECT MAX(schema_version) FROM localytics_info";
    sqlite3_stmt *selectSchemaVersion;
    if(sqlite3_prepare_v2(_databaseConnection, sql, -1, &selectSchemaVersion, NULL) == SQLITE_OK) {
        if(sqlite3_step(selectSchemaVersion) == SQLITE_ROW) {
            version = sqlite3_column_int(selectSchemaVersion, 0);
        }
    }
    sqlite3_finalize(selectSchemaVersion);
    [_dbLock unlock];
    return version;
}

- (NSString *) installId {
    [_dbLock lock];
    
    NSString *installId = nil;
    
    sqlite3_stmt *selectInstallId;
    sqlite3_prepare_v2(_databaseConnection, "SELECT install_id FROM localytics_info", -1, &selectInstallId, NULL);
    int code = sqlite3_step(selectInstallId);
    if (code == SQLITE_ROW && sqlite3_column_text(selectInstallId, 0)) {                
        installId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectInstallId, 0)];
    }
    sqlite3_finalize(selectInstallId);
    
    [_dbLock unlock];    
    return installId;
}

// Due to the new iOS storage guidelines it is necessary to move the database out of the documents directory
// and into the /library/caches directory 
- (void)moveDbToCaches {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);    
    NSString *localyticsDocumentsDirectory = [[documentPaths objectAtIndex:0] stringByAppendingPathComponent:LOCALYTICS_DIR];    
    NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *localyticsCachesDirectory = [[cachesPaths objectAtIndex:0] stringByAppendingPathComponent:LOCALYTICS_DIR];
    
    // If the old directory doesn't exist, there is nothing else to do here
    if([[NSFileManager defaultManager] fileExistsAtPath:localyticsDocumentsDirectory] == NO) 
    {
        return;
    }

    // Try to move the directory
    if(NO == [[NSFileManager defaultManager] moveItemAtPath:localyticsDocumentsDirectory 
                                             toPath:localyticsCachesDirectory 
                                             error:nil])
    {
        // If the move failed try and, delete the old directory
        [ [NSFileManager defaultManager] removeItemAtPath:localyticsDocumentsDirectory error:nil];
    }
}

- (void)createSchema {
    int code = SQLITE_OK;
    
    [_dbLock lock];
    [_transactionLock lock];

    // Execute schema creation within a single transaction.
    code = sqlite3_exec(_databaseConnection, "BEGIN", NULL, NULL, NULL);
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "CREATE TABLE upload_headers ("
                            "sequence_number INTEGER PRIMARY KEY, "
                            "blob_string TEXT)",
                            NULL, NULL, NULL);
    }

    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "CREATE TABLE events ("
                            "event_id INTEGER PRIMARY KEY AUTOINCREMENT, " // In case foreign key constraints are reintroduced.
                            "upload_header INTEGER, "
                            "blob_string TEXT NOT NULL)",
                            NULL, NULL, NULL);
    }
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "CREATE TABLE localytics_info ("
                            "schema_version INTEGER PRIMARY KEY, "
                            "last_upload_number INTEGER, "
                            "last_session_number INTEGER, "
                            "opt_out BOOLEAN, "
                            "last_close_event INTEGER, "
                            "last_flow_event INTEGER, "
                            "last_session_start REAL, "
                            "install_id CHAR(40), "
                            "custom_d0 CHAR(64), "
                            "custom_d1 CHAR(64), "
                            "custom_d2 CHAR(64), "
                            "custom_d3 CHAR(64) "
                            ")",
                            NULL, NULL, NULL);
    }

    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "INSERT INTO localytics_info (schema_version, last_upload_number, last_session_number, opt_out) "
                            "VALUES (2, 0, 0, 0)",
                            NULL, NULL, NULL);
    }

    // Commit transaction.
    if (code == SQLITE_OK || code == SQLITE_DONE) {
        sqlite3_exec(_databaseConnection, "COMMIT", NULL, NULL, NULL);
    } else {
        sqlite3_exec(_databaseConnection, "ROLLBACK", NULL, NULL, NULL);
    }
    [_transactionLock unlock];
    [_dbLock unlock];
}

// V2 adds a unique identifier for each installation
// This identifier has been moved to user preferences so the database an live in the caches directory
// Also adds storage for custom dimensions
- (void)upgradeToSchemaV2 {
    int code = SQLITE_OK;
    
    [_dbLock lock];
    [_transactionLock lock];
    code = sqlite3_exec(_databaseConnection, "BEGIN", NULL, NULL, NULL);

    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "ALTER TABLE localytics_info ADD install_id CHAR(40)",
                            NULL, NULL, NULL);
    }

    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "ALTER TABLE localytics_info ADD custom_d0 CHAR(64)",
                            NULL, NULL, NULL);
    }
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "ALTER TABLE localytics_info ADD custom_d1 CHAR(64)",
                            NULL, NULL, NULL);
    }
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "ALTER TABLE localytics_info ADD custom_d2 CHAR(64)",
                            NULL, NULL, NULL);
    }
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection,
                            "ALTER TABLE localytics_info ADD custom_d3 CHAR(64)",
                            NULL, NULL, NULL);
    }
        
    // Commit transaction.
    if (code == SQLITE_OK || code == SQLITE_DONE) {
        sqlite3_exec(_databaseConnection, "COMMIT", NULL, NULL, NULL);
    } else {
        sqlite3_exec(_databaseConnection, "ROLLBACK", NULL, NULL, NULL);
    }
    [_transactionLock unlock];
    [_dbLock unlock];
}

- (NSUInteger)databaseSize {
    NSUInteger size = 0;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] 
                                    attributesOfItemAtPath:[LocalyticsDatabase localyticsDatabasePath]
                                    error:nil];
    size = [fileAttributes fileSize];
    return size;
}

- (int) eventCount {
    [_dbLock lock];
    int count = 0;
    const char *sql = "SELECT count(*) FROM events";
    sqlite3_stmt *selectEventCount;
    
    if(sqlite3_prepare_v2(_databaseConnection, sql, -1, &selectEventCount, NULL) == SQLITE_OK) 
    {
        if(sqlite3_step(selectEventCount) == SQLITE_ROW) {
            count = sqlite3_column_int(selectEventCount, 0);
        }
    }
    sqlite3_finalize(selectEventCount);
    [_dbLock unlock];
    
    return count;
}

- (NSTimeInterval)createdTimestamp {
    NSTimeInterval timestamp = 0;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] 
                                    attributesOfItemAtPath:[LocalyticsDatabase localyticsDatabasePath]
                                    error:nil];
    timestamp = [[fileAttributes fileCreationDate] timeIntervalSince1970];    
    return timestamp;
}

- (NSTimeInterval)lastSessionStartTimestamp {
    [_dbLock lock];
    
    NSTimeInterval lastSessionStart = 0;
    
    sqlite3_stmt *selectLastSessionStart;
    sqlite3_prepare_v2(_databaseConnection, "SELECT last_session_start FROM localytics_info", -1, &selectLastSessionStart, NULL);
    int code = sqlite3_step(selectLastSessionStart);
    if (code == SQLITE_ROW) {
        lastSessionStart = sqlite3_column_double(selectLastSessionStart, 0) == 1;
    }
    sqlite3_finalize(selectLastSessionStart);
    
    [_dbLock unlock];
    
    return lastSessionStart;
}

- (BOOL)setLastsessionStartTimestamp:(NSTimeInterval)timestamp {
    [_dbLock lock];
    
    sqlite3_stmt *updateLastSessionStart;
    sqlite3_prepare_v2(_databaseConnection, "UPDATE localytics_info SET last_session_start = ?", -1, &updateLastSessionStart, NULL);
    sqlite3_bind_double(updateLastSessionStart, 1, timestamp);
    int code = sqlite3_step(updateLastSessionStart);
    sqlite3_finalize(updateLastSessionStart);
    
    [_dbLock unlock];
    
    return code == SQLITE_DONE;
}

- (BOOL)isOptedOut {
    [_dbLock lock];
   
    BOOL optedOut = NO;

    sqlite3_stmt *selectOptOut;
    sqlite3_prepare_v2(_databaseConnection, "SELECT opt_out FROM localytics_info", -1, &selectOptOut, NULL);
    int code = sqlite3_step(selectOptOut);
    if (code == SQLITE_ROW) {
        optedOut = sqlite3_column_int(selectOptOut, 0) == 1;
    }
    sqlite3_finalize(selectOptOut);
    
    [_dbLock unlock];
    
    return optedOut;
}

- (BOOL)setOptedOut:(BOOL)optOut {
    [_dbLock lock];
   
    sqlite3_stmt *updateOptedOut;
    sqlite3_prepare_v2(_databaseConnection, "UPDATE localytics_info SET opt_out = ?", -1, &updateOptedOut, NULL);
    sqlite3_bind_int(updateOptedOut, 1, optOut);
    int code = sqlite3_step(updateOptedOut);
    sqlite3_finalize(updateOptedOut);
    
    [_dbLock unlock];
    
    return code == SQLITE_OK;
}

- (NSString *)customDimension:(int)dimension {
    if(dimension < 0 || dimension > 3) {
        return nil;
    }
    
    NSString *value = nil;
    NSString *query = [NSString stringWithFormat:@"select custom_d%i from localytics_info", dimension];
    
    [_dbLock lock];
    sqlite3_stmt *selectCustomDim;
    sqlite3_prepare_v2(_databaseConnection, [query UTF8String], -1, &selectCustomDim, NULL);
    int code = sqlite3_step(selectCustomDim);
    if (code == SQLITE_ROW && sqlite3_column_text(selectCustomDim, 0)) {
        value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectCustomDim, 0)];
    }
    sqlite3_finalize(selectCustomDim);
    [_dbLock unlock];

    return value;
}

- (BOOL)setCustomDimension:(int)dimension value:(NSString *)value {
    if(dimension < 0 || dimension > 3) {
        return false;
    }
    
    NSString *query = [NSString stringWithFormat:@"update localytics_info SET custom_d%i = %@", 
                         dimension,
                         (value == nil) ? @"null" : [NSString stringWithFormat:@"\"%@\"", value]];
    
    [_dbLock lock];
    int code = sqlite3_exec(_databaseConnection, [query UTF8String], NULL, NULL, NULL);
    [_dbLock unlock];

    return code == SQLITE_OK;
}

- (BOOL)incrementLastUploadNumber:(int *)uploadNumber {
    NSString *t = @"increment_upload_number";
    int code = SQLITE_OK;

    code = [self beginTransaction:t] ? SQLITE_OK : SQLITE_ERROR;
    
    [_dbLock lock];

    if(code == SQLITE_OK) {
        // Increment value
        code = sqlite3_exec(_databaseConnection,
                            "UPDATE localytics_info "
                            "SET last_upload_number = (last_upload_number + 1)",
                            NULL, NULL, NULL);
    }

    if(code == SQLITE_OK) {
        // Retrieve new value
        sqlite3_stmt *selectUploadNumber;
        sqlite3_prepare_v2(_databaseConnection, 
                                  "SELECT last_upload_number FROM localytics_info",
                                  -1, &selectUploadNumber, NULL);
        code = sqlite3_step(selectUploadNumber);
        if (code == SQLITE_ROW) {
            *uploadNumber = sqlite3_column_int(selectUploadNumber, 0);
        }
        sqlite3_finalize(selectUploadNumber);
    }

    [_dbLock unlock];

    if(code == SQLITE_ROW) {
        [self releaseTransaction:t];
    } else {
        [self rollbackTransaction:t];
    }
    
    return code == SQLITE_ROW;
}

- (BOOL)incrementLastSessionNumber:(int *)sessionNumber {
    NSString *t = @"increment_session_number";
    int code = [self beginTransaction:t] ? SQLITE_OK : SQLITE_ERROR;
    
    [_dbLock lock];

    if(code == SQLITE_OK) {
        // Increment value
        code = sqlite3_exec(_databaseConnection,
                            "UPDATE localytics_info "
                            "SET last_session_number = (last_session_number + 1)",
                            NULL, NULL, NULL);
    }
    
    if(code == SQLITE_OK) {
        // Retrieve new value
        sqlite3_stmt *selectSessionNumber;
        sqlite3_prepare_v2(_databaseConnection, 
                           "SELECT last_session_number FROM localytics_info",
                           -1, &selectSessionNumber, NULL);
        code = sqlite3_step(selectSessionNumber);
        if (code == SQLITE_ROW && sessionNumber != NULL) {
            *sessionNumber = sqlite3_column_int(selectSessionNumber, 0);
        }
        sqlite3_finalize(selectSessionNumber);
    }

    [_dbLock unlock];
    
    if(code == SQLITE_ROW) {
        [self releaseTransaction:t];
    } else {
        [self rollbackTransaction:t];
    }

    return code == SQLITE_ROW;
}

- (BOOL)addEventWithBlobString:(NSString *)blob {
    [_dbLock lock];
    
    int code = SQLITE_OK;
    sqlite3_stmt *insertEvent;
    sqlite3_prepare_v2(_databaseConnection, "INSERT INTO events (blob_string) VALUES (?)", -1, &insertEvent, NULL);
    sqlite3_bind_text(insertEvent, 1, [blob UTF8String], -1, SQLITE_TRANSIENT); 
    code = sqlite3_step(insertEvent);
    sqlite3_finalize(insertEvent);

    [_dbLock unlock];

    return code == SQLITE_DONE;
}

- (BOOL)addCloseEventWithBlobString:(NSString *)blob {
    NSString *t = @"add_close_event";
    BOOL success = [self beginTransaction:t];
    
    // Add close event.
    if (success) {
        success = [self addEventWithBlobString:blob];
    }

    // Record row id to localytics_info so that it can be removed if the session resumes.
    if (success) {
        [_dbLock lock];
        sqlite3_stmt *updateCloseEvent;
        sqlite3_prepare_v2(_databaseConnection, "UPDATE localytics_info SET last_close_event = (SELECT event_id FROM events WHERE rowid = ?)", -1, &updateCloseEvent, NULL);
        sqlite3_int64 lastRow = sqlite3_last_insert_rowid(_databaseConnection);
        sqlite3_bind_int64(updateCloseEvent, 1, lastRow);
        int code = sqlite3_step(updateCloseEvent);        
        sqlite3_finalize(updateCloseEvent);
        success = code == SQLITE_DONE;
        [_dbLock unlock];
    }
    
    if (success) {
        [self releaseTransaction:t];
    } else {
        [self rollbackTransaction:t];
    }
    return success;
}

- (BOOL)addFlowEventWithBlobString:(NSString *)blob {
    NSString *t = @"add_flow_event";
    BOOL success = [self beginTransaction:t];
    
    // Add flow event.
    if (success) {
        success = [self addEventWithBlobString:blob];
    }
    
    // Record row id to localytics_info so that it can be removed if the session resumes.
    if (success) {
        [_dbLock lock];
        sqlite3_stmt *updateFlowEvent;
        sqlite3_prepare_v2(_databaseConnection, "UPDATE localytics_info SET last_flow_event = (SELECT event_id FROM events WHERE rowid = ?)", -1, &updateFlowEvent, NULL);
        sqlite3_int64 lastRow = sqlite3_last_insert_rowid(_databaseConnection);
        sqlite3_bind_int64(updateFlowEvent, 1, lastRow);
        int code = sqlite3_step(updateFlowEvent);        
        sqlite3_finalize(updateFlowEvent);
        success = code == SQLITE_DONE;
        [_dbLock unlock];
    }
    
    if (success) {
        [self releaseTransaction:t];
    } else {
        [self rollbackTransaction:t];
    }
    return success;
}

- (BOOL)removeLastCloseAndFlowEvents {
    [_dbLock lock];
    
    // Attempt to remove the last recorded close event.
    // Fail quietly if none was saved or it was previously removed.
    int code = sqlite3_exec(_databaseConnection, "DELETE FROM events WHERE event_id = (SELECT last_close_event FROM localytics_info) OR event_id = (SELECT last_flow_event FROM localytics_info)", NULL, NULL, NULL);
    
    [_dbLock unlock];

    return code == SQLITE_OK;
}

- (BOOL)addHeaderWithSequenceNumber:(int)number blobString:(NSString *)blob rowId:(sqlite3_int64 *)insertedRowId {
    [_dbLock lock];
    
    sqlite3_stmt *insertHeader;
    sqlite3_prepare_v2(_databaseConnection, "INSERT INTO upload_headers (sequence_number, blob_string) VALUES (?, ?)", -1, &insertHeader, NULL);
    sqlite3_bind_int(insertHeader, 1, number);
    sqlite3_bind_text(insertHeader, 2, [blob UTF8String], -1, SQLITE_TRANSIENT); 
    int code = sqlite3_step(insertHeader);
    sqlite3_finalize(insertHeader);
    
    if (code == SQLITE_DONE && insertedRowId != NULL) {
        *insertedRowId = sqlite3_last_insert_rowid(_databaseConnection);
    }

    [_dbLock unlock];
    
    return code == SQLITE_DONE;
}

- (int)unstagedEventCount {
    [_dbLock lock];
    
    int rowCount = 0;
    sqlite3_stmt *selectEventCount;
    sqlite3_prepare_v2(_databaseConnection, "SELECT COUNT(*) FROM events WHERE UPLOAD_HEADER IS NULL", -1, &selectEventCount, NULL);
    int code = sqlite3_step(selectEventCount);
    if (code == SQLITE_ROW) {
        rowCount = sqlite3_column_int(selectEventCount, 0);
    }
    sqlite3_finalize(selectEventCount);
    
    [_dbLock unlock];

    return rowCount;
}

- (BOOL)stageEventsForUpload:(sqlite3_int64)headerId {
    [_dbLock lock];
    
    // Associate all outstanding events with the given upload header ID.
    NSString *stageEvents = [NSString stringWithFormat:@"UPDATE events SET upload_header = ? WHERE upload_header IS NULL"];
    sqlite3_stmt *updateEvents;
    sqlite3_prepare_v2(_databaseConnection, [stageEvents UTF8String], -1, &updateEvents, NULL);
    sqlite3_bind_int(updateEvents, 1, headerId);
    int code = sqlite3_step(updateEvents);
    sqlite3_finalize(updateEvents);
    BOOL success = (code == SQLITE_DONE);

    [_dbLock unlock];

    return success;
}

- (NSString *)uploadBlobString {
    [_dbLock lock];

    // Retrieve the blob strings of each upload header and its child events, in order.
    const char *sql = "SELECT * FROM ( "
                      "   SELECT h.blob_string AS 'blob', h.sequence_number as 'seq', 0 FROM upload_headers h"
                      "   UNION ALL "
                      "   SELECT e.blob_string AS 'blob', e.upload_header as 'seq', 1 FROM events e"
                      ") "
                      "ORDER BY 2, 3";
    sqlite3_stmt *selectBlobs;
    sqlite3_prepare_v2(_databaseConnection, sql, -1, &selectBlobs, NULL);
    NSMutableString *uploadBlobString = [NSMutableString string];
    while (sqlite3_step(selectBlobs) == SQLITE_ROW) {
        const char *blob = (const char *)sqlite3_column_text(selectBlobs, 0);
        if (blob != NULL) {
            NSString *blobString = [[NSString alloc] initWithCString:blob encoding:NSUTF8StringEncoding];
            [uploadBlobString appendString:blobString];
            [blobString release];
        }
    }
    sqlite3_finalize(selectBlobs);
    
    [_dbLock unlock];

    return [[uploadBlobString copy] autorelease];
}

- (BOOL)deleteUploadData {
    // Delete all headers and staged events.
    NSString *t = @"delete_upload_data";
    int code = [self beginTransaction:t] ? SQLITE_OK : SQLITE_ERROR;
    
    [_dbLock lock];

    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection, "DELETE FROM events WHERE upload_header IS NOT NULL", NULL, NULL, NULL);
    }
    
    if (code == SQLITE_OK) {
        code = sqlite3_exec(_databaseConnection, "DELETE FROM upload_headers", NULL, NULL, NULL);
    }

    [_dbLock unlock];

    if (code == SQLITE_OK) {
        [self releaseTransaction:t];
    } else {
        [self rollbackTransaction:t];
    }
    
    return code == SQLITE_OK;
}

#pragma mark - Lifecycle

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (_sharedLocalyticsDatabase == nil) {
			_sharedLocalyticsDatabase = [super allocWithZone:zone];
			return _sharedLocalyticsDatabase;
		}
	}
	// returns nil on subsequent allocations
	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	// maximum value of an unsigned int - prevents additional retains for the class
	return UINT_MAX;
}

- (oneway void)release {
	// ignore release commands
}

- (id)autorelease {
	return self;
}

- (void)dealloc {
    sqlite3_close(_databaseConnection);
    [_transactionLock release];
    [_dbLock release];
	[super dealloc];
}

@end
