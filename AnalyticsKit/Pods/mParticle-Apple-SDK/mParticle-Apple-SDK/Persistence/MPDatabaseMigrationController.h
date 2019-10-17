#import <Foundation/Foundation.h>

@interface MPDatabaseMigrationController : NSObject

@property (nonatomic, readonly, nonnull) NSArray *databaseVersions;

- (nonnull instancetype)initWithDatabaseVersions:(nonnull NSArray<NSNumber *> *)databaseVersions;
- (void)migrateDatabaseFromVersion:(nonnull NSNumber *)oldVersion;
- (void)migrateDatabaseFromVersion:(nonnull NSNumber *)oldVersion deleteDbFile:(BOOL)deleteDbFile;
- (nullable NSNumber *)needsMigration;

@end
