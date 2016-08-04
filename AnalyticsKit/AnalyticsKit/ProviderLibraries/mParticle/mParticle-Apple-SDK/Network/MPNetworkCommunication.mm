//
//  MPNetworkCommunication.m
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

#import "MPNetworkCommunication.h"
#import "MPMessage.h"
#import "MPSession.h"
#import <UIKit/UIKit.h>
#import "MPConnector.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#import "MPDevice.h"
#import "MPApplication.h"
#import "MPSegment.h"
#import "MPIConstants.h"
#import "MPStandaloneUpload.h"
#import "MPZip.h"
#import "MPURLRequestBuilder.h"
#import "MParticleReachability.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MPDataModelAbstract.h"
#import "NSUserDefaults+mParticle.h"
#import "MPSessionHistory.h"
#import "MPDateFormatter.h"

NSString *const urlFormat = @"%@://%@%@/%@%@"; // Scheme, URL Host, API Version, API key, path
NSString *const kMPConfigVersion = @"/v3";
NSString *const kMPConfigURL = @"/config";
NSString *const kMPEventsVersion = @"/v1";
NSString *const kMPEventsURL = @"/events";
NSString *const kMPSegmentVersion = @"/v1";
NSString *const kMPSegmentURL = @"/audience";

NSString *const kMPURLScheme = @"https";
NSString *const kMPURLHost = @"nativesdks.mparticle.com";
NSString *const kMPURLHostConfig = @"config2.mparticle.com";

@interface MPNetworkCommunication() {
    BOOL retrievingConfig;
    BOOL retrievingSegments;
    BOOL standaloneUploading;
    BOOL uploading;
    BOOL uploadingSessionHistory;
}

@property (nonatomic, strong, readonly) NSURL *segmentURL;
@property (nonatomic, strong, readonly) NSURL *configURL;
@property (nonatomic, strong, readonly) NSURL *eventURL;

@end

@implementation MPNetworkCommunication

@synthesize configURL = _configURL;
@synthesize eventURL = _eventURL;

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    retrievingConfig = NO;
    retrievingSegments = NO;
    standaloneUploading = NO;
    uploading = NO;
    uploadingSessionHistory = NO;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleReachabilityChanged:)
                               name:MParticleReachabilityChangedNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:MParticleReachabilityChangedNotification object:nil];
}

#pragma mark Private accessors
- (NSURL *)configURL {
    if (_configURL) {
        return _configURL;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    MPApplication *application = [[MPApplication alloc] init];
    NSString *configURLFormat = [urlFormat stringByAppendingString:@"?av=%@&sv=%@"];
    NSString *urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, kMPURLHostConfig, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, application.version, kMParticleSDKVersion];
    _configURL = [NSURL URLWithString:urlString];
    
    return _configURL;
}

- (NSURL *)eventURL {
    if (_eventURL) {
        return _eventURL;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    NSString *urlString = [NSString stringWithFormat:urlFormat, kMPURLScheme, kMPURLHost, kMPEventsVersion, stateMachine.apiKey, kMPEventsURL];
    _eventURL = [NSURL URLWithString:urlString];
    
    return _eventURL;
}

- (NSURL *)segmentURL {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *segmentURLFormat = [urlFormat stringByAppendingString:@"?mpID=%@"];
    NSString *urlString = [NSString stringWithFormat:segmentURLFormat, kMPURLScheme, kMPURLHost, kMPSegmentVersion, stateMachine.apiKey, kMPSegmentURL, stateMachine.consumerInfo.mpId];
    
    NSURL *segmentURL = [NSURL URLWithString:urlString];
    
    return segmentURL;
}

#pragma mark Private methods
- (void)processNetworkResponseAction:(MPNetworkResponseAction)responseAction batchObject:(MPDataModelAbstract *)batchObject {
    [self processNetworkResponseAction:responseAction batchObject:batchObject httpResponse:nil];
}

- (void)processNetworkResponseAction:(MPNetworkResponseAction)responseAction batchObject:(MPDataModelAbstract *)batchObject httpResponse:(NSHTTPURLResponse *)httpResponse {
    switch (responseAction) {
        case MPNetworkResponseActionDeleteBatch:
            if (!batchObject) {
                return;
            }
            
            if ([batchObject isMemberOfClass:[MPUpload class]]) {
                [[MPPersistenceController sharedInstance] deleteUpload:(MPUpload *)batchObject];
            } else if ([batchObject isMemberOfClass:[MPStandaloneUpload class]]) {
                [[MPPersistenceController sharedInstance] deleteStandaloneUpload:(MPStandaloneUpload *)batchObject];
            }
            
            break;
            
        case MPNetworkResponseActionThrottle: {
            NSDate *now = [NSDate date];
            NSDictionary *httpHeaders = [httpResponse allHeaderFields];
            NSTimeInterval retryAfter = 7200; // Default of 2 hours
            NSTimeInterval maxRetryAfter = 86400; // Maximum of 24 hours
            id suggestedRetryAfter = httpHeaders[@"Retry-After"];
            
            if (!MPIsNull(suggestedRetryAfter)) {
                if ([suggestedRetryAfter isKindOfClass:[NSString class]]) {
                    if ([suggestedRetryAfter containsString:@":"]) { // Date
                        NSDate *retryAfterDate = [MPDateFormatter dateFromStringRFC1123:(NSString *)suggestedRetryAfter];
                        if (retryAfterDate) {
                            retryAfter = MIN(([retryAfterDate timeIntervalSince1970] - [now timeIntervalSince1970]), maxRetryAfter);
                            retryAfter = retryAfter > 0 ? retryAfter : 7200;
                        } else {
                            MPILogError(@"Invalid 'Retry-After' date: %@", suggestedRetryAfter);
                        }
                    } else { // Number of seconds
                        @try {
                            retryAfter = MIN([(NSString *)suggestedRetryAfter doubleValue], maxRetryAfter);
                        } @catch (NSException *exception) {
                            retryAfter = 7200;
                            MPILogError(@"Invalid 'Retry-After' value: %@", suggestedRetryAfter);
                        }
                    }
                } else if ([suggestedRetryAfter isKindOfClass:[NSNumber class]]) {
                    retryAfter = MIN([(NSNumber *)suggestedRetryAfter doubleValue], maxRetryAfter);
                }
            }
            
            if ([[MPStateMachine sharedInstance].minUploadDate compare:now] == NSOrderedAscending) {
                [MPStateMachine sharedInstance].minUploadDate = [now dateByAddingTimeInterval:retryAfter];
                MPILogDebug(@"Throttling network for %.0f seconds", retryAfter);
            }
        }
            break;
            
        default:
            [MPStateMachine sharedInstance].minUploadDate = [NSDate distantPast];
            break;
    }
}

#pragma mark Notification handlers
- (void)handleReachabilityChanged:(NSNotification *)notification {
    retrievingConfig = retrievingSegments = standaloneUploading = uploading = uploadingSessionHistory = NO;
}

#pragma mark Public accessors
- (BOOL)inUse {
    return retrievingConfig || retrievingSegments || standaloneUploading || uploading || uploadingSessionHistory;
}

- (BOOL)retrievingSegments {
    return retrievingSegments;
}

#pragma mark Public methods
- (void)requestConfig:(void(^)(BOOL success, NSDictionary *configurationDictionary))completionHandler {
    if (retrievingConfig || [MPStateMachine sharedInstance].networkStatus == MParticleNetworkStatusNotReachable) {
        return;
    }
    
    retrievingConfig = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    MPILogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->retrievingConfig = NO;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    [connector asyncGetDataFromURL:self.configURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     if (!strongSelf) {
                         completionHandler(NO, nil);
                         return;
                     }
                     
                     if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                         [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                         backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                     }
                     
                     NSInteger responseCode = [httpResponse statusCode];
                     MPILogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                     
                     if (responseCode == HTTPStatusCodeNotModified) {
                         completionHandler(YES, nil);
                         strongSelf->retrievingConfig = NO;
                         return;
                     }
                     
                     NSDictionary *configurationDictionary = nil;
                     MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                     BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                     
                     if (!data && success) {
                         completionHandler(NO, nil);
                         strongSelf->retrievingConfig = NO;
                         MPILogWarning(@"Failed config request");
                         return;
                     }
                     
                     NSDictionary *headersDictionary = [httpResponse allHeaderFields];
                     NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
                     success = success && [data length] > 0;
                     
                     if (!MPIsNull(eTag) && success) {
                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                         userDefaults[kMPHTTPETagHeaderKey] = eTag;
                     }
                     
                     if (success) {
                         @try {
                             NSError *serializationError = nil;
                             configurationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                             success = serializationError == nil && [configurationDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeConfig];
                         } @catch (NSException *exception) {
                             success = NO;
                             responseCode = HTTPStatusCodeNoContent;
                         }
                     } else {
                         if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                             responseAction = MPNetworkResponseActionThrottle;
                         }
                     }
                     
                     [strongSelf processNetworkResponseAction:responseAction batchObject:nil httpResponse:httpResponse];
                     
                     completionHandler(success, configurationDictionary);
                     strongSelf->retrievingConfig = NO;
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPILogWarning(@"Failed config request");
            completionHandler(NO, nil);
        }
        
        [connector cancelRequest];
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf->retrievingConfig = NO;
        }
    });
}

- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler {
    if (retrievingSegments) {
        return;
    }
    
    retrievingSegments = YES;
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPConnector *connector = [[MPConnector alloc] init];
    
    __weak MPNetworkCommunication *weakSelf = self;
    NSDate *fetchSegmentsStartTime = [NSDate date];
    
    [connector asyncGetDataFromURL:self.segmentURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:fetchSegmentsStartTime];
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     if (!strongSelf) {
                         completionHandler(NO, nil, elapsedTime, nil);
                         return;
                     }
                     
                     if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                         [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                         backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                     }
                     
                     if (!data) {
                         completionHandler(NO, nil, elapsedTime, nil);
                         return;
                     }
                     
                     NSMutableArray<MPSegment *> *segments = nil;
                     BOOL success = NO;
                     strongSelf->retrievingSegments = NO;
                     
                     NSArray *segmentsList = nil;
                     NSInteger responseCode = [httpResponse statusCode];
                     success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                     
                     if (success) {
                         NSError *serializationError = nil;
                         NSDictionary *segmentsDictionary = nil;
                         
                         @try {
                             @try {
                                 segmentsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                                 success = serializationError == nil;
                             } @catch (NSException *exception) {
                                 segmentsDictionary = nil;
                                 success = NO;
                                 MPILogError(@"Segments Error: %@", [exception reason]);
                             }
                         } @catch (NSException *exception) {
                             segmentsDictionary = nil;
                             success = NO;
                             MPILogError(@"Segments Error: %@", [exception reason]);
                         }
                         
                         if (success) {
                             segmentsList = segmentsDictionary[kMPSegmentListKey];
                         }
                         
                         if (segmentsList.count > 0) {
                             segments = [[NSMutableArray alloc] initWithCapacity:segmentsList.count];
                             MPSegment *segment;
                             
                             for (NSDictionary *segmentDictionary in segmentsList) {
                                 segment = [[MPSegment alloc] initWithDictionary:segmentDictionary];
                                 
                                 if (segment) {
                                     [segments addObject:segment];
                                 }
                             }
                         }
                         
                         MPILogVerbose(@"Segments Response Code: %ld", (long)responseCode);
                     } else {
                         MPILogWarning(@"Segments Error - Response Code: %ld", (long)responseCode);
                     }
                     
                     if (segments.count == 0) {
                         segments = nil;
                     }
                     
                     NSError *segmentError = nil;
                     if (responseCode == HTTPStatusCodeForbidden) {
                         segmentError = [NSError errorWithDomain:@"mParticle Segments"
                                                            code:responseCode
                                                        userInfo:@{@"message":@"Segments not enabled for this org."}];
                     }
                     
                     if (elapsedTime < timeout) {
                         completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
                     } else {
                         segmentError = [NSError errorWithDomain:@"mParticle Segments"
                                                            code:MPNetworkErrorDelayedSegemnts
                                                        userInfo:@{@"message":@"It took too long to retrieve segments."}];
                         
                         completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
                     }
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        
        if (strongSelf && !strongSelf->retrievingSegments) {
            return;
        }
        
        NSError *error = [NSError errorWithDomain:@"mParticle Segments"
                                             code:MPNetworkErrorTimeout
                                         userInfo:@{@"message":@"Segment request timeout."}];
        
        completionHandler(YES, nil, timeout, error);
        
        if (strongSelf) {
            strongSelf->retrievingSegments = NO;
        }
    });
}

- (void)standaloneUploads:(NSArray<MPStandaloneUpload *> *)standaloneUploads index:(NSUInteger)index completionHandler:(MPStandaloneUploadsCompletionHandler)completionHandler {
    if (standaloneUploading) {
        return;
    }
    
    standaloneUploading = YES;
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPStandaloneUpload *standaloneUpload = standaloneUploads[index];
    NSString *uploadString = [standaloneUpload serializedString];
    MPConnector *connector = [[MPConnector alloc] init];
    __weak MPNetworkCommunication *weakSelf = self;
    
    NSData *zipUploadData = nil;
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[standaloneUpload.uploadData bytes], (unsigned int)[standaloneUpload.uploadData length]);
    if (get<0>(zipData) != nullptr) {
        zipUploadData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        [self processNetworkResponseAction:MPNetworkResponseActionDeleteBatch batchObject:standaloneUpload];
        completionHandler(NO, standaloneUpload, nil, YES);
        standaloneUploading = NO;
        return;
    }
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:uploadString
                   serializedParams:zipUploadData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      BOOL finished = index == standaloneUploads.count - 1;
                      
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      if (!strongSelf) {
                          completionHandler(NO, standaloneUpload, nil, finished);
                          return;
                      }
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      NSDictionary *responseDictionary = nil;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      NSInteger responseCode = [httpResponse statusCode];
                      BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                      
                      if (!data && success) {
                          completionHandler(NO, standaloneUpload, nil, finished);
                          
                          strongSelf->standaloneUploading = NO;
                          if (!finished) {
                              [strongSelf standaloneUploads:standaloneUploads index:(index + 1) completionHandler:completionHandler];
                          }
                          
                          return;
                      }
                      
                      success = success && [data length] > 0;
                      
                      if (success) {
                          NSError *serializationError = nil;
                          
                          @try {
                              responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                              success = serializationError == nil;
                              MPILogVerbose(@"Stand-alone Uploaded Message: %@\n", uploadString);
                              MPILogVerbose(@"Stand-alone Upload Response Code: %ld", (long)responseCode);
                          } @catch (NSException *exception) {
                              responseDictionary = nil;
                              success = NO;
                              MPILogError(@"Stand-alone Upload Error: %@", [exception reason]);
                          }
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPILogWarning(@"Stand-alone Uploads Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:standaloneUpload httpResponse:httpResponse];
                      
                      completionHandler(success, standaloneUpload, responseDictionary, finished);
                      
                      strongSelf->standaloneUploading = NO;
                      if (!finished) {
                          [strongSelf standaloneUploads:standaloneUploads index:(index + 1) completionHandler:completionHandler];
                      }
                  }];
}

- (void)upload:(NSArray<MPUpload *> *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler {
    if (uploading) {
        return;
    }
    
    uploading = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->uploading = NO;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPUpload *upload = uploads[index];
    NSString *uploadString = [upload serializedString];
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    MPILogVerbose(@"Source Batch Id: %@", upload.uuid);
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSData *zipUploadData = nil;
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[upload.uploadData bytes], (unsigned int)[upload.uploadData length]);
    if (get<0>(zipData) != nullptr) {
        zipUploadData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        [self processNetworkResponseAction:MPNetworkResponseActionDeleteBatch batchObject:upload];
        completionHandler(NO, upload, nil, YES);
        uploading = NO;
        return;
    }
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:uploadString
                   serializedParams:zipUploadData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      
                      if (!strongSelf) {
                          completionHandler(NO, upload, nil, YES);
                          return;
                      }
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      NSDictionary *responseDictionary = nil;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      BOOL finished = index == uploads.count - 1;
                      NSInteger responseCode = [httpResponse statusCode];
                      BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                      
                      if (!data && success) {
                          completionHandler(NO, upload, nil, finished);
                          strongSelf->uploading = NO;
                          return;
                      }
                      
                      success = success && [data length] > 0;
                      
                      if (success) {
                          NSError *serializationError = nil;
                          
                          @try {
                              responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                              success = serializationError == nil && [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader];
                              MPILogVerbose(@"Uploaded Message: %@\n", uploadString);
                              MPILogVerbose(@"Upload Response Code: %ld", (long)responseCode);
                          } @catch (NSException *exception) {
                              responseDictionary = nil;
                              success = NO;
                              MPILogError(@"Uploads Error: %@", [exception reason]);
                          }
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPILogWarning(@"Uploads Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      MPILogVerbose(@"Upload Execution Time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:upload httpResponse:httpResponse];
                      
                      completionHandler(success, upload, responseDictionary, finished);
                      
                      strongSelf->uploading = NO;
                      if (!finished) {
                          [strongSelf upload:uploads index:(index + 1) completionHandler:completionHandler];
                      }
                  }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPILogWarning(@"Failed Uploading Source Batch Id: %@", upload.uuid);
            completionHandler(NO, upload, nil, YES);
        }
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf->uploading = NO;
        }
        
        [connector cancelRequest];
    });
}

- (void)uploadSessionHistory:(MPSessionHistory *)sessionHistory completionHandler:(void(^)(BOOL success))completionHandler {
    if (uploadingSessionHistory) {
        return;
    }
    
    if (!sessionHistory) {
        completionHandler(NO);
        return;
    }
    
    uploadingSessionHistory = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    MPILogVerbose(@"Source Batch Id: %@", sessionHistory.session.uuid);
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->uploadingSessionHistory = NO;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    NSData *sessionHistoryData = [NSJSONSerialization dataWithJSONObject:[sessionHistory dictionaryRepresentation] options:0 error:nil];
    
    NSData *zipSessionData = nil;
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[sessionHistoryData bytes], (unsigned int)[sessionHistoryData length]);
    if (get<0>(zipData) != nullptr) {
        zipSessionData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        completionHandler(NO);
        uploadingSessionHistory = NO;
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:sessionHistoryData encoding:NSUTF8StringEncoding];
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:jsonString
                   serializedParams:zipSessionData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      if (!strongSelf) {
                          completionHandler(NO);
                          return;
                      }
                      
                      NSInteger responseCode = [httpResponse statusCode];
                      BOOL success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      
                      if (success) {
                          MPILogVerbose(@"Session History: %@\n", jsonString);
                          MPILogVerbose(@"Session History Response Code: %ld", (long)responseCode);
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPILogWarning(@"Session History Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      MPILogVerbose(@"Session History Execution Time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:nil httpResponse:httpResponse];
                      
                      completionHandler(success);
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      strongSelf->uploadingSessionHistory = NO;
                  }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPILogWarning(@"Failed Uploading Source Batch Id: %@", sessionHistory.session.uuid);
            completionHandler(NO);
        }
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf->uploadingSessionHistory = NO;
        }
        
        [connector cancelRequest];
    });
}

@end
