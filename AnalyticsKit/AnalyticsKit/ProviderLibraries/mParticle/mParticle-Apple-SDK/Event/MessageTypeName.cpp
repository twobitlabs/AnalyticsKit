//
//  MessageTypeName.cpp
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

#include "MessageTypeName.h"
#include <algorithm>

namespace mParticle {
    const vector<string> MessageTypeName::names = {"unknown", "ss", "se", "v", "e", "x", "o", "fr", "unknown", "pr", // 0-9
                                                   "ast", "pm", "npe", "bc", "pro", "pre", "cm"}; // 10-16
    
    const size_t MessageTypeName::count = MessageTypeName::names.size();
    
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
}
