#import "MPConnector.h"
#import <dispatch/dispatch.h>
#import "MPIConstants.h"
#import "MPURLRequestBuilder.h"
#import "MPNetworkCommunication.h"
#import "MPILogger.h"
#import "mParticle.h"

static NSArray *mpStoredCertificates = nil;

@implementation MPConnectorResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = nil;
        _error = nil;
        _downloadTime = 0;
        _httpResponse = nil;
    }
    return self;
}

@end

@interface MPConnector() <NSURLSessionDelegate, NSURLSessionTaskDelegate> {
    NSMutableData *receivedData;
    NSDate *requestStartTime;
    NSHTTPURLResponse *httpURLResponse;
}

@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse);
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation MPConnector

+ (void)initialize {
    mpStoredCertificates = @[//@"MIIFKTCCBBGgAwIBAgIHBH07xuCK0zANBgkqhkiG9w0BAQsFADCBtDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0xNDA0MDgyMTEzMDRaFw0xNjEwMDIyMDI3MDJaMD0xITAfBgNVBAsTGERvbWFpbiBDb250cm9sIFZhbGlkYXRlZDEYMBYGA1UEAwwPKi5tcGFydGljbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsjbTIFnjV0QoNtlmvGRIIk/XboAD/xqiarLxhAot8Ju15vDOqugJBHERXVLxp0vUzedGAjf2ZEJc3o3WtmJxOH/dZF3qOLolaCspYlhVebWWl56UWNkI2K4fMGFjQxXPSvz6vGbDXmz7J2Pd5dvhSt2W9OkvlKLyhnIvLxxBJNTZKmEKVYALI6/g2Sj3nTRU2QVnYfCPHzY7SMDmjf++tgnx5hZBQsDE2JJrcbvtTDrnTLMYLu80ZLtuqJPJxMklmWTqoVCeHOY4YH5d4+NWpaDlzZpyrf1quHwM8bYCYulY1Lt8j2EPqeDXtvNqm6NBJOd62N3s/2v+pEx1l7QWVQIDAQABo4IBtDCCAbAwDwYDVR0TAQH/BAUwAwEBADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQDAgWgMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ29kYWRkeS5jb20vZ2RpZzJzMS0zOC5jcmwwUwYDVR0gBEwwSjBIBgtghkgBhv1tAQcXATA5MDcGCCsGAQUFBwIBFitodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZ29kYWRkeS5jb20vMEAGCCsGAQUFBzAChjRodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvZ2RpZzIuY3J0MB8GA1UdIwQYMBaAFEDCvSeOzDSDMKIz1/tss/C0LIDOMCkGA1UdEQQiMCCCDyoubXBhcnRpY2xlLmNvbYINbXBhcnRpY2xlLmNvbTAdBgNVHQ4EFgQUL0tchcqkPxXzy2vczY9CCsTbOGswDQYJKoZIhvcNAQELBQADggEBAH7LRQr5ChlMcyXUKttWAs6n7mUs/xO3GkxdGzavRw/QHM3LIZ46rkpxow0+WfOhu9NwMSN0X6kWSh18WerHVKkMgxf+1SFdaujbVEA2+7OU/HNUjezABH4uFrDu44/DVs5OxX4KGaQZw1wpghFB3NsNG0dHI+V3f7AGBw/gxE2mp+9spkInWOAmaIBqmLps8dqlAbvru2m6gWehSpjc7AVPTLY6ykY4nanld1ta8tOmFUJ/TEPnp5IMpXObFPQetLwCfV4C/+UF4Jq9JjIts69URdYjxQocL6r8mXNHWixdwqHbkMRpx1hEYxtKjTwMlSAthKpG0yjYV2eEUv0KCuU=", // Leaf - Ignored
                             @"MIIE0DCCA7igAwIBAgIBBzANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTExMDUwMzA3MDAwMFoXDTMxMDUwMzA3MDAwMFowgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC54MsQ1K92vdSTYuswZLiBCGzDBNliF44v/z5lz4/OYuY8UhzaFkVLVat4a2ODYpDOD2lsmcgaFItMzEUz6ojcnqOvK/6AYZ15V8TPLvQ/MDxdR/yaFrzDN5ZBUY4RS1T4KL7QjL7wMDge87Am+GZHY23ecSZHjzhHU9FGHbTj3ADqRay9vHHZqm8A29vNMDp5T19MR/gd71vCxJ1gO7GyQ5HYpDNO6rPWJ0+tJYqlxvTV0KaudAVkV4i1RFXULSo6Pvi4vekyCgKUZMQWOlDxSq7neTOvDCAHf+jfBDnCaQJsY1L6d8EbyHSHyLmTGFBUNUtpTrw700kuH9zB0lL7AgMBAAGjggEaMIIBFjAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUQMK9J47MNIMwojPX+2yz8LQsgM4wHwYDVR0jBBgwFoAUOpqFBxBnKLbv9r0FQW4gwZTaD94wNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wNQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZHJvb3QtZzIuY3JsMEYGA1UdIAQ/MD0wOwYEVR0gADAzMDEGCCsGAQUFBwIBFiVodHRwczovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQAIfmyTEMg4uJapkEv/oV9PBO9sPpyIBslQj6Zz91cxG7685C/b+LrTW+C05+Z5Yg4MotdqY3MxtfWoSKQ7CC2iXZDXtHwlTxFWMMS2RJ17LJ3lXubvDGGqv+QqG+6EnriDfcFDzkSnE3ANkR/0yBOtg2DZ2HKocyQetawiDsoXiWJYRBuriSUBAA/NxBti21G00w9RKpv0vHP8ds42pM3Z2Czqrpv1KrKQ0U11GIo/ikGQI31bS/6kA1ibRrLDYGCD+H1QQc7CoZDDu+8CL9IVVO5EFdkKrqeKM+2xLXY2JtwE65/3YR8V3Idv7kaWKK2hJn0KCacuBKONvPi8BDAB", // Intermediate
                             @"MIIDxTCCAq2gAwIBAgIBADANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5MDkwMTAwMDAwMFoXDTM3MTIzMTIzNTk1OVowgYMxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjExMC8GA1UEAxMoR28gRGFkZHkgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL9xYgjx+lk09xvJGKP3gElY6SKDE6bFIEMBO4Tx5oVJnyfq9oQbTqC023CYxzIBsQU+B07u9PpPL1kwIuerGVZr4oAH/PMWdYA5UXvl+TW2dE6pjYIT5LY/qQOD+qK+ihVqf94Lw7YZFAXK6sOoBJQ7RnwyDfMAZiLIjWltNowRGLfTshxgtDj6AozO091GB94KPutdfMh8+7ArU6SSYmlRJQVhGkSBjCypQ5Yj36w6gZoOKcUcqeldHraenjAKOc7xiID7S13MMuyFYkMlNAJWJwGRtDtwKj9useiciAF9n9T521NtYJ2/LOdYq7hfRvzOxBsDPAnrSTFcaUaz4EcCAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFDqahQcQZyi27/a9BUFuIMGU2g/eMA0GCSqGSIb3DQEBCwUAA4IBAQCZ21151fmXWWcDYfF+OwYxdS2hII5PZYe096acvNjpL9DbWu7PdIxztDhC2gV7+AJ1uP2lsdeu9tfeE8tTEH6KRtGX+rcuKxGrkLAngPnon1rpN5+r5N9ss4UXnT3ZJE95kTXWXwTrgIOrmgIttRD02JDHBHNA7XIloKmf7J6raBKZV8aPEjoJpL1E/QYVN8Gb5DKj7Tjo2GTzLH4U/ALqn83/B2gX2yKQOC16jdFU8WnjXzPKej17CuPKf1855eJ1usV2GDPOLPAvTK33sefOT6jEm0pUBsV/fdUID+Ic/n4XuKxe9tQWskMJDE32p2u0mYRlynqI4uJEvlz36hz1"]; // Root
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _dataTask = nil;
    requestStartTime = nil;
    _completionHandler = nil;
    httpURLResponse = nil;
    receivedData = nil;
    
    return self;
}

#pragma mark Private methods
- (NSURLSession *)urlSession {
    if (_urlSession) {
        return _urlSession;
    }
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 30;
    _urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    
    _urlSession.sessionDescription = [[NSUUID UUID] UUIDString];
    
    return _urlSession;
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    _urlSession = nil;
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    NSString *authenticationMethod = [protectionSpace authenticationMethod];
    NSString *host = [protectionSpace host];
    NSString *protocol = [protectionSpace protocol];
    __block SecTrustRef serverTrust = [protectionSpace serverTrust];
    MPNetworkOptions *networkOptions = [[MParticle sharedInstance] networkOptions];
    
    BOOL isMParticleHost = [host rangeOfString:@"mparticle.com"].location != NSNotFound;
    
    BOOL isNetworkOptionsHost = [host isEqualToString:networkOptions.configHost] || [host isEqualToString:networkOptions.identityHost] || [host isEqualToString:networkOptions.eventsHost];
    
    BOOL isPinningHost = isMParticleHost || isNetworkOptionsHost;
    
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] &&
        isPinningHost &&
        [protocol isEqualToString:kMPURLScheme] &&
        [protectionSpace receivesCredentialSecurely] &&
        serverTrust)
    {
        SecTrustCallback evaluateResult = ^(SecTrustRef _Nonnull trustRef, SecTrustResultType trustResult) {
            BOOL trustChallenge = NO;
            
            if (trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed) {
                CFIndex certificateCount = SecTrustGetCertificateCount(trustRef);
                
                for (CFIndex certIdx = 1; certIdx < certificateCount; ++certIdx) {
                    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trustRef, certIdx);
                    CFDataRef certificateDataRef = SecCertificateCopyData(certificate);
                    
                    if (certificateDataRef != NULL) {
                        NSData *certificateData = (__bridge NSData *)certificateDataRef;
                        
                        if (certificateData) {
                            NSString *certificateEncodedString = [certificateData base64EncodedStringWithOptions:0];
                            trustChallenge = [mpStoredCertificates containsObject:certificateEncodedString];
                            
                            if (!trustChallenge && networkOptions.certificates.count > 0) {
                                trustChallenge = [networkOptions.certificates containsObject:certificateData];
                            }
                        }
                        
                        
                        CFRelease(certificateDataRef);
                    }
                    
                    if (!trustChallenge) {
                        break;
                    }
                }
            }
            
            BOOL shouldDisablePinning = networkOptions.pinningDisabledInDevelopment && [MParticle sharedInstance].environment == MPEnvironmentDevelopment;
            if (trustChallenge || shouldDisablePinning) {
                NSURLCredential *urlCredential = [NSURLCredential credentialForTrust:trustRef];
                completionHandler(NSURLSessionAuthChallengeUseCredential, urlCredential);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        };
        
        SecTrustEvaluateAsync(serverTrust, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), evaluateResult);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    httpURLResponse = (NSHTTPURLResponse *)response;
    NSInteger responseCode = [httpURLResponse statusCode];
    
    if (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) {
        if (httpURLResponse.expectedContentLength != NSURLResponseUnknownLength && httpURLResponse.expectedContentLength > 0) {
            receivedData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)httpURLResponse.expectedContentLength];
        } else {
            receivedData = [[NSMutableData alloc] init];
        }
    } else {
        receivedData = nil;
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (!error) {
        NSDate *endTime = [NSDate date];
        NSTimeInterval downloadTime = [endTime timeIntervalSinceDate:requestStartTime];
        
        if (self.completionHandler != nil && self.completionHandler != NULL) {
            @try {
                self.completionHandler(receivedData, nil, downloadTime, httpURLResponse);
            } @catch (NSException *exception) {
                MPILogError(@"Error invoking the completion handler of a data download task.");
            }
        }
    } else {
        if (self.completionHandler != nil && self.completionHandler != NULL) {
            @try {
                self.completionHandler(nil, error, 0, nil);
            } @catch (NSException *exception) {
                MPILogError(@"Error invoking the completion handler of a data download task with error: %@.", [error localizedDescription]);
            }
        }
    }
    [_urlSession finishTasksAndInvalidate];
    _urlSession = nil;
}

#pragma mark Public methods
- (nonnull MPConnectorResponse *)responseFromGetRequestToURL:(nonnull NSURL *)url {
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:kMPHTTPMethodGet] build];
    
    if (urlRequest) {
        requestStartTime = [NSDate date];
        dispatch_semaphore_t requestSemaphore = dispatch_semaphore_create(0);
        __block NSData *completionData = nil;
        __block NSError *completionError = nil;
        __block NSTimeInterval completionDownloadTime = 0;
        __block NSHTTPURLResponse *completionHttpResponse = nil;
        self.completionHandler = ^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
            completionData = data;
            completionError = error;
            completionDownloadTime = downloadTime;
            completionHttpResponse = httpResponse;
            dispatch_semaphore_signal(requestSemaphore);
        };
        
        self.dataTask = [self.urlSession dataTaskWithRequest:urlRequest];
        [_dataTask resume];
        dispatch_semaphore_wait(requestSemaphore, DISPATCH_TIME_FOREVER);
        response.data = completionData;
        response.error = completionError;
        response.downloadTime = completionDownloadTime;
        response.httpResponse = completionHttpResponse;
    } else {
        response.error = [NSError errorWithDomain:@"MPConnector" code:1 userInfo:nil];
    }
    
    return response;
}

- (nonnull MPConnectorResponse *)responseFromPostRequestToURL:(nonnull NSURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams {
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    
    NSMutableURLRequest *urlRequest = [[[MPURLRequestBuilder newBuilderWithURL:url message:message httpMethod:kMPHTTPMethodPost]
                                             withPostData:serializedParams]
                                            build];
    
    if (urlRequest) {
        requestStartTime = [NSDate date];
        dispatch_semaphore_t requestSemaphore = dispatch_semaphore_create(0);
        __block NSData *completionData = nil;
        __block NSError *completionError = nil;
        __block NSTimeInterval completionDownloadTime = 0;
        __block NSHTTPURLResponse *completionHttpResponse = nil;
        self.completionHandler = ^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
            completionData = data;
            completionError = error;
            completionDownloadTime = downloadTime;
            completionHttpResponse = httpResponse;
            dispatch_semaphore_signal(requestSemaphore);
        };
        self.dataTask = [self.urlSession uploadTaskWithRequest:urlRequest fromData:serializedParams];
        [_dataTask resume];
        dispatch_semaphore_wait(requestSemaphore, DISPATCH_TIME_FOREVER);
        response.data = completionData;
        response.error = completionError;
        response.downloadTime = completionDownloadTime;
        response.httpResponse = completionHttpResponse;
    } else {
        response.error = [NSError errorWithDomain:@"MPConnector" code:1 userInfo:nil];
    }
    return response;
}

@end
