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

#ifdef __BLOCKS__
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef NRGCDOverride_H
#define NRGCDOverride_H

#define dispatch_async(...) NR__dispatch_async(__VA_ARGS__)
#define dispatch_sync(...) NR__dispatch_sync(__VA_ARGS__)
#define dispatch_after(...) NR__dispatch_after(__VA_ARGS__)
#define dispatch_apply(...) NR__dispatch_apply(__VA_ARGS__)
#define _dispatch_once NR__dispatch_once

void NR__dispatch_async(dispatch_queue_t queue, dispatch_block_t block);
void NR__dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);
void NR__dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);
void NR__dispatch_apply(size_t iterations, dispatch_queue_t queue, void(^block)(size_t));
void NR__dispatch_once(dispatch_once_t *once, dispatch_block_t block);

#endif // NRGCDOverride_H

#ifdef __cplusplus
}
#endif

#endif // __BLOCKS__
