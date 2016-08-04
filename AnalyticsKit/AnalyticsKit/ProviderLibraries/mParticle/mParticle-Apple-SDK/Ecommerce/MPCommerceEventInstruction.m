//
//  MPCommerceEventInstruction.m
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

#import "MPCommerceEventInstruction.h"

@implementation MPCommerceEventInstruction

- (id)init {
    return [self initWithInstruction:MPCommerceInstructionEvent event:nil product:nil];
}

- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event {
    return [self initWithInstruction:instruction event:event product:nil];
}

- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event product:(MPProduct *)product {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _instruction = instruction;
    _event = event;
    _product = product;
    
    return self;
}

@end
