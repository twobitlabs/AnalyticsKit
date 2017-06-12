//
//  MPURLRequestBuilder.h
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

@interface MPURLRequestBuilder : NSObject

@property (nonatomic, strong, nonnull) NSString *httpMethod;
@property (nonatomic, strong, nullable) NSData *postData;
@property (nonatomic, strong, nonnull) NSURL *url;

+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull NSURL *)url;
+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull NSURL *)url message:(nullable NSString *)message httpMethod:(nullable NSString *)httpMethod;
+ (NSTimeInterval)requestTimeout;
+ (void)tryToCaptureUserAgent;
- (nonnull instancetype)initWithURL:(nonnull NSURL *)url;
- (nonnull MPURLRequestBuilder *)withHeaderData:(nullable NSData *)headerData;
- (nonnull MPURLRequestBuilder *)withHttpMethod:(nonnull NSString *)httpMethod;
- (nonnull MPURLRequestBuilder *)withPostData:(nullable NSData *)postData;
- (nonnull NSMutableURLRequest *)build;

@end
