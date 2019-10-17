#import "MPDatabaseMigrationController.h"
#import "sqlite3.h"
#import "MPSession.h"
#import "MPIUserDefaults.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPPersistenceController.h"
#import "MPIConstants.h"
#import "MPILogger.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

@interface MPCart ()

- (nonnull instancetype)initWithUserId:(NSNumber *_Nonnull)userId;
- (void)migrate;

@end


@interface MPDatabaseMigrationController() {
    NSArray *migratedSessions;
}

@property (nonatomic, strong) NSArray<NSNumber *> *databaseVersions;

@end

@implementation MPDatabaseMigrationController

- (instancetype)initWithDatabaseVersions:(NSArray<NSNumber *> *)databaseVersions {
    self = [super init];
    if (self) {
        self.databaseVersions = [databaseVersions copy];
    }
    
    return self;
}

#pragma mark Private methods

- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp version:(NSNumber *)oldVersion fromDatabase:(sqlite3 *)mParticleDB {
    char *errMsg;
    NSString *sqlStatement = @"BEGIN TRANSACTION";
    
    if (sqlite3_exec(mParticleDB, sqlStatement.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK) {
        MPILogError("Problem Beginning SQL Transaction: %@\n", sqlStatement);
    }
    
    NSInteger oldVersionValue = [oldVersion integerValue];
    NSArray *statements = nil;
    
    if (oldVersionValue < 10) {
        statements = @[
                       @"DELETE FROM messages WHERE message_time < ?",
                       @"DELETE FROM uploads WHERE message_time < ?",
                       @"DELETE FROM sessions WHERE end_time < ?"
                       ];
    } else {
        statements = @[
                       @"DELETE FROM messages WHERE timestamp < ?",
                       @"DELETE FROM uploads WHERE timestamp < ?",
                       @"DELETE FROM sessions WHERE end_time < ?"
                       ];
    }
    
    sqlite3_stmt *preparedStatement;
    for (NSString *sqlStatement in statements) {
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.UTF8String, (int)[sqlStatement length], &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, timestamp);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting old records: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        sqlite3_finalize(preparedStatement);
    }
    
    sqlStatement = @"END TRANSACTION";
    
    if (sqlite3_exec(mParticleDB, sqlStatement.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK) {
        MPILogError("Problem Ending SQL Transaction: %@\n", sqlStatement);
    }
}

- (void)migrateUserDefaultsWithVersion:(NSNumber *)oldVersion {
    NSInteger oldVersionValue = [oldVersion integerValue];
    if (oldVersionValue < 26) {
        [[MPIUserDefaults standardUserDefaults] migrateUserKeysWithUserId:[MPPersistenceController mpId]];
    }
    if (oldVersionValue < 28) {
        [[MPIUserDefaults standardUserDefaults] migrateFirstLastSeenUsers];
    }
}

- (void)migrateCartWithVersion:(NSNumber *)oldVersion {
    NSInteger oldVersionValue = [oldVersion integerValue];
    if (oldVersionValue < 26) {
        MPCart *newCart = [[MPCart alloc] initWithUserId:[MPPersistenceController mpId]];
        [newCart migrate];
    }
}

- (void)migrateSessionsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    
    NSInteger oldVersionValue = [oldVersion integerValue];
    if (oldVersionValue < 6) {
        selectStatement = "SELECT cfuuid, start_time, end_time, attributes FROM sessions ORDER BY _id";
    } else if (oldVersionValue < 10) {
        selectStatement = "SELECT cfuuid, start_time, end_time, attributes_data FROM sessions ORDER BY _id";
    } else if (oldVersionValue < 16) {
        selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number FROM sessions ORDER BY _id";
    } else if (oldVersionValue < 20) {
        selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time FROM sessions ORDER BY _id";
    } else if (oldVersionValue < 26) {
        selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time, length FROM sessions ORDER BY _id";
    } else {
        selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids FROM sessions ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO sessions (uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // uuid
        
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 1)); // start_time
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_double(selectStatementHandle, 2)); // end_time

        // attributes_data
        NSData *attributesData;
        NSUInteger attributesLength;
        if (oldVersionValue < 6) {
            NSString *attributesString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 3)];
            attributesData = [attributesString dataUsingEncoding:NSUTF8StringEncoding];
            attributesLength = [attributesData length];
        } else {
            const char *attributesBytes = sqlite3_column_blob(selectStatementHandle, 3);
            attributesLength = sqlite3_column_bytes(selectStatementHandle, 3);
            attributesData = [NSData dataWithBytes:attributesBytes length:attributesLength];
        }
        sqlite3_bind_blob(insertStatementHandle, 5, [attributesData bytes], (int)attributesLength, SQLITE_TRANSIENT);
        
        sqlite3_bind_int64(insertStatementHandle, 6, 0); //session_number Deprecated

        NSTimeInterval backgroundTime = 0;
        int numberInterruptions = 0;
        int eventCount = 0;
        NSTimeInterval suspendTime = 0;
        NSTimeInterval length = 0;
        NSNumber *mpId;
        if (oldVersionValue < 26) {
            mpId = [MPPersistenceController mpId];
        } else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 10));
        }
        if (oldVersionValue > 15) {
            backgroundTime = sqlite3_column_double(selectStatementHandle, 5);
            numberInterruptions = sqlite3_column_int(selectStatementHandle, 6);
            eventCount = sqlite3_column_int(selectStatementHandle, 7);
            suspendTime = sqlite3_column_double(selectStatementHandle, 8);
            
            if (oldVersionValue > 19) {
                length = sqlite3_column_double(selectStatementHandle, 9);
            } else {
                length = MAX(sqlite3_column_double(selectStatementHandle, 2) - sqlite3_column_double(selectStatementHandle, 1), 0);
            }
        }
        sqlite3_bind_double(insertStatementHandle, 2, backgroundTime); // background_time
        sqlite3_bind_int(insertStatementHandle, 7, numberInterruptions); // number_interruptions
        sqlite3_bind_int(insertStatementHandle, 8, eventCount); // event_count
        sqlite3_bind_double(insertStatementHandle, 9, suspendTime); // suspend_time
        sqlite3_bind_double(insertStatementHandle, 10, length); // length
        sqlite3_bind_int64(insertStatementHandle, 11, [mpId longLongValue]); // mpid
        sqlite3_bind_text(insertStatementHandle, 12, (const char *)[mpId stringValue].UTF8String, -1, SQLITE_TRANSIENT); // session_user_ids

        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateMessagesFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    const char *uuid;
    int64_t sessionId;
    NSNumber *mpId;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 10) {
        selectStatement = "SELECT message_type, session_id, cfuuid, message_time, message_data, upload_status FROM messages ORDER BY _id";
    } else if (oldVersionValue < 26) {
        selectStatement = "SELECT message_type, session_id, uuid, timestamp, message_data, upload_status FROM messages ORDER BY _id";
    } else {
        selectStatement = "SELECT message_type, session_id, uuid, timestamp, message_data, upload_status, mpid FROM messages ORDER BY _id";
    }

    insertStatement = "INSERT INTO messages (message_type, session_id, uuid, timestamp, message_data, upload_status, mpid) VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);

    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // message_type

        uuid = (const char *)sqlite3_column_text(selectStatementHandle, 2);
        sqlite3_bind_text(insertStatementHandle, 3, uuid, -1, SQLITE_TRANSIENT); // uuid
        
        if (oldVersionValue < 10) {
            sqlite3_bind_null(insertStatementHandle, 2); // session_id
        } else {
            sessionId = sqlite3_column_int64(selectStatementHandle, 1);
            if (sessionId != 0) {
                sqlite3_bind_int64(insertStatementHandle, 2, sessionId); // session_id
            }
            else {
                sqlite3_bind_null(insertStatementHandle, 2); // session_id
            }
        }
        
        if (oldVersionValue < 26) {
            mpId = [MPPersistenceController mpId];
        } else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 6));
        }
        
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_double(selectStatementHandle, 3)); // timestamp
        
        NSString *messageString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 4)];
        NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
        sqlite3_bind_blob(insertStatementHandle, 5, [messageData bytes], (int)[messageData length], SQLITE_TRANSIENT);  // message_data
        
        sqlite3_bind_int(insertStatementHandle, 6, sqlite3_column_int(selectStatementHandle, 5)); // upload_status
        
        sqlite3_bind_int64(insertStatementHandle, 7, [mpId longLongValue]); // mpid
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateUploadsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    const char *uuid;
    int64_t sessionId;
    NSInteger oldVersionValue = [oldVersion integerValue];

    if (oldVersionValue < 10) {
        selectStatement = "SELECT cfuuid, message_data, message_time, session_id FROM uploads ORDER BY _id";
    } else if (oldVersionValue < 28) {
        selectStatement = "SELECT uuid, message_data, timestamp, session_id FROM uploads ORDER BY _id";
    } else {
        selectStatement = "SELECT uuid, message_data, timestamp, session_id, upload_type FROM uploads ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO uploads (uuid, message_data, timestamp, session_id, upload_type) VALUES (?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        uuid = (const char *)sqlite3_column_text(selectStatementHandle, 0);
        sqlite3_bind_text(insertStatementHandle, 1, uuid, -1, SQLITE_TRANSIENT); // uuid
        
        NSString *messageString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 1)];
        NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
        sqlite3_bind_blob(insertStatementHandle, 2, [messageData bytes], (int)[messageData length], SQLITE_TRANSIENT);  // message_data
        
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 2)); // timestamp
        
        if (oldVersionValue < 10) {
            sqlite3_bind_null(insertStatementHandle, 4); // session_id
        } else {
            sessionId = sqlite3_column_int64(selectStatementHandle, 3);
            if (sessionId != 0) {
                sqlite3_bind_int64(insertStatementHandle, 4, sessionId); // session_id
            }
            else {
                sqlite3_bind_null(insertStatementHandle, 4); // session_id
            }
        }
        
        if (oldVersionValue < 28) {
            sqlite3_bind_int64(insertStatementHandle, 5, MPUploadTypeMessage); // upload_type
        } else {
            sqlite3_bind_int64(insertStatementHandle, 5, sqlite3_column_int64(selectStatementHandle, 4)); // upload_type
        }
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateSegmentsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    NSNumber *mpId;
    
    if (oldVersionValue < 13) {
        return;
    }
    
    if (oldVersionValue < 14) {
        selectStatement = "SELECT audience_id, uuid, name, endpoint_ids FROM audiences ORDER BY audience_id";
    } else if (oldVersionValue < 26) {
        selectStatement = "SELECT segment_id, uuid, name, endpoint_ids FROM segments ORDER BY segment_id";
    } else {
        selectStatement = "SELECT segment_id, uuid, name, endpoint_ids, mpid FROM segments ORDER BY segment_id";
    }

    insertStatement = "INSERT INTO segments (segment_id, uuid, name, endpoint_ids, mpid) VALUES (?, ?, ?, ?, ?)";

    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // segment_id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // name
        sqlite3_bind_text(insertStatementHandle, 4, (const char *)sqlite3_column_text(selectStatementHandle, 3), -1, SQLITE_TRANSIENT); // endpoint_ids
        if (oldVersionValue < 26) {
            mpId = [MPPersistenceController mpId];
        } else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 4));
        }
        sqlite3_bind_int64(insertStatementHandle, 5, [mpId longLongValue]); // mpid
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateSegmentMembershipsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    NSNumber *mpId;
    
    if (oldVersionValue < 13) {
        return;
    }
    
    if (oldVersionValue < 14) {
        selectStatement = "SELECT _id, audience_id, timestamp, membership_action FROM audience_memberships ORDER BY _id";
    } else if (oldVersionValue < 26) {
        selectStatement = "SELECT _id, segment_id, timestamp, membership_action FROM segment_memberships ORDER BY _id";
    } else {
        selectStatement = "SELECT _id, segment_id, timestamp, membership_action, mpid FROM segment_memberships ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO segment_memberships (_id, segment_id, timestamp, membership_action, mpid) VALUES (?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // segment_id
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 2)); // timestamp
        sqlite3_bind_int(insertStatementHandle, 4, sqlite3_column_int(selectStatementHandle, 3)); // membership_action
        
        if (oldVersionValue < 26) {
            mpId = [MPPersistenceController mpId];
        } else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 4));
        }
        sqlite3_bind_int64(insertStatementHandle, 5, [mpId longLongValue]); // mpid
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateForwardingRecordsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    NSNumber *mpId;
    
    if (oldVersionValue < 23) {
        return;
    }
    
    if (oldVersionValue < 27) {
        selectStatement = "SELECT _id, forwarding_data FROM forwarding_records";
    } else {
        selectStatement = "SELECT _id, forwarding_data, mpid FROM forwarding_records";
    }
    
    insertStatement = "INSERT INTO forwarding_records (_id, forwarding_data, mpid) VALUES (?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_blob(insertStatementHandle, 2, sqlite3_column_blob(selectStatementHandle, 1), sqlite3_column_bytes(selectStatementHandle, 1), SQLITE_TRANSIENT); // forwarding_data
        if (oldVersionValue < 26) {
            mpId = [MPPersistenceController mpId];
        }
        else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 2));
        }
        sqlite3_bind_int64(insertStatementHandle, 3, [mpId longLongValue]); // mpid
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateConsumerInfoFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    NSNumber *mpId;
    
    if (oldVersionValue < 22) {
        return;
    }
    
    // Consumer Info
    selectStatement = "SELECT _id, mpid, unique_identifier FROM consumer_info";
    insertStatement = "INSERT INTO consumer_info (_id, mpid, unique_identifier) VALUES (?, ?, ?)";
    
    selectStatementHandle = NULL;
    insertStatementHandle = NULL;
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    int64_t userId = 0;
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        userId = sqlite3_column_int64(selectStatementHandle, 1);
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int64(insertStatementHandle, 2, userId); // mpid
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // unique_identifier
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
    
    // Cookies
    if (oldVersionValue < 26) {
        selectStatement = "SELECT _id, consumer_info_id, content, domain, expiration, name FROM cookies";
    } else {
        selectStatement = "SELECT _id, consumer_info_id, content, domain, expiration, name, mpid FROM cookies";
    }
    
    insertStatement = "INSERT INTO cookies (_id, consumer_info_id, content, domain, expiration, name, mpid) VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // consumer_info_id
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // content
        sqlite3_bind_text(insertStatementHandle, 4, (const char *)sqlite3_column_text(selectStatementHandle, 3), -1, SQLITE_TRANSIENT); // domain
        sqlite3_bind_text(insertStatementHandle, 5, (const char *)sqlite3_column_text(selectStatementHandle, 4), -1, SQLITE_TRANSIENT); // expiration
        sqlite3_bind_text(insertStatementHandle, 6, (const char *)sqlite3_column_text(selectStatementHandle, 5), -1, SQLITE_TRANSIENT); // name
        if (oldVersionValue < 26) {
            mpId = @(userId);
            [MPPersistenceController setMpid:mpId];
        } else {
            mpId = @(sqlite3_column_int64(selectStatementHandle, 6));
        }
        
        sqlite3_bind_int64(insertStatementHandle, 7, [mpId longLongValue]); // mpid
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateIntegrationAttributesFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 25) {
        return;
    }

    selectStatement = "SELECT _id, kit_code, attributes_data FROM integration_attributes";
    insertStatement = "INSERT INTO integration_attributes (_id, kit_code, attributes_data) VALUES (?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // kit_code        
        sqlite3_bind_blob(insertStatementHandle, 3, sqlite3_column_blob(selectStatementHandle, 2), sqlite3_column_bytes(selectStatementHandle, 2), SQLITE_TRANSIENT); // attributes_data
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)removeSessionNumberFile {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *sessionNumberPath = [documentsDirectory stringByAppendingPathComponent:@"SessionNumber"];
    
    if ([fileManager fileExistsAtPath:sessionNumberPath]) {
        [fileManager removeItemAtPath:sessionNumberPath error:nil];
    }
}

#pragma mark Public methods

- (void)migrateDatabaseFromVersion:(NSNumber *)oldVersion {
    [self migrateDatabaseFromVersion:oldVersion deleteDbFile:YES];
}

- (void)migrateDatabaseFromVersion:(NSNumber *)oldVersion deleteDbFile:(BOOL)deleteDbFile {
    [self removeSessionNumberFile];
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSNumber *currentDatabaseVersion = [self.databaseVersions lastObject];
    NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", currentDatabaseVersion];
    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    sqlite3 *oldmParticleDB, *mParticleDB;
    NSString *dbPath;
    
    if (sqlite3_open_v2([databasePath UTF8String], &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK) {
        return;
    }
    
    if ([oldVersion isEqualToNumber:self.databaseVersions[0]]) {
        databaseName = @"mParticle.db";
    } else {
        databaseName = [NSString stringWithFormat:@"mParticle%@.db", oldVersion];
    }
    
    dbPath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    
    if (![fileManager fileExistsAtPath:dbPath] || (sqlite3_open_v2([dbPath UTF8String], &oldmParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK)) {
        return;
    }
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    [self deleteRecordsOlderThan:(currentTime - SEVEN_DAYS) version:oldVersion fromDatabase:oldmParticleDB];
    [self migrateConsumerInfoFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateUserDefaultsWithVersion:oldVersion];
    [self migrateSessionsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateMessagesFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateUploadsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateSegmentsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateSegmentMembershipsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateForwardingRecordsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
    [self migrateIntegrationAttributesFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];

    sqlite3_close(oldmParticleDB);
    if (deleteDbFile) {
        [fileManager removeItemAtPath:dbPath error:nil];
    }
    sqlite3_close(mParticleDB);
}

- (NSNumber *)needsMigration {
    NSMutableArray *oldDatabaseVersions = [self.databaseVersions mutableCopy];
    [oldDatabaseVersions removeLastObject];
    [oldDatabaseVersions sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        NSComparisonResult comparisonResult = [obj1 compare:obj2];
        switch (comparisonResult) {
            case NSOrderedAscending:
                return NSOrderedDescending;
                
            case NSOrderedDescending:
                return NSOrderedAscending;
                
            default:
                return NSOrderedSame;
        }
    }];
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL needsMigration = NO;
    NSString *dbPath, *databaseName;
    NSNumber *databaseVersion = nil;
    NSInteger numberOfVersions = oldDatabaseVersions.count;
    for (NSInteger i = 0; i < numberOfVersions; ++i) {
        databaseVersion = [oldDatabaseVersions[i] copy];
        
        if ([databaseVersion isEqualToNumber:self.databaseVersions[0]]) {
            databaseName = @"mParticle.db";
        } else {
            databaseName = [NSString stringWithFormat:@"mParticle%@.db", databaseVersion];
        }
        
        dbPath = [documentsDirectory stringByAppendingPathComponent:databaseName];
        
        needsMigration = [fileManager fileExistsAtPath:dbPath];
        if (needsMigration) {
            break;
        }
    }
    
    if (!needsMigration) {
        databaseVersion = nil;
    }
    
    return databaseVersion;
}

@end
