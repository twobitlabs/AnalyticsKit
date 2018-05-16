#ifndef __mParticle__MessageTypeName__
#define __mParticle__MessageTypeName__

#include <string>
#include <vector>

using namespace std;

namespace mParticle {
    enum MessageType {
        Unknown = 0,
        SessionStart = 1,
        SessionEnd = 2,
        ScreenView = 3,
        Event = 4,
        CrashReport = 5,
        OptOut = 6,
        FirstRun = 7,
        PreAttribution = 8,
        PushRegistration = 9,
        AppStateTransition = 10,
        PushNotification = 11,
        NetworkPerformance = 12,
        Breadcrumb = 13,
        Profile = 14,
        PushNotificationInteraction = 15,
        CommerceEvent = 16,
        UserAttributeChange = 17,
        UserIdentityChange = 18
    };
    
    class MessageTypeName final {
        static const vector<string> names;
        static const size_t _size;
        
    public:
        static string nameForMessageType(const MessageType messageType);
        static MessageType messageTypeForName(const string &messageTypeName);
        static size_t size();
    };
}

#endif
