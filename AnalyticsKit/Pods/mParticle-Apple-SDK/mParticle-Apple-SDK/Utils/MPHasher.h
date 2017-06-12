//
//  MPHasher.h
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

#ifndef __mParticle__Hasher__
#define __mParticle__Hasher__

#include <stdio.h>
#include <string>
#include <vector>

using namespace std;

namespace mParticle {
    class Hasher final {
        
    public:
        static int hashFromString(const string &stringToHash);
        static string hashString(string stringToHash);
        static vector<string> hashedEventTypes(const vector<int> &eventTypes);
        static vector<string> hashedAllEventTypes();
        static string hashEvent(string eventName, string eventType);
        static uint64_t hashFNV1a(const char *bytes, int length);
    };
}

#endif
