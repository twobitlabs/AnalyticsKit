//
//  MPKitContainer.h
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
#import <Foundation/Foundation.h>
#import "MPExtensionProtocol.h"
#import "MPKitProtocol.h"

@class MPKitFilter;
@class MPKitExecStatus;
@class MPCommerceEvent;
@class MPEvent;
@class MPForwardQueueParameters;

@interface MPKitContainer : NSObject

+ (BOOL)registerKit:(nonnull id<MPExtensionKitProtocol>)kitRegister;
+ (nullable NSSet<id<MPExtensionKitProtocol>> *)registeredKits;
+ (nonnull MPKitContainer *)sharedInstance;

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry;
- (void)configureKits:(nullable NSArray<NSDictionary *> *)kitsConfiguration;
- (void)removeKitConfigurationAtPath:(nonnull NSString *)kitPath;
- (void)removeAllKitConfigurations;
- (nullable NSArray<NSNumber *> *)supportedKits;

- (void)forwardCommerceEventCall:(nonnull MPCommerceEvent *)commerceEvent kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector event:(nullable MPEvent *)event messageType:(MPMessageType)messageType userInfo:(nullable NSDictionary *)userInfo kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributeKey:(nonnull NSString *)key value:(nullable id)value kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userAttributes:(nonnull NSDictionary *)userAttributes kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, NSDictionary * _Nullable forwardAttributes))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector userIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector errorMessage:(nullable NSString *)errorMessage exception:(nullable NSException *)exception eventInfo:(nullable NSDictionary *)eventInfo kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;
- (void)forwardSDKCall:(nonnull SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType kitHandler:(void (^ _Nonnull)(id<MPKitProtocol> _Nonnull kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitExecStatus * _Nonnull * _Nonnull execStatus))kitHandler;

@end
