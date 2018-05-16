#ifndef __mParticle__Bracket__
#define __mParticle__Bracket__

#include <cstdint>
#include <memory>

using namespace std;

namespace mParticle {
    class Bracket final {
        
    public:
        int64_t mpId = 0;
        short low = 0;
        short high = 100;
        bool shouldForward();
        
        Bracket(const long mpId, const short low, const short high) :
        mpId(mpId), low(low), high(high)
        {}
        
        inline bool operator==(const Bracket &bracket) const {
            return mpId == bracket.mpId &&
                   low == bracket.low &&
                   high == bracket.high;
        }
        
        inline bool operator!=(const Bracket &bracket) const {
            return !(*this == bracket);
        }
    };
}

#endif
