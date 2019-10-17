#ifndef mParticleSDK_MPILogger_h
#define mParticleSDK_MPILogger_h

#import "MPEnums.h"

#define MPILogger(loggerLevel, format, ...) if ([MParticle sharedInstance].logLevel >= (loggerLevel) && [MParticle sharedInstance].logLevel != MPILogLevelNone) { \
                                                NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                            }

#define MPILogError(format, ...) if ([MParticle sharedInstance].logLevel >= MPILogLevelError) { \
                                     NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                 }

#define MPILogWarning(format, ...) if ([MParticle sharedInstance].logLevel >= MPILogLevelWarning) { \
                                       NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                   }

#define MPILogDebug(format, ...) if ([MParticle sharedInstance].logLevel >= MPILogLevelDebug) { \
                                     NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                 }

#define MPILogVerbose(format, ...) if ([MParticle sharedInstance].logLevel >= MPILogLevelVerbose) { \
                                       NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                   }

#endif
