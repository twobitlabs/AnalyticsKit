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
    MPEventTypeLocation = 2,
    /** Use for search related events */
    MPEventTypeSearch = 3,
    /** Use for transaction related events */
    MPEventTypeTransaction = 4,
    /** Use for user content related events */
    MPEventTypeUserContent = 5,
    /** Use for user preference related events */
    MPEventTypeUserPreference = 6,
    /** Use for social related events */
    MPEventTypeSocial = 7,
    /** Use for other types of events not contained in this enum */
    MPEventTypeOther = 8,
    /** 9 used to be MPEventTypeMedia. It has been discontinued */
    /** Internal. Used when a product is added to the cart */
    MPEventTypeAddToCart = 10,
    /** Internal. Used when a product is removed from the cart */
    MPEventTypeRemoveFromCart = 11,
    /** Internal. Used when the cart goes to checkout */
    MPEventTypeCheckout = 12,
    /** Internal. Used when the cart goes to checkout with options */
    MPEventTypeCheckoutOption = 13,
    /** Internal. Used when a product is clicked */
    MPEventTypeClick = 14,
    /** Internal. Used when user views the details of a product */
    MPEventTypeViewDetail = 15,
    /** Internal. Used when a product is purchased */
    MPEventTypePurchase = 16,
    /** Internal. Used when a product refunded */
    MPEventTypeRefund = 17,
    /** Internal. Used when a promotion is displayed */
    MPEventTypePromotionView = 18,
    /** Internal. Used when a promotion is clicked */
    MPEventTypePromotionClick = 19,
    /** Internal. Used when a product is added to the wishlist */
    MPEventTypeAddToWishlist = 20,
    /** Internal. Used when a product is removed from the wishlist */
    MPEventTypeRemoveFromWishlist = 21,
    /** Internal. Used when a product is displayed in a promotion */
    MPEventTypeImpression = 22
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
    /** User identity customer id. This is an id issued by your own system */
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
    MPUserIdentityFacebookCustomAudienceId,
    /** User identity other 2 */
    MPUserIdentityOther2,
    /** User identity other 3 */
    MPUserIdentityOther3,
    /** User identity other 4 */
    MPUserIdentityOther4
};

/// Kit Instance Codes
typedef NS_ENUM(NSUInteger, MPKitInstance) {
    /** Kit code for Urban Airship */
    MPKitInstanceUrbanAirship = 25,
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
    /** Kit code for Nielsen */
    MPKitInstanceNielsen = 63,
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
    /** Kit code for Carnival */
    MPKitInstanceCarnival = 99,
    /** Kit code for Primer */
    MPKitInstancePrimer = 100,
    /** Kit code for Apptimize */
    MPKitInstanceApptimize = 105,
    /** Kit code for Reveal Mobile */
    MPKitInstanceRevealMobile = 112,
    /** Kit code for Radar */
    MPKitInstanceRadar = 117,
    /** Kit code for Skyhook */
    MPKitInstanceSkyhook = 121,
    /** Kit code for Iterable */
    MPKitInstanceIterable = 1003,
    /** Kit code for Button */
    MPKitInstanceButton = 1022,
    /** Kit code for Singular */
    MPKitInstanceSingular = 119,
    /** Kit code for Adobe */
    MPKitInstanceAdobe = 124,
    /** Kit code for Instabot */
    MPKitInstanceInstabot = 123
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
    /** Message type code for when an app successfully registers to receive push notifications */
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
    MPMessageTypeCommerceEvent = 16,
    /** Message type code for a user attribute change */
    MPMessageTypeUserAttributeChange = 17,
    /** Message type code for a user identity change */
    MPMessageTypeUserIdentityChange = 18
};

typedef NS_ENUM(NSUInteger, MPConnectivityErrorCode) {
    /** Client side error: Unknown error. */
    MPConnectivityErrorCodeUnknown = 0,
    /** The device is not online. Please make sure you've initialized the mParticle SDK and that your device has an active network connection. */
    MPConnectivityErrorCodeNoConnection = 1,
    /** Client side error: SSL connection failed to be established due to invalid server certificate. mParticle performs SSL pinning - you cannot use a proxy to read traffic. */
    MPConnectivityErrorCodeSSLCertificate = 2,
};

typedef NS_ENUM(NSUInteger, MPIdentityErrorResponseCode) {
    /** Client side error: Unknown error. */
    MPIdentityErrorResponseCodeUnknown = 0,
    /** Client side error: There is a current Identity API request in progress. Please wait until it has completed and retry your request. */
    MPIdentityErrorResponseCodeRequestInProgress = 1,
    /** Client side error: Request timed-out while attempting to call the server. Request should be retried when device connectivity has been reestablished. */
    MPIdentityErrorResponseCodeClientSideTimeout = 2,
    /** Client side error: Device has no network connection. Request should be retried when device connectivity has been reestablished. */
    MPIdentityErrorResponseCodeClientNoConnection = 3,
    /** Client side error: SSL connection failed to be established due to invalid server certificate. mParticle performs SSL pinning - you cannot use a proxy to read traffic. */
    MPIdentityErrorResponseCodeSSLError = 3,
    /** HTTP Error 401: Unauthorized. Ensure that you've initialized the mParticle SDK with a valid workspace key and secret. */
    MPIdentityErrorResponseCodeUnauthorized = 401,
    /** HTTP Error 504: Identity request should be retried */
    MPIdentityErrorResponseCodeTimeout = 504,
    /** HTTP Error 429: Identity request should be retried */
    MPIdentityErrorResponseCodeRetry = 429
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

/** Posted immediately after the SDK becomes initialized.
 
 @discussion You can register to receive this notification using NSNotificationCenter. This notification is broadcast when the mParticle SDK successfully
 finishes its initialization.
 */
extern NSString * _Nonnull const mParticleDidFinishInitializing;

/**
 Set of constants that can be used to specify certain attributes of a user. 
 
 @discussion There are many 3rd party services that support,
 for example, specifying a gender of a user. The mParticle platform will look for these constants within the user attributes that
 you have set for a given user, and forward any attributes to the services that support them.
 mParticleUserAttributeMobileNumber Setting the mobile number as user attribute
 mParticleUserAttributeGender Setting the gender as user attribute
 mParticleUserAttributeAge Setting the age as user attribute
 mParticleUserAttributeCountry Setting the country as user attribute
 mParticleUserAttributeZip Setting the postal code (zip) as user attribute
 mParticleUserAttributeCity Setting the city as user attribute
 mParticleUserAttributeState Setting the state as user attribute
 mParticleUserAttributeAddress Setting the address as user attribute
 mParticleUserAttributeFirstName Setting the first name as user attribute
 mParticleUserAttributeLastName Setting the last name as user attribute
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

extern NSString * _Nonnull const mParticleIdentityStateChangeListenerNotification;
extern NSString * _Nonnull const mParticleUserKey;
extern NSString * _Nonnull const mParticleIdentityErrorDomain;
extern NSString * _Nonnull const mParticleIdentityErrorKey;

/**
 Constant used to express gender.
 */
extern NSString * _Nonnull const mParticleGenderMale;
extern NSString * _Nonnull const mParticleGenderFemale;
extern NSString * _Nonnull const mParticleGenderNotAvailable;

/**
 Kit API error domain and key
 */
extern NSString * _Nonnull const MPKitAPIErrorDomain;
extern NSString * _Nonnull const MPKitAPIErrorKey;

#endif
