#import "MPNetworkPerformance.h"
#import "MPIConstants.h"

NSString *const kMPNetworkPerformanceURLKey = @"url";
NSString *const kMPNetworkPerformanceTimeElapsedKey = @"te";
NSString *const kMPNetworkPerformanceBytesInKey = @"bi";
NSString *const kMPNetworkPerformanceBytesOutKey = @"bo";
NSString *const kMPNetworkPerformanceResponseCodeKey = @"rc";
NSString *const kMPNetworkPerformanceHttpMethodKey = @"v";
NSString *const kMPNetworkPerformanceHttpPostBody = @"d";

NSString *const npURLFormat = @"%@://%@%@";
NSString *const GoogleAnalyticsSecureURL = @"https://ssl.google-analytics.com/collect";
NSString *const GoogleAnalyticsPlainURL = @"http://www.google-analytics.com/collect";

@interface MPNetworkPerformance() {
    NSURL *url;
    NSURLRequest *urlRequest;
}

@end


@implementation MPNetworkPerformance

@synthesize POSTBody = _POSTBody;

- (instancetype)initWithURLRequest:(NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _networkMeasurementMode = networkMeasurementMode;
    
    urlRequest = [request copy];
    
    switch (_networkMeasurementMode) {
        case MPNetworkMeasurementModeAbridged:
            url = urlRequest.URL;
            _urlString = [NSString stringWithFormat:npURLFormat, [url scheme], [url host], [url relativePath]];
            break;
            
        case MPNetworkMeasurementModePreserveQuery:
            url = urlRequest.URL;
            _urlString = [url absoluteString];
            break;
            
        case MPNetworkMeasurementModeExclude:
            url = nil;
            _urlString = nil;
            break;
    }
    
    _httpMethod = [urlRequest HTTPMethod];
    if (!_httpMethod) {
        _httpMethod = kMPHTTPMethodGet;
    }
    _startTime = 0;
    _endTime = 0;
    _elapsedTime = 0;
    _bytesIn = 0;
    _bytesOut = 0;
    _responseCode = 0;
    
    return self;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MPNetworkPerformance *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        [copyObject setUrlString:[_urlString copy]];
        copyObject->_httpMethod = [_httpMethod copy];
        [copyObject setStartTime:_startTime];
        [copyObject setEndTime:_endTime];
        [copyObject setElapsedTime:_elapsedTime];
        [copyObject setBytesIn:_bytesIn];
        [copyObject setBytesOut:_bytesOut];
        [copyObject setResponseCode:_responseCode];
        copyObject->_networkMeasurementMode = _networkMeasurementMode;
        copyObject->urlRequest = [urlRequest copy];
    }
    
    return copyObject;
}

#pragma mark Accessors
- (void)setStartTime:(NSTimeInterval)startTime {
    _startTime = startTime;
    
    if (_endTime != 0) {
        _elapsedTime = trunc(_endTime - _startTime);
    }
}

- (void)setEndTime:(NSTimeInterval)endTime {
    _endTime = endTime;
    
    if (_startTime != 0) {
        _elapsedTime = trunc(_endTime - _startTime);
    }
}

- (void)setElapsedTime:(NSTimeInterval)elapsedTime {
    _elapsedTime = elapsedTime;
    
    if (_startTime != 0) {
        _endTime = _startTime + _elapsedTime;
    }
}

- (NSString *)POSTBody {
    if (_POSTBody) {
        return _POSTBody;
    }
    
    NSString *urlString = [urlRequest.URL absoluteString];
    
    if (([urlString isEqualToString:GoogleAnalyticsSecureURL] || [urlString isEqualToString:GoogleAnalyticsPlainURL]) &&
        (urlRequest.HTTPBody != nil) &&
        [urlRequest.HTTPMethod isEqualToString:kMPHTTPMethodPost])
    {
        _POSTBody = [[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding];
    }
    
    return _POSTBody;
}

#pragma mark Public methods
- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"Network Performance \nURL: %@ \nHTTP Method: %@ \nStart Time: %.2f \nEnd Time: %.2f \nElapsedTime: %.2f \nBytes In: %ld \nBytes Out: %ld \nResponseCode: %ld\n\n",
                             [urlRequest.URL absoluteString], _httpMethod, _startTime, _endTime, _elapsedTime, (long)_bytesIn, (long)_bytesOut, (long)_responseCode];
    return description;
}

- (void)setStartDate:(NSDate *)date {
    self.startTime = [date timeIntervalSince1970] * 1000;
}

- (void)setEndDate:(NSDate *)date {
    self.endTime = [date timeIntervalSince1970] * 1000;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *messageDictionary = [@{kMPNetworkPerformanceHttpMethodKey:self.httpMethod,
                                                kMPNetworkPerformanceTimeElapsedKey:@(self.elapsedTime),
                                                kMPNetworkPerformanceBytesInKey:@(self.bytesIn),
                                                kMPNetworkPerformanceBytesOutKey:@(self.bytesOut)}
                                              mutableCopy];
    
    if (self.urlString) {
        messageDictionary[kMPNetworkPerformanceURLKey] = self.urlString;
    }
    
    if (_responseCode != 0) {
        messageDictionary[kMPNetworkPerformanceResponseCodeKey] = @(self.responseCode);
    } else {
        messageDictionary[kMPNetworkPerformanceResponseCodeKey] = @200;
    }
    
    if (self.POSTBody) {
        messageDictionary[kMPNetworkPerformanceHttpPostBody] = self.POSTBody;
    }
    
    return [messageDictionary copy];
}

@end
