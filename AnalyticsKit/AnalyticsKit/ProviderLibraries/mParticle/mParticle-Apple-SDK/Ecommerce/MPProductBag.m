//
//  MPProductBag.m
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

#import "MPProductBag.h"
#import "MPIConstants.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"

@implementation MPProductBag

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name product:nil];
}

- (instancetype)initWithName:(NSString *)name product:(MPProduct *)product {
    self = [super init];
    if (!self || MPIsNull(name) || ![name isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    _name = name;
    
    if (!MPIsNull(product) && [product isKindOfClass:[MPProduct class]]) {
        [self.products addObject:product];
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPProductBag:{\n"];
    
    [description appendFormat:@"  name:%@\n", _name];
    
    [description appendString:@"  products:[\n"];
    for (MPProduct *product in self.products) {
        [description appendFormat:@"    %@\n", [product description]];
    }
    
    [description appendString:@"  ]\n"];
    [description appendString:@"}\n"];
    
    return (NSString *)description;
}

- (BOOL)isEqual:(id)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPProductBag class]]) {
        return NO;
    }

    BOOL isEqual = [self.name isEqualToString:((MPProductBag *)object).name];
    
    if (isEqual) {
        isEqual = self.products.count == ((MPProductBag *)object).products.count;
    }
    
    return isEqual;
}

#pragma mark Public accessors
- (void)setName:(NSString *)name {
    BOOL validName = !MPIsNull(name) && [name isKindOfClass:[NSString class]];
    NSAssert(validName, @"The 'name' variable is not valid.");
    
    if (validName) {
        _name = name;
    }
}

- (nonnull NSMutableArray<MPProduct *> *)products {
    if (_products) {
        return _products;
    }
    
    _products = [[NSMutableArray alloc] initWithCapacity:1];
    return _products;
}

#pragma mark Public methods
- (NSDictionary<NSString *, NSDictionary *> *)dictionaryRepresentation {
    NSMutableArray *products = [[NSMutableArray alloc] init];
    for (MPProduct *product in self.products) {
        NSDictionary *productDictionary = [product commerceDictionaryRepresentation];
        
        if (productDictionary) {
            [products addObject:productDictionary];
        }
    }
    
    NSDictionary *productsDictionary = @{@"pl":products};
    NSDictionary *dictionary = @{_name:productsDictionary};
    
    return dictionary;
}

@end
