#import "MPIHasher.h"
#include "MPHasher.h"

@implementation MPIHasher

+ (uint64_t)hashFNV1a:(NSData *)data {
    uint64_t dataHash = mParticle::Hasher::hashFNV1a((const char *)[data bytes], (int)[data length]);
    return dataHash;
}

+ (NSString *)hashString:(NSString *)stringToHash {
    NSString *result = [NSString stringWithCString:mParticle::Hasher::hashString([stringToHash cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
    return result;
}

@end
