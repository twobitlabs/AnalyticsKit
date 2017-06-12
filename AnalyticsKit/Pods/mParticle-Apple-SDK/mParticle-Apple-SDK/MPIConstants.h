//
//  MPIConstants.h
//
//  Copyright 2015 mParticle, Inc.
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

#ifndef mParticleSDK_MPIConstants_h
#define mParticleSDK_MPIConstants_h

#import <Foundation/Foundation.h>

#define MPMilliseconds(timestamp) @(trunc((timestamp) * 1000))
#define MPCurrentEpochInMilliseconds @(trunc([[NSDate date] timeIntervalSince1970] * 1000))

#define CRASH_LOGS_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"CrashLogs"];
#define ARCHIVED_MESSAGES_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"ArchivedMessages"];
#define STATE_MACHINE_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"StateMachine"];

#define MPIsNull(object) (!(object) || (NSNull *)(object) == [NSNull null])

typedef NS_ENUM(NSInteger, MPUploadStatus) {
    MPUploadStatusUnknown = -1,
    MPUploadStatusStream = 0,
    MPUploadStatusBatch,
    MPUploadStatusUploaded
};

// Types of messages as defined by the Javascript SDK
typedef NS_ENUM(NSUInteger, MPJavascriptMessageType) {
    MPJavascriptMessageTypeSessionStart = 1,    /** Session start */
    MPJavascriptMessageTypeSessionEnd,   /** Session end */
    MPJavascriptMessageTypePageView,     /** Page/Screen view */
    MPJavascriptMessageTypePageEvent,      /** User/transaction event */
    MPJavascriptMessageTypeError,       /** Error event */
    MPJavascriptMessageTypeOptOut,    /** Opt out */
    MPJavascriptMessageTypeCommerce = 16  /** Product action, promotion or impression */
};

typedef NS_ENUM(NSInteger, MPDataType) {
    MPDataTypeString = 1,
    MPDataTypeInt = 2,
    MPDataTypeBool = 3,
    MPDataTypeFloat = 4,
    MPDataTypeLong = 5
};

// mParticle SDK Version
extern NSString * _Nonnull const kMParticleSDKVersion;

// Session Upload Settings
extern NSString * _Nonnull const kMPSessionHistoryValue;

// Message Type (dt)
extern NSString * _Nonnull const kMPMessageTypeKey;                  
extern NSString * _Nonnull const kMPMessageTypeRequestHeader;
extern NSString * _Nonnull const kMPMessageTypeResponseHeader;
extern NSString * _Nonnull const kMPMessageTypeConfig;
extern NSString * _Nonnull const kMPMessageTypeNetworkPerformance;
extern NSString * _Nonnull const kMPMessageTypeLeaveBreadcrumbs;

// Request Header Keys
extern NSString * _Nonnull const kMPmParticleSDKVersionKey;
extern NSString * _Nonnull const kMPApplicationKey;

// Device Information Keys
extern NSString * _Nonnull const kMPDeviceCydiaJailbrokenKey;
extern NSString * _Nonnull const kMPDeviceSupportedPushNotificationTypesKey;

// Launch Keys
extern NSString * _Nonnull const kMPLaunchSourceKey;
extern NSString * _Nonnull const kMPLaunchURLKey;
extern NSString * _Nonnull const kMPLaunchParametersKey;
extern NSString * _Nonnull const kMPLaunchSessionFinalizedKey;
extern NSString * _Nonnull const kMPLaunchNumberOfSessionInterruptionsKey;

// Message Keys
extern NSString * _Nonnull const kMPMessagesKey;                      
extern NSString * _Nonnull const kMPMessageIdKey;                     
extern NSString * _Nonnull const kMPTimestampKey;                   
extern NSString * _Nonnull const kMPSessionIdKey;                     
extern NSString * _Nonnull const kMPSessionStartTimestamp;           
extern NSString * _Nonnull const kMPEventStartTimestamp;              
extern NSString * _Nonnull const kMPEventLength;                     
extern NSString * _Nonnull const kMPEventNameKey;
extern NSString * _Nonnull const kMPEventTypeKey;
extern NSString * _Nonnull const kMPEventLengthKey;
extern NSString * _Nonnull const kMPAttributesKey;                   
extern NSString * _Nonnull const kMPLocationKey;
extern NSString * _Nonnull const kMPUserAttributeKey;
extern NSString * _Nonnull const kMPUserAttributeDeletedKey;
extern NSString * _Nonnull const kMPEventTypePageView;
extern NSString * _Nonnull const kMPUserIdentityArrayKey;
extern NSString * _Nonnull const kMPUserIdentityIdKey;
extern NSString * _Nonnull const kMPUserIdentityTypeKey;
extern NSString * _Nonnull const kMPAppStateTransitionType;
extern NSString * _Nonnull const kMPEventTagsKey;
extern NSString * _Nonnull const kMPLeaveBreadcrumbsKey;
extern NSString * _Nonnull const kMPSessionNumberKey;
extern NSString * _Nonnull const kMPOptOutKey;
extern NSString * _Nonnull const kMPDateUserIdentityWasFirstSet;
extern NSString * _Nonnull const kMPIsFirstTimeUserIdentityHasBeenSet;
extern NSString * _Nonnull const kMPRemoteNotificationCampaignHistoryKey;
extern NSString * _Nonnull const kMPRemoteNotificationContentIdHistoryKey;
extern NSString * _Nonnull const kMPRemoteNotificationTimestampHistoryKey;
extern NSString * _Nonnull const kMPProductBagKey;
extern NSString * _Nonnull const kMPForwardStatsRecord;

// Push Notifications
extern NSString * _Nonnull const kMPDeviceTokenKey;
extern NSString * _Nonnull const kMPPushStatusKey;
extern NSString * _Nonnull const kMPPushMessageTypeKey;
extern NSString * _Nonnull const kMPPushMessageReceived;
extern NSString * _Nonnull const kMPPushMessageAction;
extern NSString * _Nonnull const kMPPushMessageSent;
extern NSString * _Nonnull const kMPPushMessageProviderKey;
extern NSString * _Nonnull const kMPPushMessageProviderValue;
extern NSString * _Nonnull const kMPPushMessagePayloadKey;
extern NSString * _Nonnull const kMPPushNotificationStateKey;
extern NSString * _Nonnull const kMPPushNotificationStateNotRunning;
extern NSString * _Nonnull const kMPPushNotificationStateBackground;
extern NSString * _Nonnull const kMPPushNotificationStateForeground;
extern NSString * _Nonnull const kMPPushNotificationActionIdentifierKey;
extern NSString * _Nonnull const kMPPushNotificationBehaviorKey;
extern NSString * _Nonnull const kMPPushNotificationActionTileKey;
extern NSString * _Nonnull const kMPPushNotificationCategoryIdentifierKey;

// Assorted Keys
extern NSString * _Nonnull const kMPSessionLengthKey;                 
extern NSString * _Nonnull const kMPSessionTotalLengthKey;
extern NSString * _Nonnull const kMPOptOutStatus;
extern NSString * _Nonnull const kMPAlwaysTryToCollectIDFA;
extern NSString * _Nonnull const kMPCrashingSeverity;
extern NSString * _Nonnull const kMPCrashingClass;
extern NSString * _Nonnull const kMPCrashWasHandled;
extern NSString * _Nonnull const kMPErrorMessage;                     
extern NSString * _Nonnull const kMPStackTrace;                       
extern NSString * _Nonnull const kMPCrashSignal;
extern NSString * _Nonnull const kMPTopmostContext;
extern NSString * _Nonnull const kMPPLCrashReport;
extern NSString * _Nonnull const kMPCrashExceptionKey;
extern NSString * _Nonnull const kMPNullUserAttributeString;
extern NSString * _Nonnull const kMPSessionTimeoutKey;
extern NSString * _Nonnull const kMPUploadIntervalKey;
extern NSString * _Nonnull const kMPPreviousSessionLengthKey;
extern NSString * _Nonnull const kMPLifeTimeValueKey;
extern NSString * _Nonnull const kMPIncreasedLifeTimeValueKey;
extern NSString * _Nonnull const kMPPreviousSessionStateFileName;
extern NSString * _Nonnull const kMPHTTPMethodPost;
extern NSString * _Nonnull const kMPHTTPMethodGet;
extern NSString * _Nonnull const kMPPreviousSessionIdKey;
extern NSString * _Nonnull const kMPEventCounterKey;
extern NSString * _Nonnull const kMPProfileChangeTypeKey;
extern NSString * _Nonnull const kMPProfileChangeCurrentKey;
extern NSString * _Nonnull const kMPProfileChangePreviousKey;
extern NSString * _Nonnull const kMPPresentedViewControllerKey;
extern NSString * _Nonnull const kMPMainThreadKey;
extern NSString * _Nonnull const kMPPreviousSessionStartKey;
extern NSString * _Nonnull const kMPAppFirstSeenInstallationKey;
extern NSString * _Nonnull const kMPInfluencedOpenTimerKey;
extern NSString * _Nonnull const kMPResponseURLKey;
extern NSString * _Nonnull const kMPResponseMethodKey;
extern NSString * _Nonnull const kMPResponsePOSTDataKey;
extern NSString * _Nonnull const kMPHTTPHeadersKey;
extern NSString * _Nonnull const kMPHTTPAcceptEncodingKey;
extern NSString * _Nonnull const kMPDeviceTokenTypeKey;
extern NSString * _Nonnull const kMPDeviceTokenTypeDevelopment;
extern NSString * _Nonnull const kMPDeviceTokenTypeProduction;
extern NSString * _Nonnull const kMPHTTPETagHeaderKey;
extern NSString * _Nonnull const kMPAppSearchAdsAttributionKey;
extern NSString * _Nonnull const kMPSynchedUserAttributesKey;
extern NSString * _Nonnull const kMPSynchedUserIdentitiesKey;

// Remote configuration
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeKey;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeForce;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeIgnore;
extern NSString * _Nonnull const kMPRemoteConfigNetworkPerformanceModeKey;
extern NSString * _Nonnull const kMPRemoteConfigAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigForceTrue;
extern NSString * _Nonnull const kMPRemoteConfigForceFalse;
extern NSString * _Nonnull const kMPRemoteConfigKitsKey;
extern NSString * _Nonnull const kMPRemoteConfigConsumerInfoKey;
extern NSString * _Nonnull const kMPRemoteConfigCookiesKey;
extern NSString * _Nonnull const kMPRemoteConfigMPIDKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleIdKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModulePreferencesKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleLocationKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModulePreferenceSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleReadKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleDataTypeKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleWriteKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleDefaultKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigSandboxModeKey;
extern NSString * _Nonnull const kMPRemoteConfigSessionTimeoutKey;
extern NSString * _Nonnull const kMPRemoteConfigUploadIntervalKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationDictionaryKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationModeKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationTypeKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationModeKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationAccuracyKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationMinimumDistanceKey;
extern NSString * _Nonnull const kMPRemoteConfigLatestSDKVersionKey;
extern NSString * _Nonnull const kMPRemoteConfigRampKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerEventsKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerMessageTypesKey;
extern NSString * _Nonnull const kMPRemoteConfigInfluencedOpenTimerKey;
extern NSString * _Nonnull const kMPRemoteConfigUniqueIdentifierKey;
extern NSString * _Nonnull const kMPRemoteConfigBracketKey;
extern NSString * _Nonnull const kMPRemoteConfigRestrictIDFA;
extern NSString * _Nonnull const kMPRemoteConfigIncludeSessionHistory;

// Notifications
extern NSString * _Nonnull const kMPCrashReportOccurredNotification;
extern NSString * _Nonnull const kMPConfigureExceptionHandlingNotification;
extern NSString * _Nonnull const kMPRemoteNotificationOpenKey;
extern NSString * _Nonnull const kMPLogRemoteNotificationKey;
extern NSString * _Nonnull const kMPEventCounterLimitReachedNotification;
extern NSString * _Nonnull const kMPRemoteNotificationReceivedNotification;
extern NSString * _Nonnull const kMPUserNotificationDictionaryKey;
extern NSString * _Nonnull const kMPUserNotificationActionKey;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenNotification;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenKey;
extern NSString * _Nonnull const kMPRemoteNotificationOldDeviceTokenKey;
extern NSString * _Nonnull const kMPLocalNotificationReceivedNotification;
extern NSString * _Nonnull const kMPUserNotificationRunningModeKey;

// Config.plist keys
extern NSString * _Nonnull const kMPConfigPlist;
extern NSString * _Nonnull const kMPConfigApiKey;
extern NSString * _Nonnull const kMPConfigSecret;
extern NSString * _Nonnull const kMPConfigSessionTimeout;
extern NSString * _Nonnull const kMPConfigUploadInterval;
extern NSString * _Nonnull const kMPConfigEnableSSL;
extern NSString * _Nonnull const kMPConfigEnableCrashReporting;
extern NSString * _Nonnull const kMPConfigLocationTracking;
extern NSString * _Nonnull const kMPConfigLocationAccuracy;
extern NSString * _Nonnull const kMPConfigLocationDistanceFilter;
extern NSString * _Nonnull const kMPConfigRegisterForSilentNotifications;

// Data connection path/status
extern NSString * _Nonnull const kDataConnectionOffline;
extern NSString * _Nonnull const kDataConnectionMobile;
extern NSString * _Nonnull const kDataConnectionWifi;

// Application State Transition
extern NSString * _Nonnull const kMPASTInitKey;
extern NSString * _Nonnull const kMPASTExitKey;
extern NSString * _Nonnull const kMPASTBackgroundKey;
extern NSString * _Nonnull const kMPASTForegroundKey;
extern NSString * _Nonnull const kMPASTIsFirstRunKey;
extern NSString * _Nonnull const kMPASTIsUpgradeKey;
extern NSString * _Nonnull const kMPASTPreviousSessionSuccessfullyClosedKey;

// Network performance
extern NSString * _Nonnull const kMPNetworkPerformanceMeasurementNotification;
extern NSString * _Nonnull const kMPNetworkPerformanceKey;

// Kits
extern NSString * _Nonnull const MPKitAttributeJailbrokenKey;
extern NSString * _Nonnull const MPIntegrationAttributesKey;

// mParticle Javascript SDK paths
extern NSString * _Nonnull const kMParticleWebViewSdkScheme;
extern NSString * _Nonnull const kMParticleWebViewPathLogEvent;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserIdentity;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathSetSessionAttribute;

//
// Primitive data type constants
//
extern const NSTimeInterval MINIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval MAXIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval DEFAULT_SESSION_TIMEOUT;
extern const NSTimeInterval TWENTY_FOUR_HOURS; // Database clean up interval
extern const NSTimeInterval ONE_HUNDRED_EIGHTY_DAYS;

// Interval between uploads if not specified
extern const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL;
extern const NSTimeInterval DEFAULT_UPLOAD_INTERVAL;

// Delay before processing uploads to allow app to get started
extern const NSTimeInterval INITIAL_UPLOAD_TIME;

extern const NSUInteger EVENT_LIMIT; // maximum number of events per session

// Attributes limits
extern const NSInteger LIMIT_ATTR_COUNT;
extern const NSInteger LIMIT_ATTR_LENGTH;
extern const NSInteger LIMIT_NAME;
extern const NSInteger LIMIT_USER_ATTR_LENGTH;
extern const NSInteger MAX_USER_ATTR_LIST_SIZE;
extern const NSInteger MAX_USER_ATTR_LIST_ENTRY_LENGTH;

#endif
