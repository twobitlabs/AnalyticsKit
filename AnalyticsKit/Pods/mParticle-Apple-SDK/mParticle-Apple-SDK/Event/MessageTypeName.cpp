#include "MessageTypeName.h"
#include <algorithm>

namespace mParticle {
    const vector<string> MessageTypeName::names = {"unknown", "ss", "se", "v", "e", "x", "o", "fr", "unknown", "pr", // 0-9
                                                   "ast", "pm", "npe", "bc", "pro", "pre", "cm", "uac", "uic"}; // 10-17
    
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
