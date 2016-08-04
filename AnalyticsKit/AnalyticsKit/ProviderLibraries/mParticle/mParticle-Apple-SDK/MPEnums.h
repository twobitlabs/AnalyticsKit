//
//  MPEnums.h
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

#ifndef mParticle_MPEnums_h
#define mParticle_MPEnums_h

#import <Foundation/Foundation.h>

/// Running Environment
typedef NS_ENUM(NSUInteger, MPEnvironment) {
    /** Tells the SDK to auto detect the current run environment (initial value) */
    MPEnvironmentAutoDetect = 0,
    /** The SDK is running in development mode (Debug/Development or AdHoc) */
    MPEnvironmentDevelopment,
    /** The SDK is running in production mode (App Store) */
    MPEnvironmentProduction
};

/// Event Types
typedef NS_ENUM(NSUInteger, MPEventType) {
    /** Use for navigation related events */
    MPEventTypeNavigation = 1,
    /** Use for location related events */
    MPEventTypeLocation,
    /** Use for search related events */
    MPEventTypeSearch,
    /** Use for transaction related events */
    MPEventTypeTransaction,
    /** Use for user content related events */
    MPEventTypeUserContent,
    /** Use for user preference related events */
    MPEventTypeUserPreference,
    /** Use for social related events */
    MPEventTypeSocial,
    /** Use for other types of events not contained in this enum */
    MPEventTypeOther,
    /** Use for media related events */
    MPEventTypeMedia,
    /** Internal. Used when a product is added to the cart */
    MPEventTypeAddToCart,
    /** Internal. Used when a product is removed from the cart */
    MPEventTypeRemoveFromCart,
    /** Internal. Used when the cart goes to checkout */
    MPEventTypeCheckout,
    /** Internal. Used when the cart goes to checkout with options */
    MPEventTypeCheckoutOption,
    /** Internal. Used when a product is clicked */
    MPEventTypeClick,
    /** Internal. Used when user views the details of a product */
    MPEventTypeViewDetail,
    /** Internal. Used when a product is purchased */
    MPEventTypePurchase,
    /** Internal. Used when a product refunded */
    MPEventTypeRefund,
    /** Internal. Used when a promotion is displayed */
    MPEventTypePromotionView,
    /** Internal. Used when a is clicked */
    MPEventTypePromotionClick,
    /** Internal. Used when a product is added to the wishlist */
    MPEventTypeAddToWishlist,
    /** Internal. Used when a product is removed from the wishlist */
    MPEventTypeRemoveFromWishlist,
    /** Internal. Used when a product is displayed in a promotion */
    MPEventTypeImpression
};

/// Installation Types
typedef NS_ENUM(NSInteger, MPInstallationType) {
    /** mParticle auto-detects the installation type. This is the default value */
    MPInstallationTypeAutodetect = 0,
    /** Informs mParticle this binary is a new installation */
    MPInstallationTypeKnownInstall,
    /** Informs mParticle this binary is an upgrade */
    MPInstallationTypeKnownUpgrade,
    /** Informs mParticle this binary is the same version. This value is for internal use only. It should not be used by developers */
    MPInstallationTypeKnownSameVersion
};

/// Location Tracking Authorization Request
typedef NS_ENUM(NSUInteger, MPLocationAuthorizationRequest) {
    /** Requests authorization to always use location services */
    MPLocationAuthorizationRequestAlways = 0,
    /** Requests authorization to use location services when the app is in use */
    MPLocationAuthorizationRequestWhenInUse
};

/// eCommerce Product Events
typedef NS_ENUM(NSInteger, MPProductEvent) {
    /** To be used when a product is viewed by a user */
    MPProductEventView = 0,
    /** To be used when a user adds a product to a wishlist */
    MPProductEventAddedToWishList,
    /** To be used when a user removes a product from a wishlist */
    MPProductEventRemovedFromWishList,
    /** To be used when a user adds a product to a cart */
    MPProductEventAddedToCart,
    /** To be used when a user removes a product from a cart */
    MPProductEventRemovedFromCart
};

/// Survey Providers
typedef NS_ENUM(NSUInteger, MPSurveyProvider) {
    MPSurveyProviderForesee = 64
};

/// User Identities
typedef NS_ENUM(NSUInteger, MPUserIdentity) {
    /** User identity other */
    MPUserIdentityOther = 0,
    /** User identity customer id. This is an id issue by your own system */
    MPUserIdentityCustomerId,
    /** User identity Facebook */
    MPUserIdentityFacebook,
    /** User identity Twitter */
    MPUserIdentityTwitter,
    /** User identity Google */
    MPUserIdentityGoogle,
    /** User identity Microsoft */
    MPUserIdentityMicrosoft,
    /** User identity Yahoo! */
    MPUserIdentityYahoo,
    /** User identity Email */
    MPUserIdentityEmail,
    /** User identity Alias */
    MPUserIdentityAlias,
    /** User identity Facebook Custom Audience Third Party Id, or User App Id */
    MPUserIdentityFacebookCustomAudienceId
};

/// Kit Instance Codes
typedef NS_ENUM(NSUInteger, MPKitInstance) {
    /** Kit code for Appboy */
    MPKitInstanceAppboy = 28,
    /** Kit code for Tune */
    MPKitInstanceTune = 32,
    /** Kit code for Kochava */
    MPKitInstanceKochava = 37,
    /** Kit code for comScore */
    MPKitInstanceComScore = 39,
    /** Kit code for Kahuna */
    MPKitInstanceKahuna = 56,
    /** Kit code for Foresee */
    MPKitInstanceForesee = 64,
    /** Kit code for Adjust */
    MPKitInstanceAdjust = 68,
    /** Kit code for Branch Metrics */
    MPKitInstanceBranchMetrics = 80,
    /** Kit code for Flurry */
    MPKitInstanceFlurry = 83,
    /** Kit code for Localytics */
    MPKitInstanceLocalytics = 84,
    /** Kit code for Apteligent (formerly known as Crittercism) */
    MPKitInstanceApteligent = 86,
    /** Kit code for Crittercism (now Apteligent) */
    MPKitInstanceCrittercism = 86,
    /** Kit code for Wootric */
    MPKitInstanceWootric = 90,
    /** Kit code for AppsFlyer */
    MPKitInstanceAppsFlyer = 92,
    /** Kit code for Apptentive */
    MPKitInstanceApptentive = 97,
    /** Kit code for Leanplum */
    MPKitInstanceLeanplum = 98,
    /** Kit code for Button */
    MPKitInstanceButton = 1022
};

/// Log Levels
typedef NS_ENUM(NSUInteger, MPILogLevel) {
    /** No log messages are displayed on the console  */
    MPILogLevelNone = 0,
    /** Only error log messages are displayed on the console */
    MPILogLevelError,
    /** Warning and error log messages are displayed on the console */
    MPILogLevelWarning,
    /** Debug, warning, and error log messages are displayed on the console */
    MPILogLevelDebug,
    /** Verbose, debug, warning, and error log messages are displayed on the console */
    MPILogLevelVerbose
};

/// Message Types
typedef NS_ENUM(NSUInteger, MPMessageType) {
    /** Message type unknown - RESERVED, DO NOT USE */
    MPMessageTypeUnknown = 0,
    /** Message type code for a session start */
    MPMessageTypeSessionStart = 1,
    /** Message type code for a session end */
    MPMessageTypeSessionEnd = 2,
    /** Message type code for a screen view */
    MPMessageTypeScreenView = 3,
    /** Message type code for an event */
    MPMessageTypeEvent = 4,
    /** Message type code for a crash report */
    MPMessageTypeCrashReport = 5,
    /** Message type code for opt out */
    MPMessageTypeOptOut = 6,
    /** Message type code for the first time the app is run */
    MPMessageTypeFirstRun = 7,
    /** Message type code for attributions */
    MPMessageTypePreAttribution = 8,
    /** Message type code for when an app successfuly registers to receive push notifications */
    MPMessageTypePushRegistration = 9,
    /** Message type code for when an app transitions to/from background */
    MPMessageTypeAppStateTransition = 10,
    /** Message type code for when an app receives a push notification */
    MPMessageTypePushNotification = 11,
    /** Message type code for logging a network performance measurement */
    MPMessageTypeNetworkPerformance = 12,
    /** Message type code for leaving a breadcrumb */
    MPMessageTypeBreadcrumb = 13,
    /** Message type code for profile - RESERVED, DO NOT USE */
    MPMessageTypeProfile = 14,
    /** Message type code for when a user interacts with a received push notification */
    MPMessageTypePushNotificationInteraction = 15,
    /** Message type code for a commerce event */
    MPMessageTypeCommerceEvent = 16
};

/** Posted immediately after a new session has begun.
 
 @discussion You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
 access the respective session id by using the mParticleSessionId constant.
 */
extern NSString * _Nonnull const mParticleSessionDidBeginNotification;

/** Posted right before the current session ends.
 
 @discussion You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
 access the respective session id by using the mParticleSessionId constant.
 */
extern NSString * _Nonnull const mParticleSessionDidEndNotification;

/** This constant is used as key for the userInfo dictionary in the
 mParticleSessionDidBeginNotification and mParticleSessionDidEndNotification notifications. The value
 of this key is the id of the session.
 */
extern NSString * _Nonnull const mParticleSessionId;

/**
 Set of constants that can be used to specify certain attributes of a user. 
 
 @discussion There are many 3rd party services that support,
 for example, specifying a gender of a user. The mParticle platform will look for these constants within the user attributes that
 you have set for a given user, and forward any attributes to the services that support them.
 @param mParticleUserAttributeMobileNumber Setting the mobile number as user attribute
 @param mParticleUserAttributeGender Setting the gender as user attribute
 @param mParticleUserAttributeAge Setting the age as user attribute
 @param mParticleUserAttributeCountry Setting the country as user attribute
 @param mParticleUserAttributeZip Setting the postal code (zip) as user attribute
 @param mParticleUserAttributeCity Setting the city as user attribute
 @param mParticleUserAttributeState Setting the state as user attribute
 @param mParticleUserAttributeAddress Setting the address as user attribute
 @param mParticleUserAttributeFirstName Setting the first name as user attribute
 @param mParticleUserAttributeLastName Setting the last name as user attribute
 @see setUserAttribute:value:
 */
extern NSString * _Nonnull const mParticleUserAttributeMobileNumber;
extern NSString * _Nonnull const mParticleUserAttributeGender;
extern NSString * _Nonnull const mParticleUserAttributeAge;
extern NSString * _Nonnull const mParticleUserAttributeCountry;
extern NSString * _Nonnull const mParticleUserAttributeZip;
extern NSString * _Nonnull const mParticleUserAttributeCity;
extern NSString * _Nonnull const mParticleUserAttributeState;
extern NSString * _Nonnull const mParticleUserAttributeAddress;
extern NSString * _Nonnull const mParticleUserAttributeFirstName;
extern NSString * _Nonnull const mParticleUserAttributeLastName;

/** Posted immediately after a kit becomes available to be used.
 
 @discussion If your app is calling a kit methods directly, you can register to receive this notification
 when a kit becomes available for use. The notification contains a userInfo dictionary where you can extract
 the associated kit instance with the mParticleKitInstanceKey constant.
 @see MPKitInstance
 @see mParticleKitInstanceKey
 */
extern NSString * _Nonnull const mParticleKitDidBecomeActiveNotification;
extern NSString * _Nonnull const mParticleEmbeddedSDKDidBecomeActiveNotification;

/** Posted immediately after a kit becomes unavailable to be used.
 
 @discussion If your app is calling kit methods directly, you can register to receive this notification
 when a kit becomes unavailable for use. You may receive this notification if a kit gets disabled
 in the mParticle Services Hub. The notification contains a userInfo dictionary where you can extract
 the associated kit instance with the mParticleKitInstanceKey constant.
 @see MPKitInstance
 @see mParticleKitInstanceKey
 */
extern NSString * _Nonnull const mParticleKitDidBecomeInactiveNotification;
extern NSString * _Nonnull const mParticleEmbeddedSDKDidBecomeInactiveNotification;

/**
 Constant used to extract the respective kit instance number from userInfo dictionary in a
 kit notification.
 @see mParticleKitDidBecomeActiveNotification
 @see mParticleKitDidBecomeInactiveNotification
 */
extern NSString * _Nonnull const mParticleKitInstanceKey;
extern NSString * _Nonnull const mParticleEmbeddedSDKInstanceKey;

/**
 Constant used to express gender.
 */
extern NSString * _Nonnull const mParticleGenderMale;
extern NSString * _Nonnull const mParticleGenderFemale;
extern NSString * _Nonnull const mParticleGenderNotAvailable;

#endif
