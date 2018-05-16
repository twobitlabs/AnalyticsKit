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
