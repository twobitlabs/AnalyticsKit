//
//  MPURLRequestBuilder.m
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

#import "MPURLRequestBuilder.h"
#import <CommonCrypto/CommonHMAC.h>
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "NSUserDefaults+mParticle.h"
#import "MPKitContainer.h"
#import "MPExtensionProtocol.h"

static NSDateFormatter *RFC1123DateFormatter;
static NSTimeInterval requestTimeout = 30.0;

@interface MPURLRequestBuilder() {
    BOOL SDKURLRequest;
}

@property (nonatomic, strong) NSData *headerData;
@property (nonatomic, strong) NSString *message;

@end


@implementation MPURLRequestBuilder

+ (void)initialize {
    RFC1123DateFormatter = [[NSDateFormatter alloc] init];
    RFC1123DateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    RFC1123DateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    RFC1123DateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self || !url) {
        return nil;
    }
    
    _url = url;
    _headerData = nil;
    _httpMethod = kMPHTTPMethodGet;
    _message = nil;
    _postData = nil;

    return self;
}

#pragma mark Private methods
- (NSString *)hmacSha256Encode:(NSString *const)message key:(NSString *const)key {
    if (!message || !key) {
        return nil;
    }
    
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cMessage, strlen(cMessage), cHMAC);
    
    NSMutableString *encodedMessage = [NSMutableString stringWithCapacity:(CC_SHA256_DIGEST_LENGTH << 1)];
    
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [encodedMessage appendFormat:@"%02x", cHMAC[i]];
    }
    
    return (NSString *)encodedMessage;
}

- (NSString *)userAgent {
    static NSString *mpUserAgent = nil;

    if (!mpUserAgent) {
#if TARGET_OS_IOS == 1
        dispatch_block_t getUserAgent = ^{
            UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
            
            mpUserAgent = [NSString stringWithFormat:@"%@ mParticle/%@", [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"], kMParticleSDKVersion];
        };
        
        if ([NSThread isMainThread]) {
            getUserAgent();
        } else {
            dispatch_sync(dispatch_get_main_queue(), getUserAgent);
        }
#elif TARGET_OS_TV == 1
        mpUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (AppleTV; CPU tv OS 9_0 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12F70 mParticle/%@", kMParticleSDKVersion];
#endif
    }
    
    return mpUserAgent;
}

#pragma mark Public class methods
+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    
    if (urlRequestBuilder) {
        urlRequestBuilder->SDKURLRequest = NO;
    }
    
    return urlRequestBuilder;
}

+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url message:(NSString *)message httpMethod:(NSString *)httpMethod {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    [urlRequestBuilder withHttpMethod:httpMethod];
    urlRequestBuilder.message = message;
    
    if (urlRequestBuilder) {
        urlRequestBuilder->SDKURLRequest = YES;
    }
    
    return urlRequestBuilder;
}

+ (NSTimeInterval)requestTimeout {
    return requestTimeout;
}

#pragma mark Public instance methods
- (MPURLRequestBuilder *)withHeaderData:(NSData *)headerData {
    _headerData = headerData;
    
    return self;
}

- (MPURLRequestBuilder *)withHttpMethod:(NSString *)httpMethod {
    if (httpMethod) {
        _httpMethod = httpMethod;
    } else {
        _httpMethod = kMPHTTPMethodGet;
    }
    
    return self;
}

- (MPURLRequestBuilder *)withPostData:(NSData *)postData {
    _postData = postData;
    
    return self;
}

- (NSMutableURLRequest *)build {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:_url];
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [urlRequest setTimeoutInterval:requestTimeout];
    [urlRequest setHTTPMethod:_httpMethod];

    if (SDKURLRequest) {
        NSString *deviceLocale = [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
        MPKitContainer *kitContainer = [MPKitContainer sharedInstance];
        NSArray<NSNumber *> *supportedKits = [kitContainer supportedKits];
        NSString *contentType = nil;
        NSString *kits = nil;
        NSString *relativePath = [_url relativePath];
        NSString *signatureMessage;
        NSString *date = [RFC1123DateFormatter stringFromDate:[NSDate date]];
        NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
        NSString *secondsFromGMT = [NSString stringWithFormat:@"%ld", (unsigned long)[timeZone secondsFromGMT]];
        NSRange range;
        BOOL containsMessage = _message != nil;
        
        if (containsMessage) { // /events
            contentType = @"application/json";
            
            if (supportedKits) {
                kits = [supportedKits componentsJoinedByString:@","];
                [urlRequest setValue:kits forHTTPHeaderField:@"x-mp-bundled-kits"];
                kits = nil;
            }
            
            NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MPKitContainer sharedInstance] activeKitsRegistry];
            if (activeKitsRegistry.count > 0) {
                NSMutableArray<NSNumber *> *activeKitIds = [[NSMutableArray alloc] initWithCapacity:activeKitsRegistry.count];
                
                for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
                    [activeKitIds addObject:kitRegister.code];
                }
                
                kits = [activeKitIds componentsJoinedByString:@","];
            }
            
            range = [_message rangeOfString:kMPMessageTypeNetworkPerformance];
            if (range.location != NSNotFound) {
                [urlRequest setValue:kMPMessageTypeNetworkPerformance forHTTPHeaderField:kMPMessageTypeNetworkPerformance];
            }
            
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@%@", _httpMethod, date, relativePath, _message];
        } else { // /config and /audience
            contentType = @"application/x-www-form-urlencoded";
            
            range = [relativePath rangeOfString:@"/config"];
            if (range.location != NSNotFound) {
                if (supportedKits) {
                    kits = [supportedKits componentsJoinedByString:@","];
                }
                
                NSString *environment = [NSString stringWithFormat:@"%d", (int)[MPStateMachine environment]];
                [urlRequest setValue:environment forHTTPHeaderField:@"x-mp-env"];
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
                if (eTag) {
                    [urlRequest setValue:eTag forHTTPHeaderField:@"If-None-Match"];
                }
                
                NSString *query = [_url query];
                signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@?%@", _httpMethod, date, relativePath, query];
            } else {
                signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@", _httpMethod, date, relativePath];
            }
        }
        
        NSString *hmacSha256Encode = [self hmacSha256Encode:signatureMessage key:[MPStateMachine sharedInstance].secret];
        if (hmacSha256Encode) {
            [urlRequest setValue:hmacSha256Encode forHTTPHeaderField:@"x-mp-signature"];
        }
        
        if (kits) {
            [urlRequest setValue:kits forHTTPHeaderField:@"x-mp-kits"];
        }

        [urlRequest setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        [urlRequest setValue:deviceLocale forHTTPHeaderField:@"locale"];
        [urlRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [urlRequest setValue:[timeZone name] forHTTPHeaderField:@"timezone"];
        [urlRequest setValue:secondsFromGMT forHTTPHeaderField:@"secondsFromGMT"];
        [urlRequest setValue:date forHTTPHeaderField:@"Date"];
    } else if (_headerData) {
        NSDictionary *headerDictionary = [NSJSONSerialization JSONObjectWithData:_headerData options:0 error:nil];
        
        if (headerDictionary) {
            NSEnumerator *headerEnumerator = [headerDictionary keyEnumerator];
            NSString *key;
            
            while ((key = [headerEnumerator nextObject])) {
                [urlRequest setValue:headerDictionary[key] forHTTPHeaderField:key];
            }
        }
    }

    if (_postData.length > 0) {
        [urlRequest setHTTPBody:_postData];
    }
    
    return urlRequest;
}

@end
