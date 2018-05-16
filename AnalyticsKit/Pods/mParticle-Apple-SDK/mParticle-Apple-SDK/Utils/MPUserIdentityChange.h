#import <Foundation/Foundation.h>
#import "MPEnums.h"

#pragma mark - MPUserIdentityInstance
@interface MPUserIdentityInstance : NSObject

@property (nonatomic, strong, nullable) NSString *value;
@property (nonatomic, strong, nonnull) NSDate *dateFirstSet;
@property (nonatomic, unsafe_unretained) MPUserIdentity type;
@property (nonatomic, unsafe_unretained) BOOL isFirstTimeSet;

- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value;
- (nonnull instancetype)initWithType:(MPUserIdentity)type value:(nullable NSString *)value dateFirstSet:(nonnull NSDate *)dateFirstSet isFirstTimeSet:(BOOL)isFirstTimeSet;
- (nonnull instancetype)initWithUserIdentityDictionary:(nonnull NSDictionary<NSString *, id> *)userIdentityDictionary;
- (nonnull NSMutableDictionary<NSString *, id> *)dictionaryRepresentation;

@end

#pragma mark - MPUserIdentityChange
@interface MPUserIdentityChange : NSObject

@property (nonatomic, strong, nullable) MPUserIdentityInstance *userIdentityNew;
@property (nonatomic, strong, nullable) MPUserIdentityInstance *userIdentityOld;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, unsafe_unretained, readonly) BOOL changed;

- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities;
- (nonnull instancetype)initWithNewUserIdentity:(nullable MPUserIdentityInstance *)userIdentityNew oldUserIdentity:(nullable MPUserIdentityInstance *)userIdentityOld timestamp:(nullable NSDate *)timestamp userIdentities:(nullable NSArray<NSDictionary<NSString *, id> *> *)userIdentities;

@end
