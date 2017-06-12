//
//  MPDatabaseMigrationController.m
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

#import "MPDatabaseMigrationController.h"
#import "sqlite3.h"
#import "MPSession.h"

@interface MPDatabaseMigrationController() {
    dispatch_queue_t dbQueue;
    NSArray *migratedSessions;
}

@property (nonatomic, strong) NSArray<NSNumber *> *databaseVersions;

@end

@implementation MPDatabaseMigrationController

- (instancetype)initWithDatabaseVersions:(NSArray<NSNumber *> *)databaseVersions {
    self = [super init];
    if (self) {
        dbQueue = dispatch_queue_create("com.mParticle.migrationQueue", DISPATCH_QUEUE_SERIAL);
        self.databaseVersions = [databaseVersions copy];
    }
    
    return self;
}

#pragma mark Private methods
- (NSArray *)migratedSessionsInDatabase:(sqlite3 *)database {
    if (migratedSessions) {
        return migratedSessions;
    }
    
    NSMutableArray *sessions = [[NSMutableArray alloc] initWithCapacity:1];
    MPSession *session;
    sqlite3_stmt *statementHandle;
    const char *sqlStatement = "SELECT _id, uuid FROM sessions";
    if (sqlite3_prepare_v2(database, sqlStatement, -1, &statementHandle, NULL) == SQLITE_OK) {
        while (sqlite3_step(statementHandle) == SQLITE_ROW) {
            session = [[MPSession alloc] initWithSessionId:sqlite3_column_int(statementHandle, 0)
                                                      UUID:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statementHandle, 1)]
                                            backgroundTime:0
                                                 startTime:0
                                                   endTime:0
                                                attributes:nil
                                             sessionNumber:@0
                                     numberOfInterruptions:0
                                              eventCounter:0
                                               suspendTime:0];
            
            [sessions addObject:session];
        }
    }
    
    sqlite3_finalize(statementHandle);
    
    migratedSessions = [sessions copy];
    return migratedSessions;
}

- (MPSession *)sessionWithUUID:(NSString *)uuid database:(sqlite3 *)database {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    MPSession *session = [[[self migratedSessionsInDatabase:database] filteredArrayUsingPredicate:predicate] lastObject];
    return session;
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
    } else {
        selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time, length FROM sessions ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO sessions (uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    NSUInteger sessionNumber = 0;
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
        
        sessionNumber = (oldVersionValue >= 10) ? sqlite3_column_int(selectStatementHandle, 4) : 0;
        sqlite3_bind_int64(insertStatementHandle, 5, sessionNumber); // session_number

        NSTimeInterval backgroundTime = 0;
        int numberInterruptions = 0;
        int eventCount = 0;
        NSTimeInterval suspendTime = 0;
        NSTimeInterval length = 0;
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

        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateMessagesFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    MPSession *session;
    const char *uuid;
    int64_t sessionId;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 10) {
        selectStatement = "SELECT message_type, session_id, cfuuid, message_time, message, upload_status FROM messages ORDER BY _id";
    } else {
        selectStatement = "SELECT message_type, session_id, uuid, timestamp, message, upload_status FROM messages ORDER BY _id";
    }

    insertStatement = "INSERT INTO messages (message_type, session_id, uuid, timestamp, message, upload_status) VALUES (?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);

    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // messate_type

        uuid = (const char *)sqlite3_column_text(selectStatementHandle, 2);
        sqlite3_bind_text(insertStatementHandle, 3, uuid, -1, SQLITE_TRANSIENT); // uuid
        
        if (oldVersionValue < 10) {
            uuid = (const char *)sqlite3_column_text(selectStatementHandle, 1);
            session = [self sessionWithUUID:[NSString stringWithUTF8String:uuid] database:newDatabase];
            sessionId = session ? session.sessionId : 0;
            sqlite3_bind_int64(insertStatementHandle, 2, sessionId); // session_id
        } else {
            sqlite3_bind_int64(insertStatementHandle, 2, 0); // session_id
        }
        
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_double(selectStatementHandle, 3)); // timestamp
        
        NSString *messageString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 4)];
        NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
        sqlite3_bind_blob(insertStatementHandle, 5, [messageData bytes], (int)[messageData length], SQLITE_TRANSIENT);  // message_data
        
        sqlite3_bind_int(insertStatementHandle, 6, sqlite3_column_int(selectStatementHandle, 5)); // upload_status
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateUploadsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    MPSession *session;
    const char *uuid;
    int64_t sessionId;
    NSInteger oldVersionValue = [oldVersion integerValue];

    if (oldVersionValue < 10) {
        selectStatement = "SELECT cfuuid, message, message_time, session_id FROM uploads ORDER BY _id";
    } else {
        selectStatement = "SELECT uuid, message, timestamp, session_id FROM uploads ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO uploads (uuid, message, timestamp, session_id) VALUES (?, ?, ?, ?)";
    
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
            uuid = (const char *)sqlite3_column_text(selectStatementHandle, 3);
            session = [self sessionWithUUID:[NSString stringWithUTF8String:uuid] database:newDatabase];
            sessionId = session ? session.sessionId : 0;
            sqlite3_bind_int64(insertStatementHandle, 4, sessionId); // session_id
        } else {
            sqlite3_bind_int64(insertStatementHandle, 4, 0); // session_id
        }
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateSegmentsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 13) {
        return;
    }
    
    if (oldVersionValue > 13) {
        selectStatement = "SELECT segment_id, uuid, name, endpoint_ids FROM segments ORDER BY segment_id";
    } else {
        selectStatement = "SELECT audience_id, uuid, name, endpoint_ids FROM audiences ORDER BY audience_id";
    }

    insertStatement = "INSERT INTO segments (segment_id, uuid, name, endpoint_ids) VALUES (?, ?, ?, ?)";

    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // segment_id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // name
        sqlite3_bind_text(insertStatementHandle, 4, (const char *)sqlite3_column_text(selectStatementHandle, 3), -1, SQLITE_TRANSIENT); // endpoint_ids
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateSegmentMembershipsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 13) {
        return;
    }
    
    if (oldVersionValue > 13) {
        selectStatement = "SELECT _id, segment_id, timestamp, membership_action FROM segment_memberships ORDER BY _id";
    } else {
        selectStatement = "SELECT _id, audience_id, timestamp, membership_action FROM audience_memberships ORDER BY _id";
    }
    
    insertStatement = "INSERT INTO segment_memberships (_id, segment_id, timestamp, membership_action) VALUES (?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // segment_id
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 2)); // timestamp
        sqlite3_bind_int(insertStatementHandle, 4, sqlite3_column_int(selectStatementHandle, 3)); // membership_action
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateStandaloneMessagesFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 16) {
        return;
    }
    
    selectStatement = "SELECT _id, message_type, uuid, timestamp, message_data, upload_status FROM standalone_messages ORDER BY _id";
    insertStatement = "INSERT INTO standalone_messages (_id, message_type, uuid, timestamp, message_data, upload_status) VALUES (?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // messate_type
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_int64(selectStatementHandle, 3)); // timestamp
        sqlite3_bind_blob(insertStatementHandle, 5, sqlite3_column_blob(selectStatementHandle, 4), sqlite3_column_bytes(selectStatementHandle, 4), SQLITE_TRANSIENT); // message_data
        sqlite3_bind_int(insertStatementHandle, 6, sqlite3_column_int(selectStatementHandle, 5)); // upload_status
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateStandaloneUploadsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 16) {
        return;
    }
    
    selectStatement = "SELECT _id, uuid, message_data, timestamp FROM standalone_uploads ORDER BY _id";
    insertStatement = "INSERT INTO standalone_uploads (_id, uuid, message_data, timestamp) VALUES (?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_blob(insertStatementHandle, 3, sqlite3_column_blob(selectStatementHandle, 2), sqlite3_column_bytes(selectStatementHandle, 2), SQLITE_TRANSIENT); // message_data
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_int64(selectStatementHandle, 3)); // timestamp
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateRemoteNotificationsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 17) {
        return;
    }
    
    selectStatement = "SELECT _id, uuid, campaign_id, content_id, command, expiration, local_alert_time, notification_data, receipt_time FROM remote_notifications";
    insertStatement = "INSERT INTO remote_notifications (_id, uuid, campaign_id, content_id, command, expiration, local_alert_time, notification_data, receipt_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_int64(insertStatementHandle, 3, sqlite3_column_int64(selectStatementHandle, 2)); // campaign_id
        sqlite3_bind_int64(insertStatementHandle, 4, sqlite3_column_int64(selectStatementHandle, 3)); // content_id
        sqlite3_bind_int(insertStatementHandle, 5, sqlite3_column_int(selectStatementHandle, 4)); // command
        sqlite3_bind_double(insertStatementHandle, 6, sqlite3_column_double(selectStatementHandle, 5)); // expiration
        sqlite3_bind_double(insertStatementHandle, 7, sqlite3_column_double(selectStatementHandle, 6)); // local_alert_time
        sqlite3_bind_blob(insertStatementHandle, 8, sqlite3_column_blob(selectStatementHandle, 7), sqlite3_column_bytes(selectStatementHandle, 7), SQLITE_TRANSIENT); // notification_data
        sqlite3_bind_double(insertStatementHandle, 9, sqlite3_column_int64(selectStatementHandle, 8)); // receipt_time
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateProductBagsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 22) {
        return;
    }
    
    selectStatement = "SELECT _id, name, timestamp, product_data FROM product_bags";
    insertStatement = "INSERT INTO product_bags (_id, name, timestamp, product_data) VALUES (?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_text(insertStatementHandle, 2, (const char *)sqlite3_column_text(selectStatementHandle, 1), -1, SQLITE_TRANSIENT); // name
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 2)); // timestamp
        sqlite3_bind_blob(insertStatementHandle, 4, sqlite3_column_blob(selectStatementHandle, 3), sqlite3_column_bytes(selectStatementHandle, 3), SQLITE_TRANSIENT); // product_data
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateForwardingRecordsFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 23) {
        return;
    }
    
    selectStatement = "SELECT _id, forwarding_data FROM forwarding_records";
    insertStatement = "INSERT INTO product_bags (_id, forwarding_data) VALUES (?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_blob(insertStatementHandle, 2, sqlite3_column_blob(selectStatementHandle, 1), sqlite3_column_bytes(selectStatementHandle, 1), SQLITE_TRANSIENT); // forwarding_data
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateConsumerInfoFromDatabase:(sqlite3 *)oldDatabase version:(NSNumber *)oldVersion toDatabase:(sqlite3 *)newDatabase {
    const char *selectStatement, *insertStatement;
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    NSInteger oldVersionValue = [oldVersion integerValue];
    
    if (oldVersionValue < 22) {
        return;
    }
    
    // Consumer Info
    selectStatement = "SELECT _id, mpid, unique_identifier FROM consumer_info";
    insertStatement = "INSERT INTO consumer_info (_id, mpid, unique_identifier) VALUES (?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // mpid
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // unique_identifier
        
        sqlite3_step(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
    
    // Cookies
    selectStatement = "SELECT _id, consumer_info_id, content, domain, expiration, name FROM cookies";
    insertStatement = "INSERT INTO cookies (_id, consumer_info_id, content, domain, expiration, name) VALUES (?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0)); // _id
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1)); // consumer_info_id
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // content
        sqlite3_bind_text(insertStatementHandle, 4, (const char *)sqlite3_column_text(selectStatementHandle, 3), -1, SQLITE_TRANSIENT); // domain
        sqlite3_bind_text(insertStatementHandle, 5, (const char *)sqlite3_column_text(selectStatementHandle, 4), -1, SQLITE_TRANSIENT); // expiration
        sqlite3_bind_text(insertStatementHandle, 6, (const char *)sqlite3_column_text(selectStatementHandle, 5), -1, SQLITE_TRANSIENT); // name
        
        sqlite3_step(insertStatementHandle);
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

#pragma mark Public methods
- (void)migrateDatabaseFromVersion:(NSNumber *)oldVersion {
    dispatch_sync(dbQueue, ^{
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSNumber *currentDatabaseVersion = [self.databaseVersions lastObject];
        NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", currentDatabaseVersion];
        NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        sqlite3 *oldmParticleDB, *mParticleDB;
        NSString *dbPath;
        
        if (sqlite3_open([databasePath UTF8String], &mParticleDB) != SQLITE_OK) {
            return;
        }
        
        if ([oldVersion isEqualToNumber:self.databaseVersions[0]]) {
            databaseName = @"mParticle.db";
        } else {
            databaseName = [NSString stringWithFormat:@"mParticle%@.db", oldVersion];
        }
        
        dbPath = [documentsDirectory stringByAppendingPathComponent:databaseName];
        
        if (![fileManager fileExistsAtPath:dbPath] || (sqlite3_open([dbPath UTF8String], &oldmParticleDB) != SQLITE_OK)) {
            return;
        }
        
        [self migrateSessionsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateMessagesFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateUploadsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateSegmentsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateSegmentMembershipsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateStandaloneMessagesFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateStandaloneUploadsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateRemoteNotificationsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateProductBagsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateForwardingRecordsFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateConsumerInfoFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];
        [self migrateIntegrationAttributesFromDatabase:oldmParticleDB version:oldVersion toDatabase:mParticleDB];

        sqlite3_close(oldmParticleDB);
        [fileManager removeItemAtPath:dbPath error:nil];
        sqlite3_close(mParticleDB);
    });
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
