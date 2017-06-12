//
//  MessageTypeName.h
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
