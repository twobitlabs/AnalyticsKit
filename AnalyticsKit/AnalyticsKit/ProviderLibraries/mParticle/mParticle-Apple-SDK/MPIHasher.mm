//
//  MPIHasher.mm
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
