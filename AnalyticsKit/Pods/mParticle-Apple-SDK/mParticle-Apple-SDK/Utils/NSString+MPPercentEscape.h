#import <Foundation/Foundation.h>

@interface NSString(MPPercentEscape)

+ (nonnull NSString *)percentEscapeString:(nonnull NSString *)stringToEscape;
- (nonnull NSString *)percentEscape;

@end
