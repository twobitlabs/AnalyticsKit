//
//  KahunaAnalytics.h
//  KahunaSDK
//
//  Copyright (c) 2012-2015 Kahuna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>

static NSString* const KAHUNA_CREDENTIAL_USERNAME = @"username";
static NSString* const KAHUNA_CREDENTIAL_EMAIL = @"email";
static NSString* const KAHUNA_CREDENTIAL_FACEBOOK = @"fbid";
static NSString* const KAHUNA_CREDENTIAL_TWITTER = @"twtr";
static NSString* const KAHUNA_CREDENTIAL_LINKEDIN = @"lnk";
static NSString* const KAHUNA_CREDENTIAL_USER_ID = @"user_id";
static NSString* const KAHUNA_CREDENTIAL_GOOGLE_PLUS = @"gplus_id";
static NSString* const KAHUNA_CREDENTIAL_INSTALL_TOKEN = @"install_token";

typedef enum {
    KAHRegionMonitoring     = 1 << 0,    // This monitors for regions (circular) defined to find if a user enters or exits a region.
    KAHAll                  = 0xFFFF,    // This turns on all types of location monitoring supported by the SDK
} KAHLocationMonitoringFeatures __attribute__((deprecated("use ENUM 'KAHLocationServicesFeatures' instead")));

typedef enum {
    KAHRegionMonitoringServices     = 1 << 0    // This monitors for regions (circular) to find if a user enters or exits a region.
} KAHLocationServicesFeatures;

// Delegate for all Kahuna callbacks.
@protocol KahunaDelegate <NSObject>
@optional
- (void) kahunaPushReceived: (NSString *) message withDictionary: (NSDictionary *) extras __attribute__((deprecated("use method 'kahunaPushMessageReceived:withDictionary:withApplicationState:' instead")));
- (void) kahunaPushMessageReceived: (NSString *) message withDictionary: (NSDictionary *) extras __attribute__((deprecated("use method 'kahunaPushMessageReceived:withDictionary:withApplicationState:' instead")));
- (void) kahunaPushMessageReceived: (NSString *) message withDictionary: (NSDictionary *) extras withApplicationState:(UIApplicationState) applicationState;
- (void) kahunaInAppMessageReceived: (NSString *) message withDictionary: (NSDictionary *) extras;
@end

@interface KahunaAnalytics : NSObject <NSURLConnectionDelegate>

@property (weak) id <KahunaDelegate> delegate; // Kahuna delegate.

// Setting the badge Number will set the application badge. To clear set to 0.
@property (assign) NSInteger badgeNumber;

+ (id) sharedAnalytics;

//Launch Kahuna with Key
+ (void) launchWithKey: (NSString *) kahunaSecretKey;

//Start Kahuna with Key
+ (void) startWithKey: (NSString *) kahunaSecretKey __attribute__((deprecated("Use 'launchWithKey' API instead. 'launchWithKey' should be called inside application:didFinishLaunchingWithOptions:")));

//Launch Kahuna with Key and UserName and Email
+ (void) launchWithKey: (NSString *) kahunaSecretkey
          andUsername: (NSString *) username
             andEmail: (NSString *) email;

//Start Kahuna with Key and UserName and Email
+ (void) startWithKey: (NSString *) kahunaSecretkey
          andUsername: (NSString *) username
             andEmail: (NSString *) email __attribute__((deprecated("Use 'launchWithKey:andUsername:andEmail' API instead. This API should be called inside application:didFinishLaunchingWithOptions:")));

//Launch Kahuna with Key and Credentials
+ (void) launchWithKey: (NSString *) kahunaSecretkey
       andCredentials: (NSDictionary *)userCredentials;

//Start Kahuna with Key and Credentials
+ (void) startWithKey: (NSString *) kahunaSecretkey
       andCredentials: (NSDictionary *)userCredentials __attribute__((deprecated("Use 'launchWithKey:andCredentials:' API instead. This API should be called inside application:didFinishLaunchingWithOptions:")));

//Track Event
+ (void) trackEvent: (NSString *) eventString;

//Track Event with Count and Value (This is used for eCommerce transactions)
+ (void) trackEvent: (NSString *) eventString
          withCount: (long) count
           andValue: (long) value;

//Add User Credentials
+ (void) setUserCredentialsWithKey: (NSString *) key
                          andValue: (NSObject *) value;

//Set User Attributes
+ (void) setUserAttributes: (NSDictionary *) userAttributes;

//Get all User Credentials if any have been saved
+ (NSDictionary *) getUserCredentials;

//Get User Attributes if any have been saved
+ (NSDictionary *) getUserAttributes;

//Log the current user out, clears all user credentials and attributes
+ (void) logout;

//Set Device Token for Push
+ (void) setDeviceToken: (NSData *) deviceToken;

//Notify the SDK if remote push registration fails
+ (void) handleNotificationRegistrationFailure: (NSError *) error;

//Pass any remote notifications to Kahuna (only if doing push)
+ (void) handleNotification: (NSDictionary *) userInfo
       withApplicationState: (UIApplicationState) appState;

//Pass any remote notifications to Kahuna with the action identifier. (Actionable Push notifications are new in iOS 8.0)
+ (void) handleNotification: (NSDictionary *) userInfo
       withActionIdentifier: (NSString*) actionIdentifier
       withApplicationState: (UIApplicationState) appState;

//To see more detailed logging in console log, set to YES before calling start.
+ (void) setDebugMode : (Boolean) setting;

//Get the Kahuna specific device identifier for this device.
+ (NSString *) getKahunaDeviceId;

/*
 * setDeepIntegrationMode allows the host application to deeply integrate with Kahuna SDK. This allows Kahuna to capture
 * vital information for building effective campaigns.
 */
+ (void) setDeepIntegrationMode : (Boolean) setting;

/*
 * This method will enable location monitoring which includes Region monitoring, Lat/Lng updates and iBeacon monotoring.
 * Call this method when the host app wants to ask the user for location monitoring. The method will prompt the user to give permissions
 * and show the reason the app is asking for location permissions. The permissions are asked only once. To ask the user for permissions again use
 * the method "clearLocationMonitoringUserPermissions".
 * IMPORTANT : In iOS 8 the purpose needs to be defined using a key 'NSLocationAlwaysUsageDescription' in the application plist. You can send in a NIL for iOS 8.
 */
+ (void) enableLocationMonitoring:(KAHLocationMonitoringFeatures)features withReason:(NSString*) reason __attribute__((deprecated("use method 'enableLocationServices:withReason:' instead")));
+ (void) enableLocationServices:(KAHLocationServicesFeatures)features withReason:(NSString*) reason;
/* 
 * This method clears the user permissions settings stored by kahuna. By clearing the settings the host app indicates to the KahunaSDK
 * that it can ask for permissions again when "enableLocationMonitoring" is called. Since prompting the user for location permissions is controlled by the OS, clearing the
 * user permissions might still not prompt the user for location permissions, it will only clear kahuna's internal settings. But eventually the user will be prompted for
 * permissions.
 */
+ (void) clearLocationMonitoringUserPermissions __attribute__((deprecated("use method 'clearLocationServicesUserPermissions' instead")));
+ (void) clearLocationServicesUserPermissions;

/*
 * This method will disable any of the location monitoring services turned on. Since Kahuna moitors geo-fences and iBeacons in the background, one should not call
 * disbleLocationMonitoring as this will turn off the feature completely. A typical usage of this API would be to show a user settings view, where the user can 
 * switch ON and OFF the feature they want / don't want.
 */
+ (void) disbleLocationServices:(KAHLocationServicesFeatures)features __attribute__((deprecated("use method 'disableLocationServices' instead")));

+ (void) disableLocationServices:(KAHLocationServicesFeatures)features;


@end
