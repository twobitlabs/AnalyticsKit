//
//  MPEnums.h
//
//  Copyright 2014-2015. mParticle, Inc. All Rights Reserved.
//

#ifndef mParticle_MPEnums_h
#define mParticle_MPEnums_h

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

/// Supported Social Networks
typedef NS_OPTIONS(uint64_t, MPSocialNetworks) {
    /** Social Network Facebook */
    MPSocialNetworksFacebook = 1 << 1,
    /** Social Network Twitter */
    MPSocialNetworksTwitter = 1 << 2
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
    /** User identity Goolge */
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

/// Reachable Embedded Kit Instances
typedef NS_ENUM(NSUInteger, MPEmbeddedSDKInstance) {
    MPEmbeddedSDKInstanceAppboy = 28,
    MPEmbeddedSDKInstanceKochava = 37,
    MPEmbeddedSDKInstanceKahuna = 56,
    MPEmbeddedSDKInstanceComScore = 39,
    MPEmbeddedSDKInstanceForesee = 64,
    MPEmbeddedSDKInstanceAdjust = 68,
    MPEmbeddedSDKInstanceBranchMetrics = 80
};

/// Log Levels
typedef NS_ENUM(NSUInteger, MPLogLevel) {
    MPLogLevelNone = 0,
    MPLogLevelError,
    MPLogLevelWarning,
    MPLogLevelDebug
};

/** Posted immediately after a new session has began.
 
 @discussion You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
 access the respective session id by using the mParticleSessionId constant.
 */
extern NSString *const mParticleSessionDidBeginNotification;

/** Posted right before the current session ends.
 
 @discussion You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
 access the respective session id by using the mParticleSessionId constant.
 */
extern NSString *const mParticleSessionDidEndNotification;

/** This constant is used as key for the userInfo dictionary in the
 mParticleSessionDidBeginNotification and mParticleSessionDidEndNotification notifications. The value
 of this key is the id of the session.
 */
extern NSString *const mParticleSessionId;

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
extern NSString *const mParticleUserAttributeMobileNumber;
extern NSString *const mParticleUserAttributeGender;
extern NSString *const mParticleUserAttributeAge;
extern NSString *const mParticleUserAttributeCountry;
extern NSString *const mParticleUserAttributeZip;
extern NSString *const mParticleUserAttributeCity;
extern NSString *const mParticleUserAttributeState;
extern NSString *const mParticleUserAttributeAddress;
extern NSString *const mParticleUserAttributeFirstName;
extern NSString *const mParticleUserAttributeLastName;

/** Posted immediately after an embedded SDK becomes available to be used.
 
 @discussion If your app is calling an embedded SDK methods directly, you can register to receive this notification
 when an embedded SDK becomes available for use. The notification contains a userInfo dictionary where you can extract 
 the associated embedded SDK instance with the mParticleEmbeddedSDKInstanceKey constant.
 @see MPEmbeddedSDKInstance
 @see mParticleEmbeddedSDKInstanceKey
 */
extern NSString *const mParticleEmbeddedSDKDidBecomeActiveNotification;

/** Posted immediately after an embedded SDK becomes unavailable to be used.
 
 @discussion If your app is calling an embedded SDK methods directly, you can register to receive this notification
 when an embedded SDK becomes unavailable for use. You may receive this notification if an embedded SDK gets disabled
 in the mParticle Services Hub. The notification contains a userInfo dictionary where you can extract
 the associated embedded SDK instance with the mParticleEmbeddedSDKInstanceKey constant.
 @see MPEmbeddedSDKInstance
 @see mParticleEmbeddedSDKInstanceKey
 */
extern NSString *const mParticleEmbeddedSDKDidBecomeInactiveNotification;

/**
 Constant used to extract the respective embedded SDK instance number from userInfo dictionary in an
 embedded SDK notification.
 @see mParticleEmbeddedSDKDidBecomeActiveNotification
 @see mParticleEmbeddedSDKDidBecomeInactiveNotification
 */
extern NSString *const mParticleEmbeddedSDKInstanceKey;

#endif
