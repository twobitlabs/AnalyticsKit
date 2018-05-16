#include "MPBracket.h"
#include <stdlib.h>

namespace mParticle {
    bool Bracket::shouldForward() {
        if (mpId == 0 || high == 0) {
            return false;
        }
        
        auto userBucket = static_cast<int>(llabs(mpId >> 8) % 100);
        return userBucket >= low && userBucket < high;
    }
}
