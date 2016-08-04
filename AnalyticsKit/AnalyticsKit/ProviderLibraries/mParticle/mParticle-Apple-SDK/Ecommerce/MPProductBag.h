//
//  MPProductBag.h
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

@class MPProduct;

@interface MPProductBag : NSObject

@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nonnull) NSMutableArray<MPProduct *> *products;

- (nonnull instancetype)initWithName:(nonnull NSString *)name;
- (nonnull instancetype)initWithName:(nonnull NSString *)name product:(nullable MPProduct *)product;
- (nonnull NSDictionary<NSString *, NSDictionary *> *)dictionaryRepresentation;

@end
