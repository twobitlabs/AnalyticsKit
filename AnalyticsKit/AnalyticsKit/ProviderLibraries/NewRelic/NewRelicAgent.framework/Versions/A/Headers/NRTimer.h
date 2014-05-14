//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2013 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef NanosToMillis
#define NanosToMillis(x) \
x / 1000000
#endif  

#ifndef NanosToSeconds
#define NanosToSeconds(x) \
x / 1000000000
#endif

/*
 A timer implementation that uses mach_absolute_time().
 The timer is started by its initializer.
 */
@interface NRTimer : NSObject

@property (nonatomic, readonly) double startTimeMillis;
@property (nonatomic, readonly) double endTimeMillis;
//Absolute time isn't useful from this timer.
//it uses relative time since last reboot.
- (double) startTimeInMillis;
- (double) endTimeInMillis;
- (void) restartTimer;
- (void) stopTimer;
- (BOOL) hasRunAndFinished;
- (double) timeElapsedInSeconds;
- (double) timeElapsedInMilliSeconds;

@end


double NR_NanosecondsFromTimeInterval(double timeInterval);

#ifdef __cplusplus
}
#endif
