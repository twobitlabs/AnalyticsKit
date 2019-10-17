#include "MessageTypeName.h"
#include <algorithm>
#import "MPIConstants.h"

namespace mParticle {
    
    const vector<string> MessageTypeName::names = {
        string(kMPMessageTypeStringUnknown.UTF8String),
        string(kMPMessageTypeStringSessionStart.UTF8String),
        string(kMPMessageTypeStringSessionEnd.UTF8String),
        string(kMPMessageTypeStringScreenView.UTF8String),
        string(kMPMessageTypeStringEvent.UTF8String),
        string(kMPMessageTypeStringCrashReport.UTF8String),
        string(kMPMessageTypeStringOptOut.UTF8String),
        string(kMPMessageTypeStringFirstRun.UTF8String),
        string(kMPMessageTypeStringPreAttribution.UTF8String),
        string(kMPMessageTypeStringPushRegistration.UTF8String),
        string(kMPMessageTypeStringAppStateTransition.UTF8String),
        string(kMPMessageTypeStringPushNotification.UTF8String),
        string(kMPMessageTypeStringNetworkPerformance.UTF8String),
        string(kMPMessageTypeStringBreadcrumb.UTF8String),
        string(kMPMessageTypeStringProfile.UTF8String),
        string(kMPMessageTypeStringPushNotificationInteraction.UTF8String),
        string(kMPMessageTypeStringCommerceEvent.UTF8String),
        string(kMPMessageTypeStringUserAttributeChange.UTF8String),
        string(kMPMessageTypeStringUserIdentityChange.UTF8String),
        string(kMPMessageTypeStringMedia.UTF8String)
    };
    
    const size_t MessageTypeName::_size = MessageTypeName::names.size();
    
    string MessageTypeName::nameForMessageType(const MessageType messageType) {
        auto messageName = MessageTypeName::names[messageType];
        return messageName;
    }
    
    MessageType MessageTypeName::messageTypeForName(const string &messageTypeName) {
        MessageType messageType = Unknown;
        
        const auto firstMessageType = names.begin();
        const auto lastMessageType = names.end();
        const auto iterator = find(firstMessageType, lastMessageType, messageTypeName);
        
        if (iterator != lastMessageType) {
            messageType = static_cast<MessageType>(distance(firstMessageType, iterator));
        }
        
        return messageType;
    }
    
    size_t MessageTypeName::size() {
        return _size;
    }
}
