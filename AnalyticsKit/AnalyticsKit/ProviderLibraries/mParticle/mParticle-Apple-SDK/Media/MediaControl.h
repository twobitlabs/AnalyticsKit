//
//  MediaControl.h
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

#ifndef __mParticle__MediaControl__
#define __mParticle__MediaControl__

#include <string>
#include <vector>

using namespace std;

namespace mParticle {
    enum MediaAction {
        Play = 1,
        Stop,
        PlaybackPosition,
        Metadata
    };
    
    struct MediaActionDescription {
        string name;
        string action;
    };
    
    class MediaControl {
        static vector<MediaActionDescription> mediaActionDescriptions;
        
    public:
        static const size_t count;
        static MediaActionDescription actionDescriptionForMediaAction(MediaAction mediaAction);
    };
}

#endif
