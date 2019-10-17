#import "MPZip.h"
#include "zlib.h"

@implementation MPZip

+ (NSData *)compressedDataFromData:(NSData *)data {
    if (data.length == 0) {
        return data;
    }
    
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.total_out = 0;
    stream.next_in = (Bytef *)data.bytes;
    stream.avail_in = (uint)data.length;
    
    if (deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        return nil;
    }
    
    static const NSUInteger chunkSize = 16384;
    NSMutableData *output = [NSMutableData dataWithLength:chunkSize];
    
    do {
        if (stream.total_out >= output.length) {
            output.length += chunkSize;
        }
        stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
        stream.avail_out = (uInt)(output.length - stream.total_out);

        deflate(&stream, Z_FINISH);
    } while (stream.avail_out == 0);

    deflateEnd(&stream);
    output.length = stream.total_out;
    return output;
}

@end
