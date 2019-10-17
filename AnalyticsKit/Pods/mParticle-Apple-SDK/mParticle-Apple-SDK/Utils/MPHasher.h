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
        static int64_t hashFNV1a(const char *bytes, int length);
    };
}

#endif
