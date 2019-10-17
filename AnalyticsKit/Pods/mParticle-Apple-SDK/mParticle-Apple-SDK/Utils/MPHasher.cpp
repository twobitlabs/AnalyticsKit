#include "MPHasher.h"
#include "EventTypeName.h"
#include <algorithm>

namespace mParticle {
    __attribute__((no_sanitize("integer")))
    int Hasher::hashFromString(const string &stringToHash) {
        if (stringToHash.empty()) {
            return 0;
        }

        string lowerCaseStringToHash = stringToHash;
        transform(lowerCaseStringToHash.begin(), lowerCaseStringToHash.end(), lowerCaseStringToHash.begin(), ::tolower);
        
        int hash = 0;
        for (auto &character : lowerCaseStringToHash) {
            hash = ((hash << 5) - hash) + character;
        }
        
        return hash;
    }

    string Hasher::hashString(string stringToHash) {
        if (stringToHash.empty()) {
            return "";
        }
        
        auto hash = Hasher::hashFromString(stringToHash);
        
        auto hashString = to_string(hash);
        return hashString;
    }
    
    vector<string> Hasher::hashedEventTypes(const vector<int> &eventTypes) {
        vector<string> hashedEventTypes;

        if (eventTypes.empty()) {
            return hashedEventTypes;
        }
        
        for (auto &eventType : eventTypes) {
            auto eventTypeString = to_string(eventType);
            auto hashedEventType = Hasher::hashString(eventTypeString);
            hashedEventTypes.push_back(hashedEventType);
        }
        
        return hashedEventTypes;
    }
    
    vector<string> Hasher::hashedAllEventTypes() {
        vector<int> eventTypes(EventTypeName::count);
        
        int i = 0;
        for_each(eventTypes.begin(), eventTypes.end(), [&i](int &eventType) {eventType = i++;});
        
        vector<string> hashes = Hasher::hashedEventTypes(eventTypes);
        return hashes;
    }
    
    string Hasher::hashEvent(string eventName, string eventType) {
        eventName.append(eventType);
        return Hasher::hashString(eventName);
    }

    __attribute__((no_sanitize("integer")))
    int64_t Hasher::hashFNV1a(const char *bytes, int length) {
        // FNV-1a hashing
        int64_t rampHash = 0xcbf29ce484222325;
        
        int i = 0;
        while (i < length) {
            rampHash = (rampHash ^ bytes[i]) * 0x100000001B3;
            i += 1;
        }
        
        return rampHash;
    }
}
