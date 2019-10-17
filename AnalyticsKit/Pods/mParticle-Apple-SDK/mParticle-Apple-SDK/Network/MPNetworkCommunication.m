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
#import "MPZip.h"
#import "MPURLRequestBuilder.h"
#import "MParticleReachability.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"
#import "MPDateFormatter.h"
#import "MPIdentityApiRequest.h"
#import "mParticle.h"
#import "MPEnums.h"
#import "MPIdentityDTO.h"
#import "MPIConstants.h"
#import "NSString+MPPercentEscape.h"
#import "MPResponseEvents.h"
#import "MPAliasResponse.h"
#import "MPResponseConfig.h"

NSString *const urlFormat = @"%@://%@%@/%@%@"; // Scheme, URL Host, API Version, API key, path
NSString *const identityURLFormat = @"%@://%@%@/%@"; // Scheme, URL Host, API Version, path
NSString *const modifyURLFormat = @"%@://%@%@/%@/%@"; // Scheme, URL Host, API Version, mpid, path
NSString *const aliasURLFormat = @"%@://%@%@/%@/%@/%@"; // Scheme, URL Host, API Version, identity, API key, path
NSString *const kMPConfigVersion = @"/v4";
NSString *const kMPConfigURL = @"/config";
NSString *const kMPEventsVersion = @"/v2";
NSString *const kMPEventsURL = @"/events";
NSString *const kMPSegmentVersion = @"/v1";
NSString *const kMPSegmentURL = @"/audience";
NSString *const kMPIdentityVersion = @"/v1";
NSString *const kMPIdentityURL = @"";

NSString *const kMPURLScheme = @"https";
NSString *const kMPURLHost = @"nativesdks.mparticle.com";
NSString *const kMPURLHostConfig = @"config2.mparticle.com";
NSString *const kMPURLHostIdentity = @"identity.mparticle.com";

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@interface MPIdentityApiRequest ()

- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end


@interface MPIdentityHTTPErrorResponse ()

- (instancetype)initWithJsonObject:(nullable NSDictionary *)dictionary httpCode:(NSInteger) httpCode;
- (instancetype)initWithCode:(MPIdentityErrorResponseCode) code message: (NSString *) message error:(NSError *) error;

@end

@interface MPNetworkCommunication()

@property (nonatomic, strong, readonly) NSURL *segmentURL;
@property (nonatomic, strong, readonly) NSURL *configURL;
@property (nonatomic, strong, readonly) NSURL *eventURL;
@property (nonatomic, strong, readonly) NSURL *identifyURL;
@property (nonatomic, strong, readonly) NSURL *loginURL;
@property (nonatomic, strong, readonly) NSURL *logoutURL;
@property (nonatomic, strong, readonly) NSURL *modifyURL;
@property (nonatomic, strong, readonly) NSURL *aliasURL;

@property (nonatomic, strong) NSString *context;
@property (nonatomic, assign) BOOL identifying;

@end

@implementation MPNetworkCommunication

@synthesize configURL = _configURL;
@synthesize eventURL = _eventURL;
@synthesize identifyURL = _identifyURL;
@synthesize loginURL = _loginURL;
@synthesize logoutURL = _logoutURL;
@synthesize aliasURL = _aliasURL;
@synthesize identifying = _identifying;

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.identifying = NO;
    
    return self;
}

#pragma mark Private accessors
- (NSURL *)configURL {
    if (_configURL) {
        return _configURL;
    }
    
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    MPApplication *application = [[MPApplication alloc] init];
    NSString *configURLFormat = [urlFormat stringByAppendingString:@"?av=%@&sv=%@"];
    NSString *configHost = [MParticle sharedInstance].networkOptions.configHost ?: kMPURLHostConfig;
    NSString *urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, configHost, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, [application.version percentEscape], kMParticleSDKVersion];
    _configURL = [NSURL URLWithString:urlString];
    
    return _configURL;
}

- (NSURL *)eventURL {
    if (_eventURL) {
        return _eventURL;
    }
    
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *eventHost = [MParticle sharedInstance].networkOptions.eventsHost ?: kMPURLHost;
    NSString *urlString = [NSString stringWithFormat:urlFormat, kMPURLScheme, eventHost, kMPEventsVersion, stateMachine.apiKey, kMPEventsURL];
    _eventURL = [NSURL URLWithString:urlString];
    
    return _eventURL;
}

- (NSURL *)segmentURL {
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *segmentURLFormat = [urlFormat stringByAppendingString:@"?mpID=%@"];
    NSString *eventHost = [MParticle sharedInstance].networkOptions.eventsHost ?: kMPURLHost;
    NSString *urlString = [NSString stringWithFormat:segmentURLFormat, kMPURLScheme, eventHost, kMPSegmentVersion, stateMachine.apiKey, kMPSegmentURL, [MPPersistenceController mpId]];
    
    NSURL *segmentURL = [NSURL URLWithString:urlString];
    
    return segmentURL;
}

- (NSURL *)identifyURL {
    if (_identifyURL) {
        return _identifyURL;
    }
    NSString *pathComponent = @"identify";
    NSString *identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: kMPURLHostIdentity;
    NSString *urlString = [NSString stringWithFormat:identityURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, pathComponent];
    _identifyURL = [NSURL URLWithString:urlString];
    
    return _identifyURL;
}

- (NSURL *)loginURL {
    if (_loginURL) {
        return _loginURL;
    }
    
    NSString *pathComponent = @"login";
    NSString *identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: kMPURLHostIdentity;
    NSString *urlString = [NSString stringWithFormat:identityURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, pathComponent];
    _loginURL = [NSURL URLWithString:urlString];
    
    return _loginURL;
}

- (NSURL *)logoutURL {
    if (_logoutURL) {
        return _logoutURL;
    }
    
    NSString *pathComponent = @"logout";
    NSString *identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: kMPURLHostIdentity;
    NSString *urlString = [NSString stringWithFormat:identityURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, pathComponent];
    _logoutURL = [NSURL URLWithString:urlString];
    
    return _logoutURL;
}

- (NSURL *)modifyURL {
    NSString *pathComponent = @"modify";
    NSString *identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: kMPURLHostIdentity;
    NSString *urlString = [NSString stringWithFormat:modifyURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, [MPPersistenceController mpId], pathComponent];
    
    NSURL *modifyURL = [NSURL URLWithString:urlString];
    
    return modifyURL;
}

- (NSURL *)aliasURL {
    if (_aliasURL) {
        return _aliasURL;
    }
    
    NSString *pathComponent = @"alias";
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *eventHost = [MParticle sharedInstance].networkOptions.eventsHost ?: kMPURLHost;
    NSString *urlString = [NSString stringWithFormat:aliasURLFormat, kMPURLScheme, eventHost, kMPIdentityVersion, @"identity", stateMachine.apiKey, pathComponent];
    _aliasURL = [NSURL URLWithString:urlString];
    
    return _aliasURL;
}


- (BOOL)identifying {
    @synchronized(self) {
        return _identifying;
    }
}

- (void)setIdentifying:(BOOL)identifying {
    @synchronized(self) {
        _identifying = identifying;
    }
}

#pragma mark Private methods
- (void)throttleWithHTTPResponse:(NSHTTPURLResponse *)httpResponse uploadType:(MPUploadType)uploadType {
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
    
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:uploadType];
    if ([minUploadDate compare:now] == NSOrderedAscending) {
        [MParticle.sharedInstance.stateMachine setMinUploadDate:[now dateByAddingTimeInterval:retryAfter] uploadType:uploadType];
        if (uploadType == MPUploadTypeMessage) {
            MPILogDebug(@"Throttling uploads for %.0f seconds", retryAfter);
        } else if (uploadType == MPUploadTypeAlias) {
            MPILogDebug(@"Throttling alias requests for %.0f seconds", retryAfter);
        }
    }
}

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache {
    NSNumber *maxAge;
    cache = cache.lowercaseString;
    
    if ([cache containsString: @"max-age="]) {
        NSArray *maxAgeComponents = [cache componentsSeparatedByString:@"max-age="];
        NSString *beginningOfMaxAgeString = [maxAgeComponents objectAtIndex:1];
        NSArray *components = [beginningOfMaxAgeString componentsSeparatedByString:@","];
        NSString *maxAgeValue = [components objectAtIndex:0];
        
        maxAge = [NSNumber numberWithDouble:MIN([maxAgeValue doubleValue], CONFIG_REQUESTS_MAX_EXPIRATION_AGE)];
    }
    
    return maxAge;
}

#pragma mark Public methods
- (MPConnector *_Nonnull)makeConnector {
    return [[MPConnector alloc] init];
}

- (void)requestConfig:(nullable MPConnector *)connector withCompletionHandler:(void(^)(BOOL success))completionHandler {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    BOOL shouldSendRequest = [userDefaults isConfigurationExpired] || [userDefaults isConfigurationParametersOutdated];
    
    if (!shouldSendRequest) {
        completionHandler(YES);
        return;
    }
    
    __weak MPNetworkCommunication *weakSelf = self;
    
    MPILogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointConfig url:self.configURL.absoluteString body:@[]];
    
    connector = connector ? connector : [[MPConnector alloc] init];
    MPConnectorResponse *response = [connector responseFromGetRequestToURL:self.configURL];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSString *cacheControl = httpResponse.allHeaderFields[kMPHTTPCacheControlHeaderKey];
    NSString *ageString = httpResponse.allHeaderFields[kMPHTTPAgeHeaderKey];

    NSNumber *maxAge = [self maxAgeForCache:cacheControl];
        
    __strong MPNetworkCommunication *strongSelf = weakSelf;
    if (!strongSelf) {
        completionHandler(NO);
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    if (responseCode == HTTPStatusCodeNotModified) {
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        [userDefaults setConfiguration:[userDefaults getConfiguration] eTag:userDefaults[kMPHTTPETagHeaderKey] requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString maxAge:maxAge];
        
        completionHandler(YES);
        [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.absoluteString body:[NSDictionary dictionary] responseCode:responseCode];
        return;
    }
    
    BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
    
    if (!data && success) {
        completionHandler(NO);
        MPILogWarning(@"Failed config request");
        [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.absoluteString body:[NSDictionary dictionary] responseCode:HTTPStatusCodeNoContent];
        return;
    }
    
    success = success && [data length] > 0;

    NSDictionary *configurationDictionary = nil;
    if (success) {
        @try {
            NSError *serializationError = nil;
            configurationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            success = serializationError == nil && [configurationDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeConfig];
        } @catch (NSException *exception) {
            success = NO;
            responseCode = HTTPStatusCodeNoContent;
        }
    }
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.absoluteString body:configurationDictionary responseCode:responseCode];
    if (success && configurationDictionary) {
        NSDictionary *headersDictionary = [httpResponse allHeaderFields];
        NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
        if (!MPIsNull(eTag)) {
            MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configurationDictionary dataReceivedFromServer:YES];
            MPILogDebug(@"MPResponseConfig init: %@", responseConfig.description);

            MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
            [userDefaults setConfiguration:configurationDictionary eTag:eTag requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString maxAge:maxAge];
        }
        
        completionHandler(success);
    } else {
        completionHandler(NO);
    }
}

- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler {
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    __weak MPNetworkCommunication *weakSelf = self;
    NSDate *fetchSegmentsStartTime = [NSDate date];
    MPConnector *connector = [self makeConnector];

    MPConnectorResponse *response = [connector responseFromGetRequestToURL:self.segmentURL];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:fetchSegmentsStartTime];
    __strong MPNetworkCommunication *strongSelf = weakSelf;
    if (!strongSelf) {
        completionHandler(NO, nil, elapsedTime, nil);
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    
    if (!data) {
        completionHandler(NO, nil, elapsedTime, nil);
        return;
    }
    
    NSMutableArray<MPSegment *> *segments = nil;
    BOOL success = NO;
    
    NSArray *segmentsList = nil;
    NSInteger responseCode = [httpResponse statusCode];
    success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
    
    if (success) {
        NSError *serializationError = nil;
        NSDictionary *segmentsDictionary = nil;
        
        @try {
            segmentsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            success = serializationError == nil;
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
                                           code:MPNetworkErrorDelayedSegments
                                       userInfo:@{@"message":@"It took too long to retrieve segments."}];
        
        completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
    }
}

- (BOOL)performMessageUpload:(MPUpload *)upload {
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:MPUploadTypeMessage];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES;  //stop upload loop
    }
    
    NSString *uploadString = [upload serializedString];
    MPConnector *connector = [self makeConnector];
    
    MPILogVerbose(@"Beginning upload for upload ID: %@", upload.uuid);
    
    NSData *zipUploadData = [MPZip compressedDataFromData:upload.uploadData];
    if (zipUploadData == nil || zipUploadData.length <= 0) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointEvents url:self.eventURL.absoluteString body:@[uploadString, zipUploadData]];
    
    MPConnectorResponse *response = [connector responseFromPostRequestToURL:self.eventURL
                                                                    message:uploadString
                                                           serializedParams:zipUploadData];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Upload response code: %ld", (long)responseCode);
    BOOL isSuccessCode = responseCode >= 200 && responseCode < 300;
    BOOL isInvalidCode = responseCode != 429 && responseCode >= 400 && responseCode < 500;
    if (isSuccessCode || isInvalidCode) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
    }
    
    BOOL success = isSuccessCode && data && [data length] > 0;
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointEvents url:self.eventURL.absoluteString body:response.data responseCode:responseCode];
    if (success) {
        @try {
            NSError *serializationError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (responseDictionary &&
                serializationError == nil &&
                [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader]) {
                [MPResponseEvents parseConfiguration:responseDictionary];
            }
            MPILogVerbose(@"Upload complete: %@\n", uploadString);
            
        } @catch (NSException *exception) {
            MPILogError(@"Upload error: %@", [exception reason]);
        }
    }
    
    MPILogVerbose(@"Upload execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    // 429, 503
    if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
        [self throttleWithHTTPResponse:httpResponse uploadType:MPUploadTypeMessage];
        return YES;
    }
    
    //5xx, 0, 999, -1, etc
    if (!isSuccessCode && !isInvalidCode) {
        return YES;
    }
    
    return NO;
}

- (BOOL)performAliasUpload:(MPUpload *)upload {
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:MPUploadTypeAlias];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES; //stop upload loop
    }
    NSString *uploadString = [upload serializedString];
    MPConnector *connector = [self makeConnector];
    
    MPILogVerbose(@"Beginning alias request with upload ID: %@", upload.uuid);
    
    if (upload.uploadData == nil || upload.uploadData.length <= 0) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSURL *uploadURL = self.aliasURL;
    MPILogVerbose(@"Alias request:\nURL: %@ \nBody:%@", uploadURL, uploadString);
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointAlias url:self.aliasURL.absoluteString body:@[uploadString, upload.uploadData]];
    
    MPConnectorResponse *response = [connector responseFromPostRequestToURL:uploadURL
                                                                    message:uploadString
                                                           serializedParams:upload.uploadData];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Alias response code: %ld", (long)responseCode);
    
    BOOL isSuccessCode = responseCode >= 200 && responseCode < 300;
    BOOL isInvalidCode = responseCode != 429 && responseCode >= 400 && responseCode < 500;
    if (isSuccessCode || isInvalidCode) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
    }
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointAlias url:self.aliasURL.absoluteString body:response.data responseCode:responseCode];
    
    NSString *responseString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
    if (responseString != nil && responseString.length > 0) {
        MPILogVerbose(@"Alias response:\n%@", responseString);
    }
    
    MPAliasResponse *aliasResponse = [[MPAliasResponse alloc] init];
    aliasResponse.responseCode = responseCode;
    aliasResponse.willRetry = NO;
    
    NSDictionary *requestDictionary = [NSJSONSerialization JSONObjectWithData:upload.uploadData options:0 error:nil];
    NSNumber *sourceMPID = requestDictionary[@"source_mpid"];
    NSNumber *destinationMPID = requestDictionary[@"destination_mpid"];
    NSNumber *startTimeNumber = requestDictionary[@"start_unixtime_ms"];
    NSNumber *endTimeNumber = requestDictionary[@"end_unixtime_ms"];
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:startTimeNumber.doubleValue/1000];
    NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:endTimeNumber.doubleValue/1000];
    aliasResponse.requestID = requestDictionary[@"request_id"];
    aliasResponse.request = [MPAliasRequest requestWithSourceMPID:sourceMPID destinationMPID:destinationMPID startTime:startTime endTime:endTime];
    
    if (!isSuccessCode && data && data.length > 0) {
        @try {
            NSError *serializationError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (responseDictionary != nil && serializationError == nil) {
                NSString *message = responseDictionary[@"message"];
                NSNumber *code = responseDictionary[@"code"];
                MPILogError(@"Alias request failed - %@ %@", code, message);
                aliasResponse.errorResponse = message;
            }
        } @catch (NSException *exception) {
            MPILogError(@"Alias error: %@", [exception reason]);
        }
    }
    
    MPILogVerbose(@"Alias execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    // 429, 503
    if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
        aliasResponse.willRetry = YES;
        [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
        [self throttleWithHTTPResponse:httpResponse uploadType:upload.uploadType];
        return YES;
    }
    
    //5xx, 0, 999, -1, etc
    if (!isSuccessCode && !isInvalidCode) {
        [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
        return YES;
    }
    
    [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
    return NO;
}

- (void)upload:(NSArray<MPUpload *> *)uploads completionHandler:(MPUploadsCompletionHandler)completionHandler {
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    for (int index = 0; index < uploads.count; index++) {
        @autoreleasepool {
            MPUpload *upload = uploads[index];
            BOOL shouldStop = NO;
            if (upload.uploadType == MPUploadTypeMessage) {
                shouldStop = [self performMessageUpload:upload];
            } else if (upload.uploadType == MPUploadTypeAlias) {
                shouldStop = [self performAliasUpload:upload];
            }
            if (shouldStop){
                break;
            }
        }
    }
    
    if (![MPStateMachine isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    completionHandler();
}

- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion {
    
    if (self.identifying) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeRequestInProgress userInfo:@{mParticleIdentityErrorKey:@"Identity API request in progress."}]);
        }
        return;
    }
    
    if ([MParticle sharedInstance].stateMachine.optOut) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeOptOut userInfo:@{mParticleIdentityErrorKey:@"Opt Out Enabled."}]);
        }
        return;
    }
    
    if (blockOtherRequests) {
        self.identifying = YES;
    }
    __weak MPNetworkCommunication *weakSelf = self;
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                __strong MPNetworkCommunication *strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.identifying = NO;
                }
                
                [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *dictionary = [identityRequest dictionaryRepresentation];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *jsonRequest = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
    
    MPILogVerbose(@"Identity request:\nURL: %@ \nBody:%@", url, jsonRequest);
    
    MPEndpoint endpointType = MPEndpointIdentityModify;
    if ([self.identifyURL.absoluteString isEqualToString:url.absoluteString]) {
        endpointType = MPEndpointIdentityIdentify;
    } else if ([self.loginURL.absoluteString isEqualToString:url.absoluteString ]) {
        endpointType = MPEndpointIdentityLogin;
    } else if ([self.logoutURL.absoluteString isEqualToString:url.absoluteString]) {
        endpointType = MPEndpointIdentityLogout;
    }
    [MPListenerController.sharedInstance onNetworkRequestStarted:endpointType url:url.absoluteString body:data];

    MPConnector *connector = [self makeConnector];
    MPConnectorResponse *response = [connector responseFromPostRequestToURL:url
                                                                    message:nil
                                                           serializedParams:data];
    NSData *responseData = response.data;
    NSError *error = response.error;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    __strong MPNetworkCommunication *strongSelf = weakSelf;
    
    if (!strongSelf) {
        if (completion) {
            MPIdentityHTTPErrorResponse *errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithJsonObject:nil httpCode:0];
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeUnknown userInfo:@{mParticleIdentityErrorKey:errorResponse}]);
        }
        
        return;
    }
    
    if (![MPStateMachine isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    
    NSDictionary *responseDictionary = nil;
    NSString *responseString = nil;
    NSInteger responseCode = [httpResponse statusCode];
    BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
    
    success = success && [responseData length] > 0;
    
    NSError *serializationError = nil;
    
    MPILogVerbose(@"Identity response code: %ld", (long)responseCode);
    
    if (success) {
        @try {
            responseString = [[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding];
            responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:0
                                                                   error:&serializationError];
        } @catch (NSException *exception) {
            responseDictionary = nil;
            success = NO;
            MPILogError(@"Identity response serialization error: %@", [exception reason]);
        }
    }
    
    MPILogVerbose(@"Identity execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    strongSelf.identifying = NO;
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:endpointType url:url.absoluteString body:responseDictionary responseCode:responseCode];
    if (success) {
        if (responseString) {
            MPILogVerbose(@"Identity response:\n%@", responseString);
        }
        BOOL isModify = [identityRequest isMemberOfClass:[MPIdentityHTTPModifyRequest class]];
        if (isModify) {
            MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
            if (completion) {
                completion(successResponse, nil);
            }
        } else {
            MPIdentityHTTPSuccessResponse *response = [[MPIdentityHTTPSuccessResponse alloc] initWithJsonObject:responseDictionary];
            _context = response.context;
            if (completion) {
                completion(response, nil);
            }
        }
    } else {
        if (completion) {
            MPIdentityHTTPErrorResponse *errorResponse;
            if (error) {
                if (error.code == MPConnectivityErrorCodeNoConnection) {
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeClientNoConnection message:@"Device has no network connectivity." error:error];
                } else if ([error.domain isEqualToString: NSURLErrorDomain] ){
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeSSLError message:@"Failed to establish SSL connection." error:error];
                } else {
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeUnknown message:@"An unknown client-side error has occured" error:error];
                }
            } else {
                errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithJsonObject:responseDictionary httpCode:responseCode];
            }
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:errorResponse.code userInfo:@{mParticleIdentityErrorKey:errorResponse}]);
        }
    }
}

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:identifyRequest];
    [self identityApiRequestWithURL:self.identifyURL identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:loginRequest];
    [self identityApiRequestWithURL:self.loginURL identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable
                                                                          MPIdentityApiManagerCallback)completion {
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:logoutRequest];
    [self identityApiRequestWithURL:self.logoutURL identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    
    NSMutableArray *identityChanges = [NSMutableArray array];
    
    NSDictionary *identitiesDictionary = modifyRequest.userIdentities;
    NSDictionary *existingIdentities = [MParticle sharedInstance].identity.currentUser.userIdentities;
    
    [identitiesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull identityType, NSString *value, BOOL * _Nonnull stop) {
        NSString *oldValue = existingIdentities[identityType];
        
        if ((NSNull *)value == [NSNull null]) {
            value = nil;
        }
        
        if (!oldValue || ![value isEqualToString:oldValue]) {
            MPUserIdentity userIdentity = (MPUserIdentity)[identityType intValue];
            NSString *stringType = [MPIdentityHTTPIdentities stringForIdentityType:userIdentity];
            MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:stringType];
            [identityChanges addObject:identityChange];
        }
    }];
    
    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:YES completion:completion];
    
}

- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue {
    NSMutableArray *identityChanges = [NSMutableArray array];
    MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:deviceIdType];
    [identityChanges addObject:identityChange];
    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:NO completion:nil];
}

- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    
    if (identityChanges == nil || identityChanges.count == 0) {
        if (completion) {
            completion([[MPIdentityHTTPModifySuccessResponse alloc] init], nil);
        }
        return;
    }

    NSString *mpid = [MPPersistenceController mpId].stringValue;
    MPIdentityHTTPModifyRequest *request = [[MPIdentityHTTPModifyRequest alloc] initWithMPID:mpid identityChanges:[identityChanges copy]];
    
    [self identityApiRequestWithURL:self.modifyURL identityRequest:request blockOtherRequests:blockOtherRequests completion:^(MPIdentityHTTPBaseSuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        if (completion) {
            completion((MPIdentityHTTPModifySuccessResponse *)httpResponse, error);
        }
    }];
}

@end
