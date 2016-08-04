//
//  MPILogger.h
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

#ifndef mParticleSDK_MPILogger_h
#define mParticleSDK_MPILogger_h

#import "MPStateMachine.h"
#import "MPEnums.h"

#define MPILogger(loggerLevel, format, ...) if ([MPStateMachine sharedInstance].logLevel >= (loggerLevel) && [MPStateMachine sharedInstance].logLevel != MPILogLevelNone) { \
                                                NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                            }

#define MPILogError(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPILogLevelError) { \
                                     NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                 }

#define MPILogWarning(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPILogLevelWarning) { \
                                       NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                   }

#define MPILogDebug(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPILogLevelDebug) { \
                                     NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                 }

#define MPILogVerbose(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPILogLevelVerbose) { \
                                       NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                   }

#endif
