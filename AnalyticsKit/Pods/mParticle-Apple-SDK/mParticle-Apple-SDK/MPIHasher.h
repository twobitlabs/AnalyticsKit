#import <Foundation/Foundation.h>

@interface MPIHasher : NSObject

+ (uint64_t)hashFNV1a:(NSData *)data;
+ (NSString *)hashString:(NSString *)stringToHash;
+ (NSString *)hashStringUTF16:(NSString *)stringToHash;

@end
