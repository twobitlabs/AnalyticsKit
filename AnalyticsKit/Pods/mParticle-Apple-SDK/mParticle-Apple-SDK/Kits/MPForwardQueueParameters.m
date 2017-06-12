//
//  MPForwardQueueParameters.m
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

#import "MPForwardQueueParameters.h"
#import "MPIConstants.h"

@interface MPForwardQueueParameters()

@property (nonatomic, strong) NSMutableArray *parameters;

@end


@implementation MPForwardQueueParameters

- (instancetype)init {
    self = [super init];
    return self;
}

- (instancetype)initWithParameters:(nonnull NSArray *)parameters {
    self = [super init];
    if (self) {
        if (!MPIsNull(parameters) && parameters.count > 0) {
            _parameters = [[NSMutableArray alloc] initWithArray:parameters];
        }
    }
    
    return self;
}

#pragma Private accessors
- (NSMutableArray *)parameters {
    if (!_parameters) {
        _parameters = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _parameters;
}

#pragma mark Public methods
- (NSUInteger)count {
    return _parameters ? _parameters.count : 0;
}

- (void)addParameter:(id)parameter {
    id addParameter = parameter;
    if (!addParameter) {
        addParameter = [NSNull null];
    }
    
    [self.parameters addObject:addParameter];
}

#pragma mark subscripting
- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    id parameter = nil;
    if (idx < self.parameters.count) {
        parameter = self.parameters[idx];
        
        if ((NSNull *)parameter == [NSNull null]) {
            parameter = nil;
        }
    }
    
    return parameter;
}

@end
