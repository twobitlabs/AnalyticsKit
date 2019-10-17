#import <Foundation/Foundation.h>

@interface MPAppboy : NSObject <NSSecureCoding>

@property (nonatomic, strong) NSArray *userInfoPerUser;
@property (nonatomic, strong) NSData *pushToken;
@property (nonatomic, strong) NSString *deviceIdentifier;
@property (nonatomic, strong) id sessionsPerUser;
@property (nonatomic, strong) NSArray *feedArrayUpdateTime;
@property (nonatomic, strong) id acksPerUser;
@property (nonatomic, strong) NSString *externalUserId;

- (NSString *)jsonString;

@end
