#import "NSString+MPPercentEscape.h"

@implementation NSString(MPPercentEscape)

+ (NSString *)percentEscapeString:(NSString *)stringToEscape {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *escapedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                    (__bridge CFStringRef)stringToEscape,
                                                                                                    (__bridge CFStringRef)@"@&=%",
                                                                                                    (__bridge CFStringRef)@"; ",
                                                                                                    kCFStringEncodingUTF8);
#pragma clang diagnostic pop
    
    return escapedString;
}

- (NSString *)percentEscape {
    return [NSString percentEscapeString:self];
}

@end
