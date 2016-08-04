//
//  MPBracket.h
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
