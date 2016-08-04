//
//  MPLaunchInfo.h
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

@interface MPLaunchInfo : NSObject

@property (nonatomic, strong, readonly, nonnull) NSURL *url;
@property (nonatomic, strong, readonly, nonnull) NSString *sourceApplication;
@property (nonatomic, strong, readonly, nullable) NSString *annotation;
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSString *, id> *options;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull instancetype)initWithURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;

@end
