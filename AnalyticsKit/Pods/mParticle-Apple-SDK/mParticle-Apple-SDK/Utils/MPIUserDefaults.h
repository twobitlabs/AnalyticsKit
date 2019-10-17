#import <Foundation/Foundation.h>

@class MPKitConfiguration;

@interface MPIUserDefaults : NSObject

+ (nonnull instancetype)standardUserDefaults;
- (nullable id)mpObjectForKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)setMPObject:(nullable id)value forKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)removeMPObjectForKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)removeMPObjectForKey:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(nonnull NSString *)key;
- (void)synchronize;
- (void)migrateUserKeysWithUserId:(nonnull NSNumber *)userId;
- (void)migrateFirstLastSeenUsers;
- (void)setSharedGroupIdentifier:(nullable NSString *)groupIdentifier;
- (void)migrateToSharedGroupIdentifier:(nonnull NSString *)groupIdentifier;
- (void)migrateFromSharedGroupIdentifier;
- (nullable NSDictionary *)getConfiguration;
- (nullable NSArray *)getKitConfigurations;
- (void)setConfiguration:(nonnull NSDictionary *)responseConfiguration eTag:(nonnull NSString *)eTag requestTimestamp:(NSTimeInterval)requestTimestamp currentAge:(nonnull NSString *)currentAge maxAge:(nullable NSNumber *)maxAge;
- (void)migrateConfiguration;
- (void)deleteConfiguration;
- (void)resetDefaults;
- (BOOL)isExistingUserId:(nonnull NSNumber *)userId;
- (nonnull NSArray<NSNumber *> *)userIDsInUserDefaults;
- (BOOL)isConfigurationExpired;
- (BOOL)isConfigurationParametersOutdated;

+ (NSString *_Nullable)stringFromDeviceToken:(NSData *_Nonnull)deviceToken;

@end
