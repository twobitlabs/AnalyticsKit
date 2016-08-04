//
//  MediaControl.cpp
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

#include "MediaControl.h"

namespace mParticle {
    vector<MediaActionDescription> MediaControl::mediaActionDescriptions = {{.name = "Play", .action = "pl"},
                                                                            {.name = "Stop", .action = "stp"},
                                                                            {.name = "Update Position", .action = "upp"},
                                                                            {.name = "Update Metadata", .action = "umt"}};
    size_t const MediaControl::count = 4;
    
    MediaActionDescription MediaControl::actionDescriptionForMediaAction(MediaAction mediaAction) {
        int idx = mediaAction - 1;
        auto actionDescription = MediaControl::mediaActionDescriptions[idx];
        return actionDescription;
    }
}
