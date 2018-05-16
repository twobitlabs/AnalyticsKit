#include "MPZip.h"
#include <string.h>
#include "zlib.h"

namespace mParticle {

#define ZIP_PAGE_SIZE 16384
    
    tuple<unsigned char *, unsigned int> Zip::compress(const unsigned char *data, unsigned int length) {
        tuple<unsigned char *, unsigned int> compressedData = {nullptr, 0};
        
        if (length == 0) {
            return {nullptr, 0};
        }
        
        z_stream stream;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL;
        stream.opaque = Z_NULL;
        stream.total_out = 0;
        stream.next_in = (Bytef *)data;
        stream.avail_in = length;
        
        // Compression Levels:
        //  Z_NO_COMPRESSION
        //  Z_BEST_SPEED
        //  Z_BEST_COMPRESSION
        //  Z_DEFAULT_COMPRESSION
        
        if (deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) {
            return {nullptr, 0};
        }
        
        unsigned int numberOfMemBlocks = 1;
        unsigned int bufferSize = numberOfMemBlocks * ZIP_PAGE_SIZE;
        get<0>(compressedData) = new unsigned char[bufferSize];
        
        do {
            if (stream.total_out >= bufferSize) {
                unsigned int previousBufferSize = bufferSize;
                unsigned char *previousData = new unsigned char[previousBufferSize];
                memmove(previousData, get<0>(compressedData), previousBufferSize);
                delete [] get<0>(compressedData);
                
                ++numberOfMemBlocks;
                bufferSize = numberOfMemBlocks * ZIP_PAGE_SIZE;
                get<0>(compressedData) = new unsigned char[bufferSize];
                memmove(get<0>(compressedData), previousData, previousBufferSize);
                delete [] previousData;
            }
            
            stream.next_out = get<0>(compressedData) + stream.total_out;
            stream.avail_out = (uInt)(bufferSize - stream.total_out);
            
            deflate(&stream, Z_FINISH);
        } while (stream.avail_out == 0);
        
        deflateEnd(&stream);
        
        get<1>(compressedData) = (unsigned int)stream.total_out;
        
        return compressedData;
    }
    
    tuple<unsigned char *, unsigned int> Zip::expand(const unsigned char *data, unsigned int length) {
        tuple<unsigned char *, unsigned int> expandedData = {nullptr, 0};

        if (length == 0) {
            return {nullptr, 0};
        }
        
        z_stream stream;
        stream.next_in = (Bytef *)data;
        stream.avail_in = length;
        stream.total_out = 0;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL;
        
        if (inflateInit2(&stream, (15+32)) != Z_OK) {
            return {nullptr, 0};
        }
        
        unsigned long full_length = length;
        unsigned long half_length = length / 2;
        unsigned long bufferSize = full_length + half_length;
        get<0>(expandedData) = new unsigned char[bufferSize];

        bool done = false;
        while (!done) {
            // Make sure we have enough room and reset the lengths.
            if (stream.total_out >= bufferSize) {
                unsigned long previousBufferSize = bufferSize;
                unsigned char *previousData = new unsigned char[previousBufferSize];
                memmove(previousData, get<0>(expandedData), previousBufferSize);
                delete [] get<0>(expandedData);
                
                bufferSize += half_length;
                get<0>(expandedData) = new unsigned char[bufferSize];
                memmove(get<0>(expandedData), previousData, previousBufferSize);
                delete [] previousData;
            }
            
            stream.next_out = get<0>(expandedData) + stream.total_out;
            stream.avail_out = (uInt)(bufferSize - stream.total_out);
            
            // Inflate another chunk.
            int status = inflate(&stream, Z_SYNC_FLUSH);
            
            if (status == Z_STREAM_END) {
                done = true;
            } else if (status != Z_OK) {
                break;
            }
        }
        
        if (inflateEnd(&stream) != Z_OK) {
            return {nullptr, 0};
        }
        
        if (done) {
            get<1>(expandedData) = (unsigned int)stream.total_out;
            return expandedData;
        } else {
            return {nullptr, 0};
        }
    }
}
