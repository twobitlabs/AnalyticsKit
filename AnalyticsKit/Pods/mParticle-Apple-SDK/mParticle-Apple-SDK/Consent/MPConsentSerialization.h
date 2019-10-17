#import <Foundation/Foundation.h>

@class MPConsentState;
@class MPConsentKitFilter;

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentSerialization : NSObject

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state;
+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state;
+ (nullable MPConsentState *)consentStateFromString:(NSString *)string;
+ (nullable MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary;

@end

NS_ASSUME_NONNULL_END
