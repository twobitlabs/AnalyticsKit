//
//  MPKitRegister.h
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
#import "MPKitProtocol.h"
#import "MPExtensionProtocol.h"

@interface MPKitRegister : NSObject <MPExtensionKitProtocol>

/**
 Kit code. Obtained from mParticle and informed to the Core SDK
 */
@property (nonatomic, strong, nonnull, readonly) NSNumber *code;

/**
 Instance of the 3rd party kit wrapper implementation. The instance is allocated by the mParticle SDK and uses the class name provided by the className parameter.
 You should not set this property. It's lifecycle is managed by the mParticle SDK
 @see className
 @see MPKitProtocol
 */
@property (nonatomic, strong, nullable) id<MPKitProtocol> wrapperInstance;

/**
 Kit name. Obtained from the 3rd party library provider and informed to the Core SDK
 */
@property (nonatomic, strong, nonnull, readonly) NSString *name;

/**
 Name of the class implementing the wrapper to forward calls to 3rd party kits
 */
@property (nonatomic, strong, nonnull, readonly) NSString *className;

/**
 Indicates whether a 3rd party kit should be started immediately or it should wait until launch info such as deep-linking is available, then start
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL startImmediately;

/**
 Allocates and initializes a register to a 3rd party kit implementation
 @param name Kit name. Obtained from the 3rd party library provider and informed to the Core SDK
 @param className Name of the class implementing the wrapper to forward calls to 3rd party kits
 @param startImmediately Indicates whether a 3rd party kit should be started immediately or it should wait until launch info such as deep-linking is available, then start
 @returns An instance of a kit register or nil if a kit register could not be instantiated
 */
- (nullable instancetype)initWithName:(nonnull NSString *)name className:(nonnull NSString *)className startImmediately:(BOOL)startImmediately __attribute__((objc_designated_initializer));

@end
