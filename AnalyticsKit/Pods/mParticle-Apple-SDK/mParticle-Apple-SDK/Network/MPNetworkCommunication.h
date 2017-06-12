//
//  MPNetworkCommunication.h
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

@class MPSession;
@class MPUpload;
@class MPStandaloneUpload;
@class MPSessionHistory;
@class MPSegment;

extern NSString * _Nonnull const kMPURLScheme;
extern NSString * _Nonnull const kMPURLHost;
extern NSString * _Nonnull const kMPURLHostConfig;

typedef NS_ENUM(NSInteger, MPNetworkResponseAction) {
    MPNetworkResponseActionNone = 0,
    MPNetworkResponseActionDeleteBatch,
    MPNetworkResponseActionThrottle
};

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegemnts
};

typedef void(^ _Nonnull MPSegmentResponseHandler)(BOOL success, NSArray<MPSegment *> * _Nullable segments, NSTimeInterval elapsedTime, NSError * _Nullable error);
typedef void(^ _Nonnull MPUploadsCompletionHandler)(BOOL success, MPUpload * _Nullable upload, NSDictionary * _Nullable responseDictionary, BOOL finished);
typedef void(^ _Nonnull MPStandaloneUploadsCompletionHandler)(BOOL success, MPStandaloneUpload * _Nullable standaloneUpload, NSDictionary * _Nullable responseDictionary, BOOL finished);

@interface MPNetworkCommunication : NSObject

@property (nonatomic, unsafe_unretained, readonly) BOOL inUse;
@property (nonatomic, unsafe_unretained, readonly) BOOL retrievingSegments;

- (void)requestConfig:(void(^ _Nonnull)(BOOL success, NSDictionary * _Nullable configurationDictionary))completionHandler;
- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler;
- (void)standaloneUploads:(nonnull NSArray<MPStandaloneUpload *> *)standaloneUploads index:(NSUInteger)index completionHandler:(MPStandaloneUploadsCompletionHandler)completionHandler;
- (void)upload:(nonnull NSArray<MPUpload *> *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler;
- (void)uploadSessionHistory:(nonnull MPSessionHistory *)sessionHistory completionHandler:(void(^ _Nonnull)(BOOL success))completionHandler;

@end
