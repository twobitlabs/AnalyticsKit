//
//  MPForwardQueueItem.h
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

#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import "MPKitProtocol.h"

@class MPEvent;
@class MPCommerceEvent;
@class MPKitFilter;
@class MPKitExecStatus;

typedef NS_ENUM(NSUInteger, MPQueueItemType) {
    MPQueueItemTypeEvent = 0,
    MPQueueItemTypeEcommerce,
};

@interface MPForwardQueueItem : NSObject

@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *commerceEvent;
@property (nonatomic, strong, readonly, nullable) MPEvent *event;
@property (nonatomic, copy, readonly, nullable) void (^commerceEventCompletionHandler)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus);
@property (nonatomic, copy, readonly, nullable) void (^eventCompletionHandler)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus);
@property (nonatomic, unsafe_unretained, readonly) MPMessageType messageType;
@property (nonatomic, unsafe_unretained, readonly) MPQueueItemType queueItemType;
@property (nonatomic, unsafe_unretained, readonly, nullable) SEL selector;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler;
- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPEvent *)event messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler;

@end
