//
//  MPCustomModulePreference.h
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
#import "MPIConstants.h"

typedef NS_ENUM(NSUInteger, MPCustomModuleId) {
    MPCustomModuleIdAppBoy = 28
};

@interface MPCustomModulePreference : NSObject <NSCoding>

@property (nonatomic, strong, readonly, nonnull) NSNumber *moduleId;
@property (nonatomic, strong, readonly, nonnull) NSString *defaultValue;
@property (nonatomic, strong, readonly, nonnull) NSString *readKey;
@property (nonatomic, strong, nonnull) id value;
@property (nonatomic, strong, readonly, nonnull) NSString *writeKey;
@property (nonatomic, readonly) MPDataType dataType;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)preferenceDictionary location:(nullable NSString *)location moduleId:(nonnull NSNumber *)moduleId;

@end
