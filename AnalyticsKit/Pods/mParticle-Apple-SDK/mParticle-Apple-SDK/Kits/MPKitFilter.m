//
//  MPKitFilter.m
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

#import "MPKitFilter.h"
#import "MPEvent.h"

@implementation MPKitFilter

- (id)init {
    return [self initWithFilter:NO filteredAttributes:nil];
}

- (instancetype)initWithFilter:(BOOL)shouldFilter {
    return [self initWithFilter:shouldFilter filteredAttributes:nil];
}

- (instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(NSDictionary *)filteredAttributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldFilter = shouldFilter;
    _filteredAttributes = filteredAttributes;
    _forwardEvent = nil;
    
    return self;
}

- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter {
    return [self initWithEvent:event shouldFilter:shouldFilter appliedProjections:nil];
}

- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray<MPEventProjection *> *)appliedProjections {
    self = [self initWithFilter:shouldFilter filteredAttributes:event.info];
    if (!self) {
        return nil;
    }
    
    _forwardEvent = event;
    _appliedProjections = appliedProjections;
    
    return self;
}

- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter {
    return [self initWithCommerceEvent:commerceEvent shouldFilter:shouldFilter appliedProjections:nil];
}

- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray<MPEventProjection *> *)appliedProjections {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldFilter = shouldFilter;
    _forwardCommerceEvent = commerceEvent;
    _appliedProjections = appliedProjections;
    
    return self;
}

@end
