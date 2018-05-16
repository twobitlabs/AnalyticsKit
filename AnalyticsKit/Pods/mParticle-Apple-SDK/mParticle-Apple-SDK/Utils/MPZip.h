#ifndef __mParticle__Zip__
#define __mParticle__Zip__

#include <stdio.h>
#include <tuple>
#include <memory>

using namespace std;

namespace mParticle {
    class Zip final {
    public:
        static tuple<unsigned char *, unsigned int> compress(const unsigned char *data, unsigned int length);
        static tuple<unsigned char *, unsigned int> expand(const unsigned char *data, unsigned int length);
    };
}

#endif
