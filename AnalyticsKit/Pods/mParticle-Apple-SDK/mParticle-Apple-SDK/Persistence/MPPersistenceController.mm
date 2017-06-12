//
//  MPPersistenceController.mm
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

#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import <dispatch/dispatch.h>
#import "MPDatabaseMigrationController.h"
#import "MPBreadcrumb.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPSegmentMembership.h"
#import "MPStandaloneMessage.h"
#import "MPStandaloneUpload.h"
#include <string>
#include <vector>
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPProductBag.h"
#import "MPForwardRecord.h"
#include "MessageTypeName.h"
#import "MPIntegrationAttributes.h"

#if TARGET_OS_IOS == 1
    #import "MParticleUserNotification.h"
#endif

using namespace std;
using namespace mParticle;

// Prototype declaration of the C functions
#ifdef __cplusplus
extern "C" {
#endif
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
    static NSData * _Nullable dataValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static NSDictionary * _Nullable dictionaryRepresentation(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static double doubleValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static int intValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static int64_t int64Value(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static NSString * _Nullable stringValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
#pragma clang diagnostic pop
    
#ifdef __cplusplus
}
#endif


typedef NS_ENUM(NSInteger, MPDatabaseState) {
    MPDatabaseStateCorrupted = 0,
    MPDatabaseStateOK
};

static const NSArray *databaseVersions;
const int MaxBreadcrumbs = 50;

@interface MPPersistenceController() {
    BOOL databaseOpen;
}

@property (nonatomic, strong) NSString *databasePath;

@end


@implementation MPPersistenceController

@synthesize databasePath = _databasePath;

+ (void)initialize {
    databaseVersions = @[@3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @21, @22, @23, @24, @25];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        dbQueue = dispatch_queue_create("com.mParticle.PersistenceQueue", DISPATCH_QUEUE_SERIAL);
        databaseOpen = NO;
        
        [self setupDatabase:^{
            [self migrateDatabaseIfNeeded];
        }];
    }
    
    return self;
}

#pragma mark Database version migration methods
- (void)migrateDatabaseIfNeeded {
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:[databaseVersions copy]];
    
    NSNumber *migrateVersion = [migrationController needsMigration];
    if (migrateVersion) {
        BOOL isDatabaseOpen = databaseOpen;
        [self closeDatabase];
        
        [migrationController migrateDatabaseFromVersion:migrateVersion];
        
        if (isDatabaseOpen) {
            [self openDatabase];
        }
    }
}

#pragma mark Accessors
- (NSString *)databasePath {
    if (_databasePath) {
        return _databasePath;
    }
    
    NSString *documentsDirectory;
#if TARGET_OS_IOS == 1
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#elif TARGET_OS_TV == 1
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
#else
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#endif
    
    NSNumber *currentDatabaseVersion = [databaseVersions lastObject];
    NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", currentDatabaseVersion];
    _databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    
    return _databasePath;
}

#pragma mark Private methods
- (void)deleteCookie:(MPCookie *)cookie {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM cookies WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 0, cookie.cookieId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting cookie: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteCookies {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM cookies";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting cookies: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (BOOL)isDatabaseOpen {
    return databaseOpen;
}

- (void)removeDatabase {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.databasePath]) {
        [fileManager removeItemAtPath:self.databasePath error:nil];
        mParticleDB = NULL;
        _databasePath = nil;
        databaseOpen = NO;
    }
}

- (void)saveCookie:(MPCookie *)cookie forConsumerInfo:(MPConsumerInfo *)consumerInfo {
    sqlite3_stmt *preparedStatement;
    
    vector<string> fields;
    vector<string> params;
    
    if (cookie.content) {
        fields.push_back("content");
        params.push_back("'" + string([cookie.content UTF8String]) + "'");
    }
    
    if (cookie.domain) {
        fields.push_back("domain");
        params.push_back("'" + string([cookie.domain UTF8String]) + "'");
    }
    
    if (cookie.expiration) {
        fields.push_back("expiration");
        params.push_back("'" + string([cookie.expiration UTF8String]) + "'");
    }
    
    fields.push_back("name");
    params.push_back("'" + string([cookie.name cStringUsingEncoding:NSUTF8StringEncoding]) + "'");
    
    string sqlStatement = "INSERT INTO cookies (consumer_info_id";
    for (auto field : fields) {
        sqlStatement += ", " + field;
    }
    
    sqlStatement += ") VALUES (?";
    
    for (auto param : params) {
        sqlStatement += ", " + param;
    }
    
    sqlStatement += ")";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, consumerInfo.consumerInfoId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing cookie: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        cookie.cookieId = sqlite3_last_insert_rowid(mParticleDB);
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)setupDatabase:(void (^)())completionHandler {
    dispatch_barrier_async(dbQueue, ^{
        if (sqlite3_open([self.databasePath UTF8String], &mParticleDB) != SQLITE_OK) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
            return;
        }
        
        MPDatabaseState databaseState = [self verifyDatabaseState];
        if (databaseState == MPDatabaseStateCorrupted) {
            [self removeDatabase];
            
            sqlite3_open([self.databasePath UTF8String], &mParticleDB);
        }
        
        string sqlStatement = "PRAGMA user_version";
        sqlite3_stmt *preparedStatement;
        int userDatabaseVersion = 0;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                userDatabaseVersion = sqlite3_column_int(preparedStatement, 0);
            }
        }
        
        sqlite3_finalize(preparedStatement);
        
        const int latestDatabaseVersion = [[databaseVersions lastObject] intValue];
        if (userDatabaseVersion == latestDatabaseVersion) {
            sqlite3_close(mParticleDB);
            mParticleDB = NULL;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
            
            return;
        }
        
        vector<string> sqlStatements = {
            "CREATE TABLE IF NOT EXISTS sessions ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                uuid TEXT NOT NULL, \
                start_time REAL, \
                end_time REAL, \
                background_time REAL, \
                attributes_data BLOB NOT NULL, \
                session_number INTEGER NOT NULL, \
                number_interruptions INTEGER, \
                event_count INTEGER, \
                suspend_time REAL, \
                length REAL \
            )",
            "CREATE TABLE IF NOT EXISTS previous_session ( \
                session_id INTEGER, \
                uuid TEXT, \
                start_time REAL, \
                end_time REAL, \
                background_time REAL, \
                attributes_data BLOB, \
                session_number INTEGER, \
                number_interruptions INTEGER, \
                event_count INTEGER, \
                suspend_time REAL, \
                length REAL \
            )",
            "CREATE TABLE IF NOT EXISTS messages ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_id INTEGER NOT NULL, \
                message_type TEXT NOT NULL, \
                uuid TEXT NOT NULL, \
                timestamp REAL NOT NULL, \
                message_data BLOB NOT NULL, \
                upload_status INTEGER, \
                FOREIGN KEY (session_id) REFERENCES sessions (_id) \
            )",
            "CREATE TABLE IF NOT EXISTS uploads ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_id INTEGER NOT NULL, \
                uuid TEXT NOT NULL, \
                message_data BLOB NOT NULL, \
                timestamp REAL NOT NULL, \
                FOREIGN KEY (session_id) REFERENCES sessions (_id) \
            )",
            "CREATE TABLE IF NOT EXISTS breadcrumbs ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_uuid TEXT NOT NULL, \
                uuid TEXT NOT NULL, \
                timestamp REAL NOT NULL, \
                breadcrumb_data BLOB NOT NULL, \
                session_number INTEGER NOT NULL \
            )",
            "CREATE TABLE IF NOT EXISTS segments ( \
                segment_id INTEGER PRIMARY KEY, \
                uuid TEXT NOT NULL, \
                name TEXT NOT NULL, \
                endpoint_ids TEXT \
            )",
            "CREATE TABLE IF NOT EXISTS segment_memberships ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                segment_id INTEGER NOT NULL, \
                timestamp REAL NOT NULL, \
                membership_action INTEGER NOT NULL, \
                FOREIGN KEY (segment_id) REFERENCES segments (segment_id) \
            )",
            "CREATE TABLE IF NOT EXISTS standalone_messages ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                message_type TEXT NOT NULL, \
                uuid TEXT NOT NULL, \
                timestamp REAL NOT NULL, \
                message_data BLOB NOT NULL, \
                upload_status INTEGER \
            )",
            "CREATE TABLE IF NOT EXISTS standalone_uploads ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                uuid TEXT NOT NULL, \
                message_data BLOB NOT NULL, \
                timestamp REAL NOT NULL \
            )",
            "CREATE TABLE IF NOT EXISTS remote_notifications ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                uuid TEXT NOT NULL, \
                campaign_id INTEGER, \
                content_id INTEGER, \
                command INTEGER, \
                expiration REAL, \
                local_alert_time REAL, \
                notification_data BLOB NOT NULL, \
                receipt_time REAL NOT NULL \
            )",
            "CREATE TABLE IF NOT EXISTS consumer_info ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                mpid INTEGER, \
                unique_identifier TEXT \
            )",
            "CREATE TABLE IF NOT EXISTS cookies ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                consumer_info_id INTEGER NOT NULL, \
                content TEXT, \
                domain TEXT, \
                expiration TEXT, \
                name TEXT, \
                FOREIGN KEY (consumer_info_id) references consumer_info (_id) \
            )",
            "CREATE TABLE IF NOT EXISTS product_bags ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                name TEXT, \
                timestamp REAL NOT NULL, \
                product_data BLOB NOT NULL \
            )",
            "CREATE TABLE IF NOT EXISTS forwarding_records ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                forwarding_data BLOB NOT NULL \
            )",
            "CREATE TABLE IF NOT EXISTS integration_attributes ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                kit_code INTEGER NOT NULL, \
                attributes_data BLOB NOT NULL \
            )"
        };
        
        int tableCreationStatus;
        char *errMsg;
        for (const auto &sqlStatement : sqlStatements) {
            tableCreationStatus = sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, &errMsg);
            
            if (tableCreationStatus != SQLITE_OK) {
                MPILogError("Problem creating table: %s\n", sqlStatement.c_str());
            }
        }
        
        sqlStatement = "PRAGMA user_version = " + to_string(latestDatabaseVersion);
        sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, NULL);
        sqlite3_close(mParticleDB);
        mParticleDB = NULL;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler();
        });
    });
}

- (void)updateCookie:(MPCookie *)cookie {
    if (!cookie.content && !cookie.domain && !cookie.expiration) {
        return;
    }
    
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "UPDATE cookies SET ";
    
    if (cookie.content) {
        sqlStatement += "content = '" + string([cookie.content UTF8String]) + "'";
    }
    
    if (cookie.domain) {
        sqlStatement += ", domain = '" + string([cookie.domain UTF8String]) + "'";
    }
    
    if (cookie.expiration) {
        sqlStatement += ", expiration = '" + string([cookie.expiration UTF8String]) + "'";
    }
    
    sqlStatement += " WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, cookie.cookieId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while updating cookie: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (MPDatabaseState)verifyDatabaseState {
    MPDatabaseState databaseState = MPDatabaseStateCorrupted;
    
    @try {
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "PRAGMA integrity_check;";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            int integrityResult = sqlite3_step(preparedStatement);
            
            if (integrityResult == SQLITE_ROW) {
                string integrityString = string((const char *)sqlite3_column_text(preparedStatement, 0));
                databaseState = integrityString == "ok" ? MPDatabaseStateOK : MPDatabaseStateCorrupted;
            }
            
            if (databaseState == MPDatabaseStateCorrupted) {
                MPILogError(@"Database is corrupted.");
            }
            
            sqlite3_finalize(preparedStatement);
        }
    } @catch (NSException *exception) {
        MPILogError(@"Verifying database state - exception %@.", [exception reason]);
        return MPDatabaseStateCorrupted;
    }
    
    return databaseState;
}

#pragma mark Class methods
+ (instancetype)sharedInstance {
    static MPPersistenceController *sharedInstance = nil;
    static dispatch_once_t persistenceControllerPredicate;
    
    dispatch_once(&persistenceControllerPredicate, ^{
        sharedInstance = [[MPPersistenceController alloc] init];
        [sharedInstance openDatabase];
    });
    
    return sharedInstance;
}

#pragma mark Public methods
- (void)archiveSession:(MPSession *)session completionHandler:(void (^)(MPSession *archivedSession))completionHandler {
    [self fetchPreviousSession:^(MPSession *previousSession) {
        if (previousSession) {
            if (session.sessionId == previousSession.sessionId && [session.uuid isEqualToString:previousSession.uuid]) {
                if (completionHandler) {
                    completionHandler(nil);
                }
                
                return;
            } else {
                [self deletePreviousSession];
            }
        }
        
        dispatch_barrier_async(dbQueue, ^{
            sqlite3_stmt *preparedStatement;
            const string sqlStatement = "INSERT INTO previous_session (session_id, uuid, start_time, end_time, background_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
                
                string uuid = string([session.uuid UTF8String]);
                sqlite3_bind_text(preparedStatement, 2, uuid.c_str(), (int)uuid.size(), SQLITE_STATIC);
                
                sqlite3_bind_double(preparedStatement, 3, session.startTime);
                sqlite3_bind_double(preparedStatement, 4, session.endTime);
                sqlite3_bind_double(preparedStatement, 5, session.backgroundTime);
                
                NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
                sqlite3_bind_blob(preparedStatement, 6, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
                
                sqlite3_bind_int64(preparedStatement, 7, [session.sessionNumber integerValue]);
                sqlite3_bind_int(preparedStatement, 8, session.numberOfInterruptions);
                sqlite3_bind_int(preparedStatement, 9, session.eventCounter);
                sqlite3_bind_double(preparedStatement, 10, session.suspendTime);
                sqlite3_bind_double(preparedStatement, 11, session.length);
                
                if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                    MPILogError(@"Error while archiving previous session: %s", sqlite3_errmsg(mParticleDB));
                }
                
                sqlite3_clear_bindings(preparedStatement);
            }
            
            sqlite3_finalize(preparedStatement);
            
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(session);
                });
            }
        });
    }];
}

- (nullable MPSession *)archiveSessionSync:(nonnull MPSession *)session {
    MPSession *previousSession = [self fetchPreviousSessionSync];
    if (previousSession) {
        if (session.sessionId == previousSession.sessionId && [session.uuid isEqualToString:previousSession.uuid]) {
            return nil;
        } else {
            [self deletePreviousSession];
        }
    }
    
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO previous_session (session_id, uuid, start_time, end_time, background_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            string uuid = string([session.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 2, uuid.c_str(), (int)uuid.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 3, session.startTime);
            sqlite3_bind_double(preparedStatement, 4, session.endTime);
            sqlite3_bind_double(preparedStatement, 5, session.backgroundTime);
            
            NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
            sqlite3_bind_blob(preparedStatement, 6, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
            
            sqlite3_bind_int64(preparedStatement, 7, [session.sessionNumber integerValue]);
            sqlite3_bind_int(preparedStatement, 8, session.numberOfInterruptions);
            sqlite3_bind_int(preparedStatement, 9, session.eventCounter);
            sqlite3_bind_double(preparedStatement, 10, session.suspendTime);
            sqlite3_bind_double(preparedStatement, 11, session.length);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while archiving previous session: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return session;
}

- (BOOL)closeDatabase {
    if (!databaseOpen) {
        return YES;
    }
    
    __block int statusCode;
    dispatch_barrier_sync(dbQueue, ^{
        statusCode = sqlite3_close(mParticleDB);
    });
    
    BOOL databaseClosed = statusCode == SQLITE_OK;
    if (databaseClosed) {
        mParticleDB = NULL;
        _databasePath = nil;
        databaseOpen = NO;
    } else {
        MPILogError(@"Error closing database: %d - %s", statusCode, sqlite3_errmsg(mParticleDB));
    }
    
    return databaseClosed;
}

- (NSUInteger)countMesssagesForUploadInSession:(MPSession *)session {
    __block NSUInteger messageCount = 0;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT COUNT(_id) FROM messages WHERE session_id = ? AND (upload_status = ? OR upload_status = ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            sqlite3_bind_int(preparedStatement, 2, MPUploadStatusStream);
            sqlite3_bind_int(preparedStatement, 3, MPUploadStatusBatch);
            
            if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                messageCount = intValue(preparedStatement, 0);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return messageCount;
}

- (NSUInteger)countStandaloneMessages {
    __block NSUInteger messageCount = 0;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT COUNT(_id) FROM standalone_messages";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                messageCount = intValue(preparedStatement, 0);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return messageCount;
}

- (void)deleteConsumerInfo {
    [self deleteCookies];
    
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM consumer_info";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting consumer info: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteExpiredUserNotifications {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM remote_notifications WHERE expiration < ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, [[NSDate date] timeIntervalSince1970]);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting expired user notifications: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteForwardRecordsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds {
    if (MPIsNull(forwardRecordsIds) || forwardRecordsIds.count == 0) {
        return;
    }
    
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        NSString *idsString = [NSString stringWithFormat:@"%@", [forwardRecordsIds componentsJoinedByString:@","]];
        NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM forwarding_records WHERE _id IN (%@)", idsString];
        const string sqlStatement = string([sqlString UTF8String]);
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting forwarding records: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteAllIntegrationAttributes {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM integration_attributes";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting integration attributes: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes {
    if (MPIsNull(integrationAttributes)) {
        return;
    }
    
    [self deleteIntegrationAttributesForKitCode:integrationAttributes.kitCode];
}

- (void)deleteIntegrationAttributesForKitCode:(nonnull NSNumber *)kitCode {
    if (MPIsNull(kitCode)) {
        return;
    }
    
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM integration_attributes WHERE kit_code = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(preparedStatement, 1, [kitCode intValue]);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting integration attributes: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteMessages:(nonnull NSArray<MPMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    
    dispatch_barrier_async(dbQueue, ^{
        NSMutableArray *messageIds = [[NSMutableArray alloc] initWithCapacity:messages.count];
        for (MPMessage *message in messages) {
            [messageIds addObject:@(message.messageId)];
        }
        
        NSString *idsString = [NSString stringWithFormat:@"%@", [messageIds componentsJoinedByString:@","]];
        NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM messages WHERE _id IN (%@)", idsString];
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = string([sqlString UTF8String]);
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting messages: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteMessagesWithNoSession {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM messages WHERE session_id = 0";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting messages with no sessions");
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteNetworkPerformanceMessages {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM messages WHERE message_type = '" + string([kMPMessageTypeNetworkPerformance UTF8String]) + "'";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting network messages from sessions");
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deletePreviousSession {
    dispatch_barrier_sync(dbQueue, ^{
        string sqlStatement = "DELETE FROM previous_session";
        sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, NULL);
    });
}

- (void)deleteProductBag:(MPProductBag *)productBag {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM product_bags WHERE name = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string name = string([productBag.name UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, name.c_str(), (int)name.size(), SQLITE_STATIC);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting product bag: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteAllProductBags {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM product_bags";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting product bags: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp {
    dispatch_barrier_async(dbQueue, ^{
        vector<string> tables = {"messages", "uploads", "sessions", "standalone_messages", "standalone_uploads", "remote_notifications"};
        vector<string> timeFields = {"timestamp", "timestamp", "timestamp", "end_time", "timestamp", "timestamp", "timestamp", "receipt_time"};
        
        size_t idx = 0;
        
        for (auto &table : tables) {
            sqlite3_stmt *preparedStatement;
            const string sqlStatement = "DELETE FROM " + table + " WHERE " + timeFields[idx] + " < ?";
            
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_double(preparedStatement, 1, timestamp);
                
                if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                    MPILogError(@"Error while deleting old records: %s", sqlite3_errmsg(mParticleDB));
                }
                
                sqlite3_clear_bindings(preparedStatement);
            }
            
            sqlite3_finalize(preparedStatement);
            ++idx;
        }
    });
}

- (void)deleteSegments {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "DELETE FROM segment_memberships";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting segment memberships: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
        
        sqlStatement = "DELETE FROM segments";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting segments: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteSession:(MPSession *)session {
    dispatch_barrier_async(dbQueue, ^{
        // Delete messages
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "DELETE FROM messages WHERE session_id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting messages: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        // Delete session
        sqlStatement = "DELETE FROM sessions WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting session: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteSessionSync:(nonnull MPSession *)session {
    dispatch_barrier_sync(dbQueue, ^{
        // Delete messages
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "DELETE FROM messages WHERE session_id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting messages: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        // Delete session
        sqlStatement = "DELETE FROM sessions WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting session: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteUpload:(MPUpload *)upload {
    [self deleteUploadId:upload.uploadId];
}

- (void)deleteUploadId:(int64_t)uploadId {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM uploads WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, uploadId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting upload: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteStandaloneMessage:(MPStandaloneMessage *)standaloneMessage {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM standalone_messages WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, standaloneMessage.messageId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting stand-alone message: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteStandaloneMessageIds:(nonnull NSArray<NSNumber *> *)standaloneMessageIds {
    if (!standaloneMessageIds || standaloneMessageIds.count == 0) {
        return;
    }
    
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        NSString *standaloneMessageIdsList = [NSString stringWithFormat:@"%@", [standaloneMessageIds componentsJoinedByString:@","]];
        NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM standalone_messages WHERE _id IN (%@)", standaloneMessageIdsList];
        const string sqlStatement = string([sqlString UTF8String]);
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting stand-alone messages: %s", sqlite3_errmsg(mParticleDB));
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)deleteStandaloneUpload:(MPStandaloneUpload *)standaloneUpload {
    [self deleteStandaloneUploadId:standaloneUpload.uploadId];
}

- (void)deleteStandaloneUploadId:(int64_t)standaloneUploadId {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM standalone_uploads WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, standaloneUploadId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting stand-alone upload: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs {
    __block vector<MPBreadcrumb *> breadcumbsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, session_uuid, uuid, breadcrumb_data, session_number, timestamp FROM breadcrumbs ORDER BY _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPBreadcrumb *breadcrumb = [[MPBreadcrumb alloc] initWithSessionUUID:stringValue(preparedStatement, 1)
                                                                        breadcrumbId:int64Value(preparedStatement, 0)
                                                                                UUID:stringValue(preparedStatement, 2)
                                                                      breadcrumbData:dataValue(preparedStatement, 3)
                                                                       sessionNumber:@(int64Value(preparedStatement, 4))
                                                                           timestamp:doubleValue(preparedStatement, 5)];
                
                breadcumbsVector.push_back(breadcrumb);
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (breadcumbsVector.empty()) {
        return nil;
    }
    
    NSArray<MPBreadcrumb *> *breadcrumbs = [NSArray arrayWithObjects:&breadcumbsVector[0] count:breadcumbsVector.size()];
    return breadcrumbs;
}

- (MPConsumerInfo *)fetchConsumerInfo {
    NSArray<MPCookie *> *cookies = [self fetchCookies];
    
    __block MPConsumerInfo *consumerInfo = nil;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, mpid, unique_identifier FROM consumer_info";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                consumerInfo = [[MPConsumerInfo alloc] init];
                consumerInfo.consumerInfoId = int64Value(preparedStatement, 0);
                consumerInfo.mpId = @(int64Value(preparedStatement, 1));
                
                unsigned char *columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 2);
                if (columnText != NULL) {
                    consumerInfo.uniqueIdentifier = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
                }
                
                consumerInfo.cookies = cookies;
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return consumerInfo;
}

- (void)fetchConsumerInfo:(void (^)(MPConsumerInfo *consumerInfo))completionHandler {
    NSArray<MPCookie *> *cookies = [self fetchCookies];
    
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, mpid, unique_identifier FROM consumer_info";
        MPConsumerInfo *consumerInfo = nil;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                consumerInfo = [[MPConsumerInfo alloc] init];
                consumerInfo.consumerInfoId = int64Value(preparedStatement, 0);
                consumerInfo.mpId = @(int64Value(preparedStatement, 1));
                
                unsigned char *columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 2);
                if (columnText != NULL) {
                    consumerInfo.uniqueIdentifier = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
                }
                
                consumerInfo.cookies = cookies;
            }
        }
        
        sqlite3_finalize(preparedStatement);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(consumerInfo);
        });
    });
}

- (nullable NSArray<MPCookie *> *)fetchCookies {
    __block vector<MPCookie *> cookiesVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, content, domain, expiration, name FROM cookies";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPCookie *cookie = [[MPCookie alloc] init];
                cookie.cookieId = int64Value(preparedStatement, 0);
                
                unsigned char *columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 1);
                if (columnText != NULL) {
                    cookie.content = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
                }
                
                columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 2);
                if (columnText != NULL) {
                    cookie.domain = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
                }
                
                columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 3);
                if (columnText != NULL) {
                    cookie.expiration = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
                }
                
                cookie.name = stringValue(preparedStatement, 4);
                
                cookiesVector.push_back(cookie);
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (cookiesVector.empty()) {
        return nil;
    }
    
    NSArray<MPCookie *> *cookies = [NSArray arrayWithObjects:&cookiesVector[0] count:cookiesVector.size()];
    return cookies;
}

- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords {
    __block vector<MPForwardRecord *> forwardRecordsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, forwarding_data FROM forwarding_records ORDER BY _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithId:int64Value(preparedStatement, 0)
                                                                                data:dataValue(preparedStatement, 1)];
                
                forwardRecordsVector.push_back(forwardRecord);
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (forwardRecordsVector.empty()) {
        return nil;
    }
    
    NSArray<MPForwardRecord *> *forwardRecords = [NSArray arrayWithObjects:&forwardRecordsVector[0] count:forwardRecordsVector.size()];
    return forwardRecords;
}

- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes {
    __block vector<MPIntegrationAttributes *> integrationAttributesVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT kit_code, attributes_data FROM integration_attributes";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithKitCode:@(intValue(preparedStatement, 0))
                                                                                                   attributesData:dataValue(preparedStatement, 1)];
                
                if (integrationAttributes) {
                    integrationAttributesVector.push_back(integrationAttributes);
                }
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (integrationAttributesVector.empty()) {
        return nil;
    }
    
    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [NSArray arrayWithObjects:&integrationAttributesVector[0] count:integrationAttributesVector.size()];
    return integrationAttributesArray;
}

- (nullable NSArray<MPMessage *> *)fetchMessagesInSession:(MPSession *)session {
    __block vector<MPMessage *> messagesVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? ORDER BY timestamp, _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPMessage *message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                                messageId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                              messageType:stringValue(preparedStatement, 2)
                                                              messageData:dataValue(preparedStatement, 3)
                                                                timestamp:doubleValue(preparedStatement, 4)
                                                             uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                messagesVector.push_back(message);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (messagesVector.empty()) {
        return nil;
    }
    
    NSArray<MPMessage *> *messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
    return messages;
}

- (NSArray<MPMessage *> *)fetchMessagesForUploadingInSession:(MPSession *)session {
    __block vector<MPMessage *> messagesVector;

    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? AND (upload_status = ? OR upload_status = ?) ORDER BY timestamp, _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            sqlite3_bind_int(preparedStatement, 2, MPUploadStatusStream);
            sqlite3_bind_int(preparedStatement, 3, MPUploadStatusBatch);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPMessage *message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                                messageId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                              messageType:stringValue(preparedStatement, 2)
                                                              messageData:dataValue(preparedStatement, 3)
                                                                timestamp:doubleValue(preparedStatement, 4)
                                                             uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                if (message) {
                    messagesVector.push_back(message);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (messagesVector.empty()) {
        return nil;
    }
    
    NSArray<MPMessage *> *messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
    return messages;
}

- (void)fetchMessagesForUploadingInSession:(MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? AND (upload_status = ? OR upload_status = ?) ORDER BY timestamp, _id";
        vector<MPMessage *> messagesVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            sqlite3_bind_int(preparedStatement, 2, MPUploadStatusStream);
            sqlite3_bind_int(preparedStatement, 3, MPUploadStatusBatch);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPMessage *message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                                messageId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                              messageType:stringValue(preparedStatement, 2)
                                                              messageData:dataValue(preparedStatement, 3)
                                                                timestamp:doubleValue(preparedStatement, 4)
                                                             uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                if (message) {
                    messagesVector.push_back(message);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        NSArray<MPMessage *> *messages = nil;
        if (!messagesVector.empty()) {
            messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(messages);
        });
    });
}

- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash {
    __block vector<MPSession *> sessionsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length \
                                     FROM sessions \
                                     WHERE _id IN ((SELECT MAX(_id) FROM sessions), (SELECT (MAX(_id) - 1) FROM sessions)) \
                                     ORDER BY session_number";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPSession *crashSession = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                          UUID:stringValue(preparedStatement, 1)
                                                                backgroundTime:doubleValue(preparedStatement, 2)
                                                                     startTime:doubleValue(preparedStatement, 3)
                                                                       endTime:doubleValue(preparedStatement, 4)
                                                                    attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                                 sessionNumber:@(int64Value(preparedStatement, 6))
                                                         numberOfInterruptions:intValue(preparedStatement, 7)
                                                                  eventCounter:intValue(preparedStatement, 8)
                                                                   suspendTime:doubleValue(preparedStatement, 9)];
                
                crashSession.length = doubleValue(preparedStatement, 10);
                
                sessionsVector.push_back(crashSession);
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (sessionsVector.empty()) {
        return nil;
    }
    
    NSArray<MPSession *> *sessions = [NSArray arrayWithObjects:&sessionsVector[0] count:sessionsVector.size()];
    return sessions;
}

- (void)fetchPreviousSession:(void (^)(MPSession *previousSession))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT session_id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length FROM previous_session";
        MPSession *previousSession = nil;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                previousSession = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                  UUID:stringValue(preparedStatement, 1)
                                                        backgroundTime:doubleValue(preparedStatement, 2)
                                                             startTime:doubleValue(preparedStatement, 3)
                                                               endTime:doubleValue(preparedStatement, 4)
                                                            attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                         sessionNumber:@(int64Value(preparedStatement, 6))
                                                 numberOfInterruptions:intValue(preparedStatement, 7)
                                                          eventCounter:intValue(preparedStatement, 8)
                                                           suspendTime:doubleValue(preparedStatement, 9)];
                
                previousSession.length = doubleValue(preparedStatement, 10);
            }
        }
        
        sqlite3_finalize(preparedStatement);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(previousSession);
        });
    });
}

- (nullable MPSession *)fetchPreviousSessionSync {
    __block MPSession *previousSession = nil;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT session_id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length FROM previous_session";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                previousSession = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                  UUID:stringValue(preparedStatement, 1)
                                                        backgroundTime:doubleValue(preparedStatement, 2)
                                                             startTime:doubleValue(preparedStatement, 3)
                                                               endTime:doubleValue(preparedStatement, 4)
                                                            attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                         sessionNumber:@(int64Value(preparedStatement, 6))
                                                 numberOfInterruptions:intValue(preparedStatement, 7)
                                                          eventCounter:intValue(preparedStatement, 8)
                                                           suspendTime:doubleValue(preparedStatement, 9)];
                
                previousSession.length = doubleValue(preparedStatement, 10);
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return previousSession;
}

- (nullable NSArray<MPProductBag *> *)fetchProductBags {
    __block vector<MPProductBag *> productBagsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT name, product_data FROM product_bags ORDER BY name, timestamp, _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            NSString *lastBagName = nil;
            
            MPProductBag *productBag = nil;
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                NSString *name = stringValue(preparedStatement, 0);
                
                if (![lastBagName isEqualToString:name]) {
                    lastBagName = name;
                    productBag = [[MPProductBag alloc] initWithName:name];
                    productBagsVector.push_back(productBag);
                }
                
                MPProduct *product = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (product) {
                    [productBag.products addObject:product];
                }
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (productBagsVector.empty()) {
        return nil;
    }
    
    NSArray<MPProductBag *> *productBags = [NSArray arrayWithObjects:&productBagsVector[0] count:productBagsVector.size()];
    return productBags;
}

- (nullable NSArray<MPSegment *> *)fetchSegments {
    __block NSMutableArray<MPSegment *> *segments = nil;
    
    dispatch_sync(dbQueue, ^{
        // Block to fetch segment memberships
        NSArray *(^fetchSegmentMemberships)(int64_t segmentId) = ^(int64_t segmentId) {
            NSMutableArray *segmentMemberships = [[NSMutableArray alloc] initWithCapacity:3];
            sqlite3_stmt *preparedStatement;
            const string sqlStatement = "SELECT _id, timestamp, membership_action FROM segment_memberships WHERE segment_id = ? ORDER BY timestamp";
            
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(preparedStatement, 1, segmentId);
                
                while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                    MPSegmentMembership *segmentMembership = [[MPSegmentMembership alloc] initWithSegmentId:segmentId
                                                                                        segmentMembershipId:int64Value(preparedStatement, 0)
                                                                                                  timestamp:doubleValue(preparedStatement, 1)
                                                                                           membershipAction:(MPSegmentMembershipAction)intValue(preparedStatement, 2)];
                    
                    [segmentMemberships addObject:segmentMembership];
                }
                
                sqlite3_clear_bindings(preparedStatement);
            }
            
            sqlite3_finalize(preparedStatement);
            
            if (segmentMemberships.count == 0) {
                segmentMemberships = nil;
            }
            
            return [segmentMemberships copy];
        };
        
        // Fetch segments
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT segment_id, uuid, name, endpoint_ids FROM segments ORDER BY segment_id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            segments = [[NSMutableArray alloc] initWithCapacity:1];
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                int64_t segmentId = int64Value(preparedStatement, 0);
                
                NSArray *endpointIds = [stringValue(preparedStatement, 3) componentsSeparatedByString:@","];
                
                MPSegment *segment = [[MPSegment alloc] initWithSegmentId:@(segmentId)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                                     name:stringValue(preparedStatement, 2)
                                                              memberships:fetchSegmentMemberships(segmentId)
                                                              endpointIds:endpointIds];
                
                [segments addObject:segment];
            }
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (segments.count == 0) {
        segments = nil;
    }
    
    return (NSArray *)segments;
}

- (MPMessage *)fetchSessionEndMessageInSession:(MPSession *)session {
    __block MPMessage *message = nil;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? AND message_type = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            string sessionEndMessageType = MessageTypeName::nameForMessageType(SessionEnd);
            sqlite3_bind_text(preparedStatement, 2, sessionEndMessageType.c_str(), (int)sessionEndMessageType.size(), SQLITE_STATIC);
            
            if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                     messageId:int64Value(preparedStatement, 0)
                                                          UUID:stringValue(preparedStatement, 1)
                                                   messageType:stringValue(preparedStatement, 2)
                                                   messageData:dataValue(preparedStatement, 3)
                                                     timestamp:doubleValue(preparedStatement, 4)
                                                  uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    return message;
}

- (void)fetchSessions:(void (^ _Nonnull)(NSMutableArray<MPSession *> * _Nullable sessions))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length FROM sessions ORDER BY _id";
        
        NSMutableArray<MPSession *> *sessions = nil;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sessions = [[NSMutableArray alloc] initWithCapacity:1];
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPSession *session = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                           backgroundTime:doubleValue(preparedStatement, 2)
                                                                startTime:doubleValue(preparedStatement, 3)
                                                                  endTime:doubleValue(preparedStatement, 4)
                                                               attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                            sessionNumber:@(int64Value(preparedStatement, 6))
                                                    numberOfInterruptions:intValue(preparedStatement, 7)
                                                             eventCounter:intValue(preparedStatement, 8)
                                                              suspendTime:doubleValue(preparedStatement, 9)];
                
                session.length = doubleValue(preparedStatement, 10);
                
                [sessions addObject:session];
            }
        }
        
        sqlite3_finalize(preparedStatement);
        
        if (sessions.count == 0) {
            sessions = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(sessions);
        });
    });
}

- (void)fetchUploadedMessagesInSession:(MPSession *)session excludeNetworkPerformanceMessages:(BOOL)excludeNetworkPerformance completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        
        string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? AND upload_status = ? ";
        if (excludeNetworkPerformance) {
            sqlStatement += "AND message_type != '" + string([kMPMessageTypeNetworkPerformance UTF8String]) + "' ";
        }
        sqlStatement += "ORDER BY timestamp";
        
        vector<MPMessage *> messagesVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            sqlite3_bind_int(preparedStatement, 2, MPUploadStatusUploaded);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPMessage *message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                                messageId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                              messageType:stringValue(preparedStatement, 2)
                                                              messageData:dataValue(preparedStatement, 3)
                                                                timestamp:doubleValue(preparedStatement, 4)
                                                             uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                messagesVector.push_back(message);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        NSArray<MPMessage *> *messages = nil;
        if (!messagesVector.empty()) {
            messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(messages);
        });
    });
}

- (nullable NSArray<MPMessage *> *)fetchUploadedMessagesInSessionSync:(nonnull MPSession *)session {
    __block NSArray<MPMessage *> *messages = nil;

    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM messages WHERE session_id = ? AND upload_status = ? ORDER BY timestamp";
        
        vector<MPMessage *> messagesVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            sqlite3_bind_int(preparedStatement, 2, MPUploadStatusUploaded);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPMessage *message = [[MPMessage alloc] initWithSessionId:session.sessionId
                                                                messageId:int64Value(preparedStatement, 0)
                                                                     UUID:stringValue(preparedStatement, 1)
                                                              messageType:stringValue(preparedStatement, 2)
                                                              messageData:dataValue(preparedStatement, 3)
                                                                timestamp:doubleValue(preparedStatement, 4)
                                                             uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                messagesVector.push_back(message);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        if (!messagesVector.empty()) {
            messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
        }
    });
    
    return messages;
}

- (void)fetchUploadsExceptInSession:(MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPUpload *> * _Nullable uploads))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_data, timestamp, session_id FROM uploads WHERE session_id != ? ORDER BY session_id, _id";
        
        vector<MPUpload *> uploadsVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPUpload *upload = [[MPUpload alloc] initWithSessionId:int64Value(preparedStatement, 4)
                                                              uploadId:int64Value(preparedStatement, 0)
                                                                  UUID:stringValue(preparedStatement, 1)
                                                            uploadData:dataValue(preparedStatement, 2)
                                                             timestamp:doubleValue(preparedStatement, 3)];
                
                uploadsVector.push_back(upload);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        NSArray<MPUpload *> *uploads = nil;
        if (!uploadsVector.empty()) {
            uploads = [NSArray arrayWithObjects:&uploadsVector[0] count:uploadsVector.size()];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(uploads);
        });
    });
}

- (void)fetchUploadsInSession:(MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPUpload *> * _Nullable uploads))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_data, timestamp FROM uploads WHERE session_id = ? ORDER BY _id";
        
        vector<MPUpload *> uploadsVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPUpload *upload = [[MPUpload alloc] initWithSessionId:session.sessionId
                                                              uploadId:int64Value(preparedStatement, 0)
                                                                  UUID:stringValue(preparedStatement, 1)
                                                            uploadData:dataValue(preparedStatement, 2)
                                                             timestamp:doubleValue(preparedStatement, 3)];
                
                uploadsVector.push_back(upload);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        NSArray<MPUpload *> *uploads = nil;
        if (!uploadsVector.empty()) {
            uploads = [NSArray arrayWithObjects:&uploadsVector[0] count:uploadsVector.size()];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(uploads);
        });
    });
}

- (nullable NSArray<MPStandaloneMessage *> *)fetchStandaloneMessages {
    __block vector<MPStandaloneMessage *> messagesVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status FROM standalone_messages ORDER BY _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPStandaloneMessage *standaloneMessage = [[MPStandaloneMessage alloc] initWithMessageId:int64Value(preparedStatement, 0)
                                                                                                   UUID:stringValue(preparedStatement, 1)
                                                                                            messageType:stringValue(preparedStatement, 2)
                                                                                            messageData:dataValue(preparedStatement, 3)
                                                                                              timestamp:doubleValue(preparedStatement, 4)
                                                                                           uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)];
                
                messagesVector.push_back(standaloneMessage);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (messagesVector.empty()) {
        return nil;
    }
    
    NSArray<MPStandaloneMessage *> *standaloneMessages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
    return standaloneMessages;
}

- (nullable NSArray<MPStandaloneUpload *> *)fetchStandaloneUploads {
    __block vector<MPStandaloneUpload *> uploadsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, uuid, message_data, timestamp FROM standalone_uploads ORDER BY _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MPStandaloneUpload *standaloneUpload = [[MPStandaloneUpload alloc] initWithUploadId:int64Value(preparedStatement, 0)
                                                                                               UUID:stringValue(preparedStatement, 1)
                                                                                         uploadData:dataValue(preparedStatement, 2)
                                                                                          timestamp:doubleValue(preparedStatement, 3)];
                
                uploadsVector.push_back(standaloneUpload);
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (uploadsVector.empty()) {
        return nil;
    }
    
    NSArray<MPStandaloneUpload *> *standaloneUploads = [NSArray arrayWithObjects:&uploadsVector[0] count:uploadsVector.size()];
    return standaloneUploads;
}

- (void)purgeMemory {
    sqlite3_db_release_memory(mParticleDB);
    sqlite3_release_memory(4096);
}

- (BOOL)openDatabase {
    if (databaseOpen) {
        return YES;
    }
    
    __block int statusCode;
    dispatch_barrier_sync(dbQueue, ^{
        const char *databasePath = [self.databasePath UTF8String];
        statusCode = sqlite3_open_v2(databasePath, &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE, NULL);
        
        if (statusCode != SQLITE_OK) {
            MPDatabaseState databaseState = [self verifyDatabaseState];
            if (databaseState == MPDatabaseStateCorrupted) {
                [self removeDatabase];
                
                statusCode = sqlite3_open_v2(databasePath, &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE, NULL);
            }
        }
    });
    
    databaseOpen = statusCode == SQLITE_OK;
    if (!databaseOpen) {
        MPILogError(@"Error opening database: %d - %s", statusCode, sqlite3_errmsg(mParticleDB));
        sqlite3_close(mParticleDB);
        mParticleDB = NULL;
    }
    
    return databaseOpen;
}

- (void)saveBreadcrumb:(MPMessage *)message session:(MPSession *)session {
    // Save message
    [self saveMessage:message];
    
    dispatch_barrier_sync(dbQueue, ^{
        // Save breadcrumb
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "INSERT INTO breadcrumbs (session_uuid, uuid, timestamp, breadcrumb_data, session_number) VALUES (?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([session.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
            
            auxString = string([message.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 2, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 3, message.timestamp);
            sqlite3_bind_blob(preparedStatement, 4, [message.messageData bytes], (int)[message.messageData length], SQLITE_STATIC);
            sqlite3_bind_int64(preparedStatement, 5, [session.sessionNumber integerValue]);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing breadcrumb: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        // Prunes breadcrumbs
        sqlStatement = "DELETE FROM breadcrumbs WHERE _id NOT IN (SELECT _id FROM breadcrumbs ORDER BY _id DESC LIMIT ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(preparedStatement, 1, MaxBreadcrumbs);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while pruning breadcrumbs: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        
        vector<string> fields;
        vector<string> params;
        
        if (consumerInfo.uniqueIdentifier) {
            fields.push_back("unique_identifier");
            params.push_back("'" + string([consumerInfo.uniqueIdentifier UTF8String]) + "'");
        }
        
        string sqlStatement = "INSERT INTO consumer_info (mpid";
        for (auto field : fields) {
            sqlStatement += ", " + field;
        }
        
        sqlStatement += ") VALUES (?";
        
        for (auto param : params) {
            sqlStatement += ", " + param;
        }
        
        sqlStatement += ")";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sizeof(void *) == 4) { // 32-bit
                sqlite3_bind_int64(preparedStatement, 1, [consumerInfo.mpId longLongValue]);
            } else if (sizeof(void *) == 8) { // 64-bit
                sqlite3_bind_int64(preparedStatement, 1, [consumerInfo.mpId integerValue]);
            }
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing consumer info: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            consumerInfo.consumerInfoId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        for (MPCookie *cookie in consumerInfo.cookies) {
            if (!cookie.expired) {
                [self saveCookie:cookie forConsumerInfo:consumerInfo];
            }
        }
    });
}

- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO forwarding_records (forwarding_data) VALUES (?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            NSData *data = [forwardRecord dataRepresentation];
            
            if (data) {
                sqlite3_bind_blob(preparedStatement, 1, [data bytes], (int)[data length], SQLITE_STATIC);
            } else {
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing forward record: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            forwardRecord.forwardRecordId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes {
    [self deleteIntegrationAttributesForKitCode:integrationAttributes.kitCode];
    
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO integration_attributes (kit_code, attributes_data) VALUES (?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            NSError *error = nil;
            NSData *attributesData = nil;
            
            @try {
                attributesData = [NSJSONSerialization dataWithJSONObject:integrationAttributes.attributes options:0 error:&error];
            } @catch (NSException *exception) {
            }
            
            if (!attributesData && error != nil) {
                return;
            }
            
            sqlite3_bind_int(preparedStatement, 1, [integrationAttributes.kitCode intValue]);
            sqlite3_bind_blob(preparedStatement, 2, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing integration attributes: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveMessage:(MPMessage *)message {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO messages (message_type, session_id, uuid, timestamp, message_data, upload_status) VALUES (?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([message.messageType UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
            
            sqlite3_bind_int64(preparedStatement, 2, message.sessionId);
            
            auxString = string([message.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 3, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 4, message.timestamp);
            sqlite3_bind_blob(preparedStatement, 5, [message.messageData bytes], (int)[message.messageData length], SQLITE_STATIC);
            sqlite3_bind_int(preparedStatement, 6, message.uploadStatus);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing message: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            message.messageId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveProductBag:(MPProductBag *)productBag {
    [self deleteProductBag:productBag];
    
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO product_bags (name, timestamp, product_data) VALUES (?, ?, ?)";
        
        string auxString;
        NSData *productData;
        
        for (MPProduct *product in productBag.products) {
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                auxString = string([productBag.name UTF8String]);
                sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT); // name
                
                sqlite3_bind_double(preparedStatement, 2, [[NSDate date] timeIntervalSince1970]); // timestamp
                
                productData = [NSKeyedArchiver archivedDataWithRootObject:product];
                sqlite3_bind_blob(preparedStatement, 3, [productData bytes], (int)[productData length], SQLITE_STATIC); // product_data
                
                if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                    MPILogError(@"Error while storing product bag: %s", sqlite3_errmsg(mParticleDB));
                    sqlite3_clear_bindings(preparedStatement);
                    sqlite3_finalize(preparedStatement);
                    return;
                }
                
                sqlite3_clear_bindings(preparedStatement);
            }
            
            sqlite3_finalize(preparedStatement);
        }
    });
}

- (void)saveSegment:(MPSegment *)segment {
    dispatch_barrier_sync(dbQueue, ^{
        void(^saveSegmentMembership)(MPSegmentMembership *segmentMembership) = ^(MPSegmentMembership *segmentMembership) {
            sqlite3_stmt *preparedStatement;
            const string sqlStatement = "INSERT INTO segment_memberships (segment_id, timestamp, membership_action) VALUES (?, ?, ?)";
            
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(preparedStatement, 1, segmentMembership.segmentId);
                sqlite3_bind_double(preparedStatement, 2, segmentMembership.timestamp);
                sqlite3_bind_int(preparedStatement, 3, segmentMembership.action);
                
                if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                    MPILogError(@"Error while storing segment membership: %s", sqlite3_errmsg(mParticleDB));
                    sqlite3_clear_bindings(preparedStatement);
                    sqlite3_finalize(preparedStatement);
                    return;
                }
                
                segmentMembership.segmentMembershipId = sqlite3_last_insert_rowid(mParticleDB);
                
                sqlite3_clear_bindings(preparedStatement);
            }
            
            sqlite3_finalize(preparedStatement);
        };
        
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO segments (segment_id, uuid, name, endpoint_ids) VALUES (?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(preparedStatement, 1, [segment.segmentId intValue]);
            
            string auxString = string([segment.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 2, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
            
            auxString = string([segment.name UTF8String]);
            sqlite3_bind_text(preparedStatement, 3, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
            
            if (segment.endpointIds.count > 0) {
                NSString *endpointIds = [segment.endpointIds componentsJoinedByString:@","];
                auxString = string([endpointIds UTF8String]);
                sqlite3_bind_text(preparedStatement, 4, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            } else {
                sqlite3_bind_null(preparedStatement, 4);
            }
            
            if (SQLITE_DONE == sqlite3_step(preparedStatement)) {
                for (MPSegmentMembership *segmentMembership in segment.memberships) {
                    saveSegmentMembership(segmentMembership);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveSession:(MPSession *)session {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO sessions (uuid, start_time, end_time, background_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([session.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 2, session.startTime);
            sqlite3_bind_double(preparedStatement, 3, session.endTime);
            sqlite3_bind_double(preparedStatement, 4, session.backgroundTime);
            
            NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
            sqlite3_bind_blob(preparedStatement, 5, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
            
            sqlite3_bind_int64(preparedStatement, 6, [session.sessionNumber integerValue]);
            sqlite3_bind_int(preparedStatement, 7, session.numberOfInterruptions);
            sqlite3_bind_int(preparedStatement, 8, session.eventCounter);
            sqlite3_bind_double(preparedStatement, 9, session.suspendTime);
            sqlite3_bind_double(preparedStatement, 10, session.length);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing session: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            session.sessionId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveUpload:(MPUpload *)upload messageIds:(nonnull NSArray<NSNumber *> *)messageIds operation:(MPPersistenceOperation)operation {
    dispatch_barrier_sync(dbQueue, ^{
        // Save upload
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "INSERT INTO uploads (uuid, message_data, timestamp, session_id) VALUES (?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([upload.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_blob(preparedStatement, 2, [upload.uploadData bytes], (int)[upload.uploadData length], SQLITE_STATIC);
            sqlite3_bind_double(preparedStatement, 3, upload.timestamp);
            sqlite3_bind_int64(preparedStatement, 4, upload.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing upload: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            upload.uploadId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        if (messageIds.count > 0) {
            NSString *messageIdsList = [messageIds componentsJoinedByString:@","];
            NSString *sqlString;
            
            switch (operation) {
                case MPPersistenceOperationDelete:
                    sqlString = [NSString stringWithFormat:@"DELETE FROM messages WHERE _id IN (%@)", messageIdsList];
                    sqlStatement = string([sqlString UTF8String]);
                    break;
                    
                case MPPersistenceOperationFlag:
                    sqlString = [NSString stringWithFormat:@"UPDATE messages SET upload_status = %ld WHERE _id IN (%@)", (long)MPUploadStatusUploaded, messageIdsList];
                    sqlStatement = string([sqlString cStringUsingEncoding:NSUTF8StringEncoding]);
                    break;
            }
            
            if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
                if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                    MPILogError(@"Error while post-processing upload: %s", sqlite3_errmsg(mParticleDB));
                }
            }
            
            sqlite3_finalize(preparedStatement);
        }
    });
}

- (void)saveStandaloneMessage:(MPStandaloneMessage *)standaloneMessage {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO standalone_messages (message_type, uuid, timestamp, message_data, upload_status) VALUES (?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([standaloneMessage.messageType UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
            
            auxString = string([standaloneMessage.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 2, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 3, standaloneMessage.timestamp);
            sqlite3_bind_blob(preparedStatement, 4, [standaloneMessage.messageData bytes], (int)[standaloneMessage.messageData length], SQLITE_STATIC);
            sqlite3_bind_int(preparedStatement, 5, standaloneMessage.uploadStatus);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing stand-alone message: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            standaloneMessage.messageId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)saveStandaloneUpload:(MPStandaloneUpload *)standaloneUpload {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO standalone_uploads (uuid, message_data, timestamp) VALUES (?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([standaloneUpload.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_blob(preparedStatement, 2, [standaloneUpload.uploadData bytes], (int)[standaloneUpload.uploadData length], SQLITE_STATIC);
            sqlite3_bind_double(preparedStatement, 3, standaloneUpload.timestamp);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing stand-alone upload: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            standaloneUpload.uploadId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)updateConsumerInfo:(MPConsumerInfo *)consumerInfo {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        string sqlStatement = "UPDATE consumer_info SET mpid = ? ";
        
        if (consumerInfo.uniqueIdentifier) {
            sqlStatement += ", unique_identifier = '" + string([consumerInfo.uniqueIdentifier UTF8String]) + "'";
        }
        
        sqlStatement += " WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            if (sizeof(void *) == 4) { // 32-bit
                sqlite3_bind_int64(preparedStatement, 1, [consumerInfo.mpId longLongValue]);
            } else if (sizeof(void *) == 8) { // 64-bit
                sqlite3_bind_int64(preparedStatement, 1, [consumerInfo.mpId integerValue]);
            }
            
            sqlite3_bind_int64(preparedStatement, 2, consumerInfo.consumerInfoId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while updating consumer info: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        for (MPCookie *cookie in consumerInfo.cookies) {
            if (cookie.expired) {
                if (cookie.cookieId != 0) {
                    [self deleteCookie:cookie];
                }
            } else {
                if (cookie.cookieId == 0) {
                    [self saveCookie:cookie forConsumerInfo:consumerInfo];
                } else {
                    [self updateCookie:cookie];
                }
            }
        }
    });
}

- (void)updateSession:(MPSession *)session {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "UPDATE sessions SET end_time = ?, attributes_data = ?, background_time = ?, number_interruptions = ?, event_count = ?, suspend_time = ?, length = ? WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, session.endTime);
            
            NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
            sqlite3_bind_blob(preparedStatement, 2, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 3, session.backgroundTime);
            sqlite3_bind_int(preparedStatement, 4, session.numberOfInterruptions);
            sqlite3_bind_int(preparedStatement, 5, session.eventCounter);
            sqlite3_bind_double(preparedStatement, 6, session.suspendTime);
            sqlite3_bind_double(preparedStatement, 7, session.length);
            sqlite3_bind_int64(preparedStatement, 8, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while updating session: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

#if TARGET_OS_IOS == 1
- (void)deleteUserNotification:(MParticleUserNotification *)userNotification {
    dispatch_barrier_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "DELETE FROM remote_notifications WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int64(preparedStatement, 1, userNotification.userNotificationId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting user notification: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedLocalUserNotifications {
    __block vector<MParticleUserNotification *> userNotificationsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data FROM remote_notifications WHERE command = ? AND local_alert_time > 0.0 AND local_alert_time < ? ORDER BY _id DESC";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(preparedStatement, 1, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_double(preparedStatement, 2, [[NSDate date] timeIntervalSince1970]);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MParticleUserNotification *userNotification = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (userNotification && userNotification.mode == MPUserNotificationModeLocal) {
                    userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                    userNotificationsVector.push_back(userNotification);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    return userNotifications;
}

- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedRemoteUserNotifications {
    __block vector<MParticleUserNotification *> userNotificationsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data FROM remote_notifications WHERE command != ? ORDER BY _id DESC";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(preparedStatement, 1, MPUserNotificationCommandAlertUserLocalTime);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MParticleUserNotification *userNotification = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (userNotification && userNotification.mode == MPUserNotificationModeRemote) {
                    userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                    userNotificationsVector.push_back(userNotification);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    return userNotifications;
}

- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedLocalUserNotificationsSince:(NSTimeInterval)referenceDate {
    __block vector<MParticleUserNotification *> userNotificationsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data FROM remote_notifications WHERE receipt_time >= ? AND command = ? AND local_alert_time > 0.0 AND local_alert_time < ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, referenceDate);
            sqlite3_bind_int(preparedStatement, 2, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_double(preparedStatement, 3, [[NSDate date] timeIntervalSince1970]);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MParticleUserNotification *userNotification = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (userNotification && userNotification.mode == MPUserNotificationModeLocal) {
                    userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                    userNotificationsVector.push_back(userNotification);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    return userNotifications;
}

- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedRemoteUserNotificationsSince:(NSTimeInterval)referenceDate {
    __block vector<MParticleUserNotification *> userNotificationsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data FROM remote_notifications WHERE receipt_time >= ? AND command != ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, referenceDate);
            sqlite3_bind_int(preparedStatement, 2, MPUserNotificationCommandAlertUserLocalTime);
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MParticleUserNotification *userNotification = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (userNotification && userNotification.mode == MPUserNotificationModeRemote) {
                    userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                    userNotificationsVector.push_back(userNotification);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    return userNotifications;
}

- (NSArray<MParticleUserNotification *> *)fetchUserNotificationCampaignHistorySync {
    __block vector<MParticleUserNotification *> userNotificationsVector;

    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data, campaign_id \
        FROM remote_notifications \
        WHERE expiration >= ? AND (command != ? OR (command = ? AND local_alert_time > 0.0 AND local_alert_time < ?)) \
        ORDER BY campaign_id ASC, receipt_time DESC";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            
            sqlite3_bind_double(preparedStatement, 1, now);
            sqlite3_bind_int(preparedStatement, 2, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_int(preparedStatement, 3, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_double(preparedStatement, 4, now);
            
            MParticleUserNotification *userNotification;
            id notificationObject;
            NSInteger previousCampaignId = 0;
            Class MParticleUserNotificationClass = [MParticleUserNotification class];
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                NSInteger campaignId = sqlite3_column_int(preparedStatement, 2);
                
                if (campaignId != previousCampaignId) {
                    previousCampaignId = campaignId;
                    
                    @try {
                        notificationObject = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                    } @catch (NSException *exception) {
                        notificationObject = nil;
                    }
                    
                    if ([notificationObject isKindOfClass:MParticleUserNotificationClass]) {
                        userNotification = (MParticleUserNotification *)notificationObject;
                    } else {
                        userNotification = nil;
                    }
                    
                    if (userNotification) {
                        userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                        userNotificationsVector.push_back(userNotification);
                    }
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    
    return userNotifications;
}

- (void)fetchUserNotificationCampaignHistory:(void (^ _Nonnull)(NSArray<MParticleUserNotification *> * _Nullable userNotificationCampaignHistory))completionHandler {
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data, campaign_id \
        FROM remote_notifications \
        WHERE expiration >= ? AND (command != ? OR (command = ? AND local_alert_time > 0.0 AND local_alert_time < ?)) \
        ORDER BY campaign_id ASC, receipt_time DESC";
        
        vector<MParticleUserNotification *> userNotificationsVector;
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            
            sqlite3_bind_double(preparedStatement, 1, now);
            sqlite3_bind_int(preparedStatement, 2, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_int(preparedStatement, 3, MPUserNotificationCommandAlertUserLocalTime);
            sqlite3_bind_double(preparedStatement, 4, now);
            
            MParticleUserNotification *userNotification;
            id notificationObject;
            NSInteger previousCampaignId = 0;
            Class MParticleUserNotificationClass = [MParticleUserNotification class];
            
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                NSInteger campaignId = sqlite3_column_int(preparedStatement, 2);
                
                if (campaignId != previousCampaignId) {
                    previousCampaignId = campaignId;
                    
                    @try {
                        notificationObject = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                    } @catch (NSException *exception) {
                        notificationObject = nil;
                    }
                    
                    if ([notificationObject isKindOfClass:MParticleUserNotificationClass]) {
                        userNotification = (MParticleUserNotification *)notificationObject;
                    } else {
                        userNotification = nil;
                    }
                    
                    if (userNotification) {
                        userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                        userNotificationsVector.push_back(userNotification);
                    }
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
        
        NSArray<MParticleUserNotification *> *userNotifications = nil;
        if (!userNotificationsVector.empty()) {
            userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(userNotifications);
        });
    });
}

- (nullable NSArray<MParticleUserNotification *> *)fetchUserNotifications {
    __block vector<MParticleUserNotification *> userNotificationsVector;
    
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "SELECT _id, notification_data FROM remote_notifications ORDER BY _id";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
                MParticleUserNotification *userNotification = [NSKeyedUnarchiver unarchiveObjectWithData:dataValue(preparedStatement, 1)];
                
                if (userNotification) {
                    userNotification.userNotificationId = sqlite3_column_int64(preparedStatement, 0);
                    userNotificationsVector.push_back(userNotification);
                }
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
    
    if (userNotificationsVector.empty()) {
        return nil;
    }
    
    NSArray<MParticleUserNotification *> *userNotifications = [NSArray arrayWithObjects:&userNotificationsVector[0] count:userNotificationsVector.size()];
    return userNotifications;
}

- (void)saveUserNotification:(MParticleUserNotification *)userNotification {
    if (!userNotification.contentId) {
        return;
    }
    
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO remote_notifications (uuid, campaign_id, content_id, command, expiration, local_alert_time, notification_data, receipt_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([userNotification.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_int64(preparedStatement, 2, [userNotification.campaignId integerValue]);
            sqlite3_bind_int64(preparedStatement, 3, [userNotification.contentId integerValue]);
            sqlite3_bind_int(preparedStatement, 4, userNotification.command);
            sqlite3_bind_double(preparedStatement, 5, userNotification.campaignExpiration);
            
            double localAlertTime = userNotification.localAlertDate ? [userNotification.localAlertDate timeIntervalSince1970] : 0.0;
            sqlite3_bind_double(preparedStatement, 6, localAlertTime);
            
            NSData *userNotificationData = [NSKeyedArchiver archivedDataWithRootObject:userNotification];
            sqlite3_bind_blob(preparedStatement, 7, [userNotificationData bytes], (int)[userNotificationData length], SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 8, [userNotification.receiptTime timeIntervalSince1970]);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing user notification: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            userNotification.userNotificationId = sqlite3_last_insert_rowid(mParticleDB);
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}

- (void)updateUserNotification:(MParticleUserNotification *)userNotification {
    dispatch_barrier_sync(dbQueue, ^{
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "UPDATE remote_notifications SET notification_data = ? WHERE _id = ?";
        
        NSData *userNotificationData = [NSKeyedArchiver archivedDataWithRootObject:userNotification];
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_blob(preparedStatement, 1, [userNotificationData bytes], (int)[userNotificationData length], SQLITE_STATIC);
            sqlite3_bind_int64(preparedStatement, 2, userNotification.userNotificationId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while updating user notification: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    });
}
#endif

@end

// Implementation of the C functions
#ifdef __cplusplus
extern "C" {
#endif

static inline NSData *dataValue(sqlite3_stmt *const preparedStatement, const int column) {
    __autoreleasing NSData *data = nil;
    const void *dataBytes = sqlite3_column_blob(preparedStatement, column);
    if (dataBytes == NULL) {
        return nil;
    }
    
    int dataLength = sqlite3_column_bytes(preparedStatement, column);
    
    data = [NSData dataWithBytes:dataBytes length:dataLength];
    return data;
}

static inline NSDictionary *dictionaryRepresentation(sqlite3_stmt *const preparedStatement, const int column) {
    __autoreleasing NSDictionary *dictionary = nil;
    const void *dataBytes = sqlite3_column_blob(preparedStatement, column);
    if (dataBytes == NULL) {
        return nil;
    }
    
    int dataLength = sqlite3_column_bytes(preparedStatement, column);
    
    NSError *error = nil;
    dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:dataBytes length:dataLength]
                                                 options:0
                                                   error:&error];
    
    if (error) {
        MPILogError(@"Error deserializing JSON: %@", error);
        return nil;
    }
    
    return dictionary;
}

static inline double doubleValue(sqlite3_stmt *const preparedStatement, const int column) {
    double doubleValue = sqlite3_column_double(preparedStatement, column);
    return doubleValue;
}

static inline int intValue(sqlite3_stmt *const preparedStatement, const int column) {
    int intValue = sqlite3_column_int(preparedStatement, column);
    return intValue;
}

static inline int64_t int64Value(sqlite3_stmt *const preparedStatement, const int column) {
    int64_t int64Value = sqlite3_column_int64(preparedStatement, column);
    return int64Value;
}

static inline NSString *stringValue(sqlite3_stmt *const preparedStatement, const int column) {
    const unsigned char *columnText = sqlite3_column_text(preparedStatement, column);
    if (columnText == NULL) {
        return nil;
    }
    
    __autoreleasing NSString *stringValue = [NSString stringWithUTF8String:(const char *)columnText];
    return stringValue;
}

#ifdef __cplusplus
}
#endif
