#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPZip : NSObject

+ (nullable NSData *)compressedDataFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
