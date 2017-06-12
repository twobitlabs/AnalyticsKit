//
//  MPForwardQueueItem.m
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

#import "MPForwardQueueItem.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPKitFilter.h"
#import "MPKitExecStatus.h"
#import "MPForwardQueueParameters.h"

@implementation MPForwardQueueItem

@synthesize queueItemType = _queueItemType;

- (nullable instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !commerceEvent || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEcommerce;
    _commerceEvent = commerceEvent;
    _commerceEventCompletionHandler = [completionHandler copy];
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector event:(nonnull MPEvent *)event messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPEvent * _Nonnull forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !selector || !event || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeEvent;
    _selector = selector;
    _event = event;
    _messageType = messageType;
    _eventCompletionHandler = [completionHandler copy];
    
    return self;
}

- (nullable instancetype)initWithSelector:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType completionHandler:(void (^ _Nonnull)(_Nonnull id<MPKitProtocol> kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus))completionHandler {
    self = [super init];
    if (!self || !selector || !completionHandler) {
        return nil;
    }
    
    _queueItemType = MPQueueItemTypeGeneralPurpose;
    _selector = selector;
    _generalPurposeCompletionHandler = [completionHandler copy];
    _queueParameters = parameters;
    _messageType = messageType;
    
    return self;
}

@end
