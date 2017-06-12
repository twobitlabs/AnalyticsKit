//
//  MPZip.h
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
