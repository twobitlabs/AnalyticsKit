//
//  NSURLSession+mParticle.m
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

#import "NSURLSession+mParticle.h"
#import <objc/runtime.h>
#import "MPNetworkPerformance.h"
#import "MPIConstants.h"

typedef NS_ENUM(int, MPURLSessionSwizzledIndex) {
    MPURLSessionSwizzledIndexDataTaskWithURL = 0, // Instance methods
    MPURLSessionSwizzledIndexDataTaskWithRequest,
    MPURLSessionSwizzledIndexDownloadTaskWithURL,
    MPURLSessionSwizzledIndexDownloadTaskWithRequest,
    MPURLSessionSwizzledIndexUploadTaskWithRequestFromData,
    MPURLSessionSwizzledIndexUploadTaskWithRequestFromFile
};

NSString *const usURLFormat = @"%@://%@";

static IMP *originalURLSessionMethodsImplementations = NULL;
static IMP *swizzledURLSessionMethodsImplementations = NULL;

static NSArray *NSURLSessionOriginalMethods;
static NSMutableArray *urlSessionExcludeURLs;
static NSMutableArray *urlSessionPreserverQueryFilters;
static BOOL NSURLSessionMethodsSwizzled = NO;
static BOOL NSURLSessionMPInitialized = NO;

// Swizzled methods prototypes
NSURLSessionDataTask *swizzledDataTaskWithURL(id self, SEL _cmd, NSURL *url, void (^)(NSData *data, NSURLResponse *response, NSError *error));
NSURLSessionDataTask *swizzledDataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *));
NSURLSessionDownloadTask *swizzledDownloadTaskWithURL(id self, SEL _cmd, NSURL *url, void (^)(NSURL *location, NSURLResponse *response, NSError *error));
NSURLSessionDownloadTask *swizzledDownloadTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, void (^)(NSURL *location, NSURLResponse *response, NSError *error));
NSURLSessionUploadTask *swizzledUploadTaskWithRequestFromData(id self, SEL _cmd, NSURLRequest *request, NSData *bodyData, void (^)(NSData *data, NSURLResponse *response, NSError *error));
NSURLSessionUploadTask *swizzledUploadTaskWithRequestFromFile(id self, SEL _cmd, NSURLRequest *request, NSURL *fileURL, void (^)(NSData *data, NSURLResponse *response, NSError *error));

@implementation NSURLSession(mParticle)

+ (void)mpInitialize {
    if (NSURLSessionMPInitialized) {
        return;
    }
    
    NSURLSessionMPInitialized = YES;
    
    NSURLSessionOriginalMethods = @[@"dataTaskWithURL:completionHandler:", // Instance methods
                                    @"dataTaskWithRequest:completionHandler:",
                                    @"downloadTaskWithURL:completionHandler:",
                                    @"downloadTaskWithRequest:completionHandler:",
                                    @"uploadTaskWithRequest:fromData:completionHandler:",
                                    @"uploadTaskWithRequest:fromFile:completionHandler:"];
    
    urlSessionExcludeURLs = [[NSMutableArray alloc] init];
    urlSessionPreserverQueryFilters = [[NSMutableArray alloc] init];
    
    size_t allocMemorySize = NSURLSessionOriginalMethods.count * sizeof(IMP);
    
    if (originalURLSessionMethodsImplementations != NULL) {
        free(originalURLSessionMethodsImplementations);
    }
    originalURLSessionMethodsImplementations = malloc(allocMemorySize);
    
    if (swizzledURLSessionMethodsImplementations != NULL) {
        free(swizzledURLSessionMethodsImplementations);
    }
    swizzledURLSessionMethodsImplementations = malloc(allocMemorySize);
}

#pragma mark Swizzled methods
NSURLSessionDataTask *swizzledDataTaskWithURL(id self, SEL _cmd, NSURL *url, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error)) {
    NSURLSessionDataTask *dataTask = nil;
    IMP originalDataTaskWithURL = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDataTaskWithURL];
    
    if (completionHandler) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:MPNetworkMeasurementModePreserveQuery];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        dataTask = ((NSURLSessionDataTask * (*)(id, SEL, NSURL *, void(^)(NSData *, NSURLResponse *, NSError *)))originalDataTaskWithURL)(self, _cmd, url, ^(NSData *data, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = [data length] + [NSURLSession sizeForResponse:httpURLResponse];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
            });
            
            completionHandler(data, response, error);
        });
    } else if (originalDataTaskWithURL) {
        dataTask = ((NSURLSessionDataTask * (*)(id, SEL, NSURL *))originalDataTaskWithURL)(self, _cmd, url);
    }
    
    return dataTask;
}

NSURLSessionDataTask *swizzledDataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSURLSessionDataTask *dataTask = nil;
    IMP originalDataTaskWithRequest = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDataTaskWithRequest];
    
    if (completionHandler) {
        NSString *npeHeader = [request valueForHTTPHeaderField:kMPMessageTypeNetworkPerformance];
        MPNetworkMeasurementMode networkMeasurementMode = npeHeader ? MPNetworkMeasurementModeExclude : [NSURLSession networkMeasurementModeForRequest:request];
        
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        dataTask = ((NSURLSessionDataTask * (*)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *)))originalDataTaskWithRequest)(self, _cmd, request, ^(NSData *data, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = [data length] + [NSURLSession sizeForResponse:httpURLResponse];
            
            if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
                });
            }
            
            completionHandler(data, response, error);
        });
    } else if (originalDataTaskWithRequest) {
        dataTask = ((NSURLSessionDataTask * (*)(id, SEL, NSURLRequest *))originalDataTaskWithRequest)(self, _cmd, request);
    }
    
    return dataTask;
}

NSURLSessionDownloadTask *swizzledDownloadTaskWithURL(id self, SEL _cmd, NSURL *url, void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error)) {
    NSURLSessionDownloadTask *downloadTask = nil;
    IMP originalDownloadTaskWithURL = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDownloadTaskWithURL];
    
    if (completionHandler) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:MPNetworkMeasurementModePreserveQuery];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        downloadTask = ((NSURLSessionDownloadTask * (*)(id, SEL, NSURL *, void(^)(NSURL *, NSURLResponse *, NSError *)))originalDownloadTaskWithURL)(self, _cmd, url, ^(NSURL *location, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = (NSUInteger)[response expectedContentLength] + [NSURLSession sizeForResponse:httpURLResponse];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
            });
            
            completionHandler(location, response, error);
        });
    } else if (originalDownloadTaskWithURL) {
        downloadTask = ((NSURLSessionDownloadTask * (*)(id, SEL, NSURL *))originalDownloadTaskWithURL)(self, _cmd, url);
    }
    
    return downloadTask;
}

NSURLSessionDownloadTask *swizzledDownloadTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error)) {
    NSURLSessionDownloadTask *downloadTask = nil;
    IMP originalDownloadTaskWithRequest = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDownloadTaskWithRequest];
    
    if (completionHandler) {
        NSString *npeHeader = [request valueForHTTPHeaderField:kMPMessageTypeNetworkPerformance];
        MPNetworkMeasurementMode networkMeasurementMode = npeHeader ? MPNetworkMeasurementModeExclude : [NSURLSession networkMeasurementModeForRequest:request];
        
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        downloadTask = ((NSURLSessionDownloadTask * (*)(id, SEL, NSURLRequest *, void(^)(NSURL *, NSURLResponse *, NSError *)))originalDownloadTaskWithRequest)(self, _cmd, request, ^(NSURL *location, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = (NSUInteger)[response expectedContentLength] + [NSURLSession sizeForResponse:httpURLResponse];
            
            if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
                });
            }
            
            completionHandler(location, response, error);
        });
    } else if (originalDownloadTaskWithRequest) {
        downloadTask = ((NSURLSessionDownloadTask * (*)(id, SEL, NSURLRequest *))originalDownloadTaskWithRequest)(self, _cmd, request);
    }
    
    return downloadTask;
}

NSURLSessionUploadTask *swizzledUploadTaskWithRequestFromData(id self, SEL _cmd, NSURLRequest *request, NSData *bodyData, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error)) {
    NSURLSessionUploadTask *uploadTask = nil;
    IMP originalUploadTaskWithRequest = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexUploadTaskWithRequestFromData];
    
    if (completionHandler) {
        NSString *npeHeader = [request valueForHTTPHeaderField:kMPMessageTypeNetworkPerformance];
        MPNetworkMeasurementMode networkMeasurementMode = npeHeader ? MPNetworkMeasurementModeExclude : [NSURLSession networkMeasurementModeForRequest:request];
        
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        uploadTask = ((NSURLSessionUploadTask * (*)(id, SEL, NSURLRequest *, NSData *, void(^)(NSData *, NSURLResponse *, NSError *)))originalUploadTaskWithRequest)(self, _cmd, request, bodyData, ^(NSData *data, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = [data length] + [NSURLSession sizeForResponse:httpURLResponse];
            
            if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
                });
            }
            
            completionHandler(data, response, error);
        });
    } else if (originalUploadTaskWithRequest) {
        uploadTask = ((NSURLSessionUploadTask * (*)(id, SEL, NSURLRequest *, NSData *))originalUploadTaskWithRequest)(self, _cmd, request, bodyData);
    }
    
    return uploadTask;
}

NSURLSessionUploadTask *swizzledUploadTaskWithRequestFromFile(id self, SEL _cmd, NSURLRequest *request, NSURL *fileURL, void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error)) {
    NSURLSessionUploadTask *uploadTask = nil;
    IMP originalUploadTaskWithRequest = originalURLSessionMethodsImplementations[MPURLSessionSwizzledIndexUploadTaskWithRequestFromFile];
    
    if (completionHandler) {
        NSString *npeHeader = [request valueForHTTPHeaderField:kMPMessageTypeNetworkPerformance];
        MPNetworkMeasurementMode networkMeasurementMode = npeHeader ? MPNetworkMeasurementModeExclude : [NSURLSession networkMeasurementModeForRequest:request];
        
        MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
        [networkPerformance setStartDate:[NSDate date]];
        networkPerformance.bytesOut = [NSURLSession sizeForRequest:request];
        
        uploadTask = ((NSURLSessionUploadTask * (*)(id, SEL, NSURLRequest *, NSURL *, void(^)(NSData *, NSURLResponse *, NSError *)))originalUploadTaskWithRequest)(self, _cmd, request, fileURL, ^(NSData *data, NSURLResponse *response, NSError *error) {
            [networkPerformance setEndDate:[NSDate date]];
            
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            networkPerformance.responseCode = [httpURLResponse statusCode];
            networkPerformance.bytesIn = [data length] + [NSURLSession sizeForResponse:httpURLResponse];
            
            if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
                });
            }
            
            completionHandler(data, response, error);
        });
    } else if (originalUploadTaskWithRequest) {
        uploadTask = ((NSURLSessionUploadTask * (*)(id, SEL, NSURLRequest *, NSURL *))originalUploadTaskWithRequest)(self, _cmd, request, fileURL);
    }
    
    return uploadTask;
}

#pragma mark Private class methods
+ (NSUInteger)sizeForRequest:(NSURLRequest *const)request {
    NSDictionary *allHeaderFields = [request allHTTPHeaderFields];
    NSString *headerValue;
    NSUInteger bodySize = [[request HTTPBody] length];
    NSUInteger urlLength = [[request.URL absoluteString] length];
    NSUInteger headersSize = 0;
    
    for (NSString *headerField in allHeaderFields) {
        headerValue = [request valueForHTTPHeaderField:headerField];
        headersSize += [headerField length] + [headerValue length];
    }
    
    return bodySize + urlLength + headersSize;
}

+ (NSUInteger)sizeForResponse:(NSHTTPURLResponse *const)response {
    NSDictionary *allHeaderFields = [response allHeaderFields];
    NSString *headerValue;
    NSUInteger headersSize = 0;
    
    for (NSString *headerField in allHeaderFields) {
        headerValue = allHeaderFields[headerField];
        headersSize += [headerField length] + [headerValue length];
    }
    
    return headersSize;
}

+ (MPNetworkMeasurementMode)networkMeasurementModeForRequest:(NSURLRequest *const)request {
    //    __block NetworkMeasurementMode networkMeasurementMode = NetworkMeasurementModeAbridged;
    __block MPNetworkMeasurementMode networkMeasurementMode = MPNetworkMeasurementModePreserveQuery;
    
    NSString *urlString = [NSString stringWithFormat:usURLFormat, [request.URL scheme], [request.URL host]];
    [urlSessionExcludeURLs enumerateObjectsWithOptions:NSEnumerationConcurrent
                                  usingBlock:^(NSString *excludeURL, NSUInteger idx, BOOL *stop) {
                                      NSRange range = [excludeURL rangeOfString:urlString];
                                      
                                      if (range.location != NSNotFound) {
                                          networkMeasurementMode = MPNetworkMeasurementModeExclude;
                                          *stop = YES;
                                      }
                                  }];
    
    if (networkMeasurementMode != MPNetworkMeasurementModeAbridged) {
        return networkMeasurementMode;
    }
    
    urlString = [request.URL absoluteString];
    [urlSessionPreserverQueryFilters enumerateObjectsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(NSString *preserverQueryFilter, NSUInteger idx, BOOL *stop) {
                                                NSRange range = [urlString rangeOfString:preserverQueryFilter];
                                                
                                                if (range.location != NSNotFound) {
                                                    networkMeasurementMode = MPNetworkMeasurementModePreserveQuery;
                                                    *stop = YES;
                                                }
                                            }];
    
    return networkMeasurementMode;
}

#pragma mark Public class methods
+ (void)freeResources {
    [NSURLSession mpInitialize];
    NSURLSessionMPInitialized = NO;
    
    if (originalURLSessionMethodsImplementations != NULL) {
        free(originalURLSessionMethodsImplementations);
        originalURLSessionMethodsImplementations = NULL;
    }
    
    if (swizzledURLSessionMethodsImplementations != NULL) {
        free(swizzledURLSessionMethodsImplementations);
        swizzledURLSessionMethodsImplementations = NULL;
    }
}

+ (BOOL)methodsSwizzled {
    return NSURLSessionMethodsSwizzled;
}

+ (void)swizzleMethods {
    if (NSURLSessionMethodsSwizzled) {
        return;
    }
    
    [NSURLSession mpInitialize];
    NSURLSessionMethodsSwizzled = YES;
    
    // Instance methods
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDataTaskWithURL] = (IMP)swizzledDataTaskWithURL;
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDataTaskWithRequest] = (IMP)swizzledDataTaskWithRequest;
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDownloadTaskWithURL] = (IMP)swizzledDownloadTaskWithURL;
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexDownloadTaskWithRequest] = (IMP)swizzledDownloadTaskWithRequest;
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexUploadTaskWithRequestFromData] = (IMP)swizzledUploadTaskWithRequestFromData;
    swizzledURLSessionMethodsImplementations[MPURLSessionSwizzledIndexUploadTaskWithRequestFromFile] = (IMP)swizzledUploadTaskWithRequestFromFile;
    
    Method originalMethod;
    MPURLSessionSwizzledIndex idx = MPURLSessionSwizzledIndexDataTaskWithURL;
    SEL originalSelector;
    for (NSString *originalMethodName in NSURLSessionOriginalMethods) {
        originalSelector = NSSelectorFromString(originalMethodName);
        originalMethod = class_getInstanceMethod([NSURLSession class], originalSelector);
        originalURLSessionMethodsImplementations[idx] = method_setImplementation(originalMethod, swizzledURLSessionMethodsImplementations[idx]);
        ++idx;
    }
}

+ (void)restoreMethods {
    if (!NSURLSessionMethodsSwizzled) {
        return;
    }
    
    NSString *originalMethodName;
    Method originalMethod;
    SEL originalSelector;
    for (MPURLSessionSwizzledIndex idx = MPURLSessionSwizzledIndexDataTaskWithURL; idx <= MPURLSessionSwizzledIndexUploadTaskWithRequestFromFile; ++idx) {
        originalMethodName = NSURLSessionOriginalMethods[idx];
        originalSelector = NSSelectorFromString(originalMethodName);
        originalMethod = class_getInstanceMethod([NSURLSession class], originalSelector);
        method_setImplementation(originalMethod, originalURLSessionMethodsImplementations[idx]);
    }
    
    NSURLSessionMethodsSwizzled = NO;
}

+ (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url {
    [NSURLSession mpInitialize];
    NSString *urlAbsoluteString = [[url absoluteString] copy];
    
    if ([urlSessionExcludeURLs containsObject:urlAbsoluteString]) {
        return;
    }
    
    [urlSessionExcludeURLs addObject:urlAbsoluteString];
}

+ (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString {
    [NSURLSession mpInitialize];
    NSString *preserveQueryString = [queryString copy];
    
    if ([urlSessionPreserverQueryFilters containsObject:preserveQueryString]) {
        return;
    }
    
    [urlSessionPreserverQueryFilters addObject:preserveQueryString];
}

+ (void)resetNetworkPerformanceExclusionsAndFilters {
    [NSURLSession mpInitialize];
    
    [urlSessionExcludeURLs removeAllObjects];
    [urlSessionPreserverQueryFilters removeAllObjects];
}

@end
