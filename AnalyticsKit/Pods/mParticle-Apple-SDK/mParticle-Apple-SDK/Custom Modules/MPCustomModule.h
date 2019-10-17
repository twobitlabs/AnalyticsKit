#import <Foundation/Foundation.h>

@class MPCustomModulePreference;

@interface MPCustomModule : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, strong, readonly, nonnull) NSNumber *customModuleId;
@property (nonatomic, strong, readonly, nullable) NSArray<MPCustomModulePreference *> *preferences;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)customModuleDictionary;
- (nonnull NSDictionary *)dictionaryRepresentation;

@end
