//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-apps for information
//    https://docs.newrelic.com/docs/releases/ios for release notes
//
//  Copyright (c) 2014 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

//Custom Trace Types
enum NRTraceType {
    NRTraceTypeNone,
    NRTraceTypeViewLoading,
    NRTraceTypeLayout,
    NRTraceTypeDatabase,
    NRTraceTypeImages,
    NRTraceTypeJson,
    NRTraceTypeNetwork
};

#define kNRNetworkStatusDidChangeNotification @"com.newrelic.networkstatus.changed"
#define kNRCarrierNameDidUpdateNotifcation @"com.newrelic.carrierName.changed"
#define kNRMemoryUsageDidChangeNotification @"com.newrelic.memoryusage.changed"
#define kNRInteractionDidCompleteNotification @"com.newrelic.interaction.complete"


//Custom Metric Units
typedef NSString NRMetricUnit;

#define kNRMetricUnitPercent            (NRMetricUnit*)@"%"
#define kNRMetricUnitBytes              (NRMetricUnit*)@"bytes"
#define kNRMetricUnitSeconds            (NRMetricUnit*)@"sec"
#define kNRMetricUnitsBytesPerSecond    (NRMetricUnit*)(@"bytes/second")
#define kNRMetricUnitsOperations        (NRMetricUnit*)@"op"

#define kNRSupportabilityPrefix          @"Supportability/MobileAgent"
#define kNRAgentHealthPrefix             @"Supportability/AgentHealth"
#define kNRMASessionStartMetric           @"Session/Start"

#define kNRMAExceptionHandlerHijackedMetric kNRAgentHealthPrefix @"/Hijacked/ExceptionHandler"

#define kNRCarrierNameCacheLifetime     50 // milliseconds
#define kNRWanTypeCacheLifetime         25 // milliseconds
#define kNRNetworkStatusCacheLifetime   25 // milliseconds

// Network Failure Codes
enum NRNetworkFailureCode {
        NRURLErrorUnknown = -1,
        NRURLErrorCancelled = -999,
        NRURLErrorBadURL = -1000,
        NRURLErrorTimedOut = -1001,
        NRURLErrorUnsupportedURL = -1002,
        NRURLErrorCannotFindHost = -1003,
        NRURLErrorCannotConnectToHost = -1004,
        NRURLErrorDataLengthExceedsMaximum = -1103,
        NRURLErrorNetworkConnectionLost = -1005,
        NRURLErrorDNSLookupFailed = -1006,
        NRURLErrorHTTPTooManyRedirects = -1007,
        NRURLErrorResourceUnavailable = -1008,
        NRURLErrorNotConnectedToInternet = -1009,
        NRURLErrorRedirectToNonExistentLocation = -1010,
        NRURLErrorBadServerResponse = -1011,
        NRURLErrorUserCancelledAuthentication = -1012,
        NRURLErrorUserAuthenticationRequired = -1013,
        NRURLErrorZeroByteResource = -1014,
        NRURLErrorCannotDecodeRawData = -1015,
        NRURLErrorCannotDecodeContentData = -1016,
        NRURLErrorCannotParseResponse = -1017,
        NRURLErrorInternationalRoamingOff = -1018,
        NRURLErrorCallIsActive = -1019,
        NRURLErrorDataNotAllowed = -1020,
        NRURLErrorRequestBodyStreamExhausted = -1021,
        NRURLErrorFileDoesNotExist = -1100,
        NRURLErrorFileIsDirectory = -1101,
        NRURLErrorNoPermissionsToReadFile = -1102,
        NRURLErrorSecureConnectionFailed = -1200,
        NRURLErrorServerCertificateHasBadDate = -1201,
        NRURLErrorServerCertificateUntrusted = -1202,
        NRURLErrorServerCertificateHasUnknownRoot = -1203,
        NRURLErrorServerCertificateNotYetValid = -1204,
        NRURLErrorClientCertificateRejected = -1205,
        NRURLErrorClientCertificateRequired = -1206,
        NRURLErrorCannotLoadFromNetwork = -2000,
        NRURLErrorCannotCreateFile = -3000,
        NRURLErrorCannotOpenFile = -3001,
        NRURLErrorCannotCloseFile = -3002,
        NRURLErrorCannotWriteToFile = -3003,
        NRURLErrorCannotRemoveFile = -3004,
        NRURLErrorCannotMoveFile = -3005,
        NRURLErrorDownloadDecodingFailedMidStream = -3006,
        NRURLErrorDownloadDecodingFailedToComplete = -3007
};

#ifdef __cplusplus
}
#endif
