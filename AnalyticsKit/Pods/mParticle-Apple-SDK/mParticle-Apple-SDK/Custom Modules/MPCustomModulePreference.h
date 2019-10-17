#import <Foundation/Foundation.h>
#import "MPIConstants.h"

typedef NS_ENUM(NSUInteger, MPCustomModuleId) {
    MPCustomModuleIdAppBoy = 28
};

@interface MPCustomModulePreference : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly, nonnull) NSNumber *moduleId;
@property (nonatomic, strong, readonly, nonnull) NSString *defaultValue;
@property (nonatomic, strong, readonly, nonnull) NSString *readKey;
@property (nonatomic, strong, nonnull) id value;
@property (nonatomic, strong, readonly, nonnull) NSString *writeKey;
@property (nonatomic, readonly) MPDataType dataType;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)preferenceDictionary location:(nullable NSString *)location moduleId:(nonnull NSNumber *)moduleId;

@end
