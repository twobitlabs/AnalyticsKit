#import <Foundation/Foundation.h>

#pragma mark - MPCookie

extern NSString * _Nonnull const kMPCKContent;
extern NSString * _Nonnull const kMPCKDomain;
extern NSString * _Nonnull const kMPCKExpiration;

@interface MPCookie : NSObject <NSSecureCoding>

@property (nonatomic, unsafe_unretained) int64_t cookieId;
@property (nonatomic, strong, nullable) NSString *content;
@property (nonatomic, strong, nullable) NSString *domain;
@property (nonatomic, strong, nullable) NSString *expiration;
@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, unsafe_unretained, readonly) BOOL expired;

- (nonnull instancetype)initWithName:(nonnull NSString *)name configuration:(nonnull NSDictionary *)configuration;
- (nullable NSDictionary *)dictionaryRepresentation;

@end


#pragma mark - MPConsumerInfo
@interface MPConsumerInfo : NSObject <NSSecureCoding>

@property (nonatomic, unsafe_unretained) int64_t consumerInfoId;
@property (nonatomic, strong, nullable) NSArray<MPCookie *> *cookies;
@property (nonatomic, strong, nullable) NSString *uniqueIdentifier;
@property (nonatomic, strong, nullable, readonly) NSString *deviceApplicationStamp;

- (nullable NSDictionary *)cookiesDictionaryRepresentation;
- (void)updateWithConfiguration:(nonnull NSDictionary *)configuration;

@end
