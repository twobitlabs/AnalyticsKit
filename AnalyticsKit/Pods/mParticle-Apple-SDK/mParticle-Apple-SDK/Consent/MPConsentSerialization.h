#import <Foundation/Foundation.h>

@class MPConsentState;

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentSerialization : NSObject

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state;
+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state;
+ (nullable MPConsentState *)consentStateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
