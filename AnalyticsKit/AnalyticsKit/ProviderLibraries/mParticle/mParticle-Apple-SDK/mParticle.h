//
//  mParticle.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MPUserSegments.h"
#import "MPEvent.h"
#import "MPEnums.h"
#import "MPCart.h"
#import "MPCommerce.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"
#import "MPBags.h"
#import "MPExtensionProtocol.h"
#import "MPKitRegister.h"
#import "MPKitExecStatus.h"
#import "MPIHasher.h"
#import "MPTransactionAttributes.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPProduct+Dictionary.h"
#import "MPDateFormatter.h"
#import "NSDictionary+MPCaseInsensitive.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 This is the main class of the mParticle SDK. It interfaces your app with the mParticle API
 so you can report and measure the many different metrics of your app.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let mParticle = MParticle.sharedInstance()
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MParticle *mParticle = [MParticle sharedInstance];
 </code></pre>
 */
@interface MParticle : NSObject

#pragma mark Properties
/**
 This property is an instance of MPBag, which used to describe a product bag to hold the state of products in the hands of a user. Please note a difference
 when compared with a shopping cart. A product bag is intendend to represent product samples shipped for trial by a user, which
 later may return the samples or add one or more to a shopping cart with the intent of purchasing them.
 
 Bags, and products added to them are persisted throughout the lifetime of the application. It is up to you to remove products from
 a bag, and remove bags according to their respective life-cycles in your app.
 
 You should not try to create independent instance of this class, instead you should use this property to perform all product bags operations.
 
 @see MPBags
 */
@property (nonatomic, strong, readonly) MPBags *bags;

/**
 This property is an instance of MPCommerce. It is used to execute transactional operations on the shopping cart.
 @see MPCommerce
 @see MPCart
 */
@property (nonatomic, strong, readonly) MPCommerce *commerce;

/**
 Forwards setting/resetting the debug mode for third party kits.
 This is a write only property.
 */
@property (nonatomic, unsafe_unretained) BOOL debugMode;
- (BOOL)debugMode UNAVAILABLE_ATTRIBUTE;

/**
 Enables or disables log outputs to the console. If set to YES development logs will be output to the
 console, if set to NO the development logs will be suppressed. This property works in conjunction with
 the environment property. If the environment is Production, consoleLogging will always be NO,
 regardless of the value you assign to it.
 @see environment
 @see logLevel
 */
@property (nonatomic, unsafe_unretained) BOOL consoleLogging;

/**
 The environment property returns the running SDK environment: Development or Production.
 @see MPEnvironment
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
@property (nonatomic, unsafe_unretained, readonly) MPEnvironment environment;

/**
 Specifies the log level output to the console while the app is under development: none, error, warning, and debug.
 If consoleLogging is set to false, the log level will be set to none automatically. When the environment is
 Production, the log level will always be none, regardless of the value you assign to it.
 @see environment
 */
@property (nonatomic, unsafe_unretained) MPILogLevel logLevel;

/**
 Flag indicating whether network performance is being measured.
 @see beginMeasuringNetworkPerformance
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL measuringNetworkPerformance;

/**
 Gets/Sets the opt-in/opt-out status for the application. Set it to YES to opt-out of event tracking. Set it to NO to opt-in of event tracking.
 The default value is NO (opt-in of event tracking)
 */
@property (nonatomic, unsafe_unretained, readwrite) BOOL optOut;

/**
 A flag indicating whether the mParticle Apple SDK has proxied the App Delegate and is handling
 application notifications automatically.
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL proxiedAppDelegate;

#if TARGET_OS_IOS == 1
/**
 Gets/Sets the push notification token for the application.
 @see registerForPushNotificationWithTypes:
 */
@property (nonatomic, strong, nullable) NSData *pushNotificationToken;
#endif

/**
 Gets/Sets the user session timeout interval. A session is ended if the app goes into the background for longer than the session timeout interval or
 when more than 1000 events are logged.
 */
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval sessionTimeout;

/**
 Unique identifier for this app running on this device. This unique identifier is synchronized with the mParticle servers.
 @retuns A string containing the unique identifier or nil, if communication with the server could not yet be established.
 */
@property (nonatomic, strong, readonly, nullable) NSString *uniqueIdentifier;

/**
 Gets/Sets the interval to upload data to mParticle servers.
 
 Batches of data are sent periodically to the mParticle servers at the rate defined by the uploadInterval. Batches are also uploaded
 when the application is sent to the background or before they are terminated.
 */
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval uploadInterval;

/**
 Gets all user attributes.
 @returns A dictionary containing the collection of user attributes.
 */
@property (nonatomic, strong, nullable, readonly) NSDictionary<NSString *, id> *userAttributes;

/**
 mParticle Apple SDK version
 */
@property (nonatomic, strong, readonly) NSString *version;

#pragma mark - Initialization

/**
 Returns the shared instance object.
 @returns the Singleton instance of the MParticle class.
 */
+ (instancetype)sharedInstance;

/**
 Starts the API with the api_key and api_secret saved in MParticleConfig.plist.  If you
 use startAPI instead of startAPIWithKey:secret: your API key and secret must
 be added to these parameters in the MParticleConfig.plist.
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
- (void)start;

/**
 Starts the API with your API key and a secret.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret;

/**
 Starts the API with your API key and a secret and installation type.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @param installationType You can tell the mParticle SDK if this is a new install, an upgrade, or let the SDK detect it automatically.
 @param environment The environment property defining the running SDK environment: Development or Production. You can set it to a specific value, or let the
        SDK auto-detect the environment for you. Once the app is deployed to the App Store, setting this parameter will have no effect, since the SDK will set
        the environment to production.
 @see MPInstallationType
 @see MPEnvironment
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment;

/**
 Starts the API with your API key and a secret and installation type.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @param installationType You can tell the mParticle SDK if this is a new install, an upgrade, or let the SDK detect it automatically.
 @param environment The environment property defining the running SDK environment: Development or Production. You can set it to a specific value, or let the
        SDK auto-detect the environment for you. Once the app is deployed to the App Store, setting this parameter will have no effect, since the SDK will set
        the environment to production.
 @param proxyAppDelegate Flag indicating whether the mParticle SDK should handle logging remote notifications, app launches, and actions automatically. If you set to NO, 
        your app is resposible to calling required methods. Default is YES
 @see MPInstallationType
 @see MPEnvironment
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment proxyAppDelegate:(BOOL)proxyAppDelegate;

#pragma mark - Application notifications
#if TARGET_OS_IOS == 1
/**
 Informs the mParticle SDK a local notification has been received. This method should be called only if proxiedAppDelegate is disabled.
 @param notification A local notification received by the app
 @see proxiedAppDelegate
 */
- (void)didReceiveLocalNotification:(UILocalNotification *)notification;

/**
 Informs the mParticle SDK a remote notification has been received. This method should be called only if proxiedAppDelegate is disabled.
 @param userInfo A dictionary containing information related to the remote notification
 @see proxiedAppDelegate
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 Informs the mParticle SDK the push notification service could not complete the registration process. This method should be called only if proxiedAppDelegate is disabled.
 @param error An NSError object encapsulating the information why registration did not succeed
 @see proxiedAppDelegate
 */
- (void)didFailToRegisterForRemoteNotificationsWithError:(nullable NSError *)error;

/**
 Informs the mParticle SDK the app successfully registered with the push notification service. This method should be called only if proxiedAppDelegate is disabled.
 @param deviceToken A token that identifies the device+App to APNS
 @see proxiedAppDelegate
 */
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a local notification.
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param notification The local notification object that was triggered
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(nullable UILocalNotification *)notification;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a remote notification.
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param userInfo A dictionary that contains information related to the remote notification
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo;
#endif

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled.
 @param url The URL resource to open
 @param sourceApplication The bundle ID of the requesting app
 @param annotation A property list object supplied by the source app
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled. This method is only available for iOS 9 and above.
 @param url The URL resource to open
 @param options The dictionary of launch options
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;

/**
 Informs the mParticle SDK the app has been asked to open to continue an NSUserActivity.
 This method should be called only if proxiedAppDelegate is disabled. This method is only available for iOS 9 and above.
 @param userActivity The NSUserActivity that caused the app to be opened
 @param restorationHandler A block to execute if your app creates objects to perform the task.
 @see proxiedAppDelegate
 */
- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler;

#pragma mark - Basic Tracking
/**
 Contains a collection with all active timed events (timed events that had begun, but not yet ended). You should not keep a 
 separate reference collection containing the events being timed. The mParticle SDK manages the lifecycle of those events.
 @see beginTimedEvent:
 @returns A set with all active timed events
 */
- (nullable NSSet *)activeTimedEvents;

/**
 Begins timing an event. There can be many timed events going on at the same time, the only requirement is that each
 concurrent timed event must have a unique event name. After beginning a timed event you don't have to keep a reference
 to the event instance being timed, you can use the eventWithName: method to retrive it later when ending the timed event.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)beginTimedEvent:(MPEvent *)event;

/**
 Ends timing an event and logs its data to the mParticle SDK. If you didn't keep a reference to the event
 being timed, you can use the eventWithName: method to retrive it.
 @param event An instance of MPEvent
 @see beginTimedEvent:
 */
- (void)endTimedEvent:(MPEvent *)event;

/**
 When working with timed events you don't need to keep a reference to the event being timed. You can use this method
 to retrive the event being timed passing the event name as parameter. If an instance of MPEvent, with a matching
 event name cannot be found, this method will return nil.
 @param eventName A string with the event name associated with the event being timed
 @returns An instance of MPEvent, if one could be found, or nil.
 @see endTimedEvent:
 */
- (nullable MPEvent *)eventWithName:(NSString *)eventName;

/**
 Logs an event. This is one of the most fundamental method of the SDK. Developers define all the characteristics
 of an event (name, type, attributes, etc) in an instance of MPEvent and pass that instance to this method to
 log its data to the mParticle SDK.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)logEvent:(MPEvent *)event;

/**
 Logs an event. This is a convenience method for logging simple events; internally it creates an instance of MPEvent
 and calls logEvent:
 @param eventName The name of the event to be logged (required not nil.) The string cannot be longer than 255 characters
 @param eventType An enum value that indicates the type of event to be logged
 @param eventInfo A dictionary containing further information about the event. This dictionary is limited to 100 key
                  value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 255 characters), 
                  numbers, booleans, or dates
 @see logEvent:
 */
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs a screen event. Developers define all the characteristics of a screen event (name, attributes, etc) in an
 instance of MPEvent and pass that instance to this method to log its data to the mParticle SDK.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)logScreenEvent:(MPEvent *)event;

/**
 Logs a screen event. This is a convenience method for logging simple screen events; internally it creates an instance
 of MPEvent and calls logScreenEvent:
 @param screenName The name of the screen to be logged (required not nil and up to 255 characters)
 @param eventInfo A dictionary containing further information about the screen. This dictionary is limited to 100 key
 value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 255 characters), numbers,
 booleans, or dates
 @see logScreenEvent:
 */
- (void)logScreen:(NSString *)screenName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

#pragma mark - Deep linking
/**
 Checks for deferred deep link information.
 @param completionHandler A block to be called when deep link checking is finished.
 */
- (void)checkForDeferredDeepLinkWithCompletionHandler:(void(^)(NSDictionary<NSString *, NSString *> * _Nullable linkInfo, NSError * _Nullable error))completionHandler;

#pragma mark - Error, Exception, and Crash Handling
/**
 Enables mParticle exception handling to automatically log events on uncaught exceptions.
 */
- (void)beginUncaughtExceptionLogging;

/**
 Disables mParticle automatic exception handling.
 */
- (void)endUncaughtExceptionLogging;

/**
 Leaves a breadcrumb. Breadcrumbs are send together with crash reports to help with debugging.
 @param breadcrumbName The name of the breadcrumb (required not nil)
 */
- (void)leaveBreadcrumb:(NSString *)breadcrumbName;

/**
 Leaves a breadcrumb. Breadcrumbs are send together with crash reports to help with debugging.
 @param breadcrumbName The name of the breadcrumb (required not nil)
 @param eventInfo A dictionary containing further information about the breadcrumb
 */
- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs an error with a message.
 @param message The name of the error to be tracked (required not nil)
 @see logError:eventInfo:
 */
- (void)logError:(NSString *)message;

/**
 Logs an error with a message and an attributes dictionary. The eventInfo is limited to
 100 key value pairs. The strings in eventInfo cannot contain more than 255 characters.
 @param message The name of the error event (required not nil)
 @param eventInfo A dictionary containing further information about the error
 */
- (void)logError:(NSString *)message eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs an exception.
 @param exception The exception which occured
 @see logException:topmostContext:
 */
- (void)logException:(NSException *)exception;

/**
 Logs an exception and a context.
 @param exception The exception which occured
 @param topmostContext The topmost context of the app, typically the topmost view controller
 */
- (void)logException:(NSException *)exception topmostContext:(nullable id)topmostContext;

#pragma mark - eCommerce Transactions
/**
 Logs a commerce event.
 @param commerceEvent An instance of MPCommerceEvent
 @see MPCommerceEvent
 */
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent;

/**
 Increases the LTV (LifeTime Value) amount of a user.
 @param increaseAmount The amount to be added to LTV
 @param eventName The name of the event (Optional). If not applicable, pass nil
 */
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName;

/**
 Increases the LTV (LifeTime Value) amount of a user.
 @param increaseAmount The amount to be added to LTV
 @param eventName The name of the event (Optional). If not applicable, pass nil
 @param eventInfo A dictionary containing further information about the LTV
 */
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

#pragma mark - Extensions
/**
 Registers an extension against the code mParticle SDK. Extensions are external code, unknown to the core SDK, which
 conform to one of more known protocols. They allow the core SDK to function in ways beyond its core functionality.
 @param extension An instance of a class conforming to a MPExtensionProtocol specialization
 @see MPExtensionProtocol
 */
+ (BOOL)registerExtension:(id<MPExtensionProtocol>)extension;

#pragma mark - Kits
/**
 Retrieves the internal instance of a kit, so it can be used to invoke methods and properties of that kit directly.
 
 This method is only applicable to kits that allocate themselves as an object instance or a singleton. For the cases
 where kits are implemented with class methods, you can call those class methods directly
 @param kitCode A NSNumber representing the kit to be retrieved
 @returns The internal instance of the kit, or nil, if the kit is not active
 */
- (nullable id const)kitInstance:(NSNumber *)kitCode;

/**
 Returns whether a kit is active or not. You can retrieve if a kit has been already initialized and
 can be used.
 @param kitCode A NSNumber representing the kit to be checked
 @returns Whether the kit is active or not.
 */
- (BOOL)isKitActive:(NSNumber *)kitCode;

#pragma mark - Location
#if TARGET_OS_IOS == 1
/**
 Enables or disables the inclusion of location information to messages when your app is running on the
 background. The default value is YES. Setting it to NO will cause the SDK to include location
 information only when your app is running on the foreground.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic, unsafe_unretained) BOOL backgroundLocationTracking;

/**
 Gets/Sets the current location of the active session.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic, strong) CLLocation *location;

/**
 Begins geographic location tracking.
 
 The desired accuracy of the location is determined by a passed in constant for accuracy.
 Choices are kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyBest,
 kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyHundredMeters,
 kCLLocationAccuracyKilometer, and kCLLocationAccuracyThreeKilometers.
 @param accuracy The desired accuracy
 @param distanceFilter The minimum distance (measured in meters) a device must move before an update event is generated.
 */
- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;

/**
 Begins geographic location tracking.
 
 The desired accuracy of the location is determined by a passed in constant for accuracy.
 Choices are kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyBest,
 kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyHundredMeters,
 kCLLocationAccuracyKilometer, and kCLLocationAccuracyThreeKilometers.
 @param accuracy The desired accuracy
 @param distanceFilter The minimum distance (measured in meters) a device must move before an update event is generated.
 @param authorizationRequest Type of authorization requested to use location services
 */
- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;

/**
 Ends geographic location tracking.
 */
- (void)endLocationTracking;
#endif

#pragma mark - Network Performance
/**
 Begins measuring and reporting network performance.
 */
- (void)beginMeasuringNetworkPerformance;

/**
 Ends measuring and reporting network performance.
 */
- (void)endMeasuringNetworkPerformance;

/**
 Excludes a URL from network performance measurement. You can call this method multiple times, passing a URL at a time.
 @param url A URL to be removed from measurements
 */
- (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url;

/**
 Allows you to log a network performance measurement independently from the mParticle SDK measurement. 
 @param urlString The absolute URL being measured
 @param httpMethod The method used in the network communication (e.g. GET, POST, etc)
 @param startTime The time when the network communication started measured in seconds since Unix Epoch Time: [[NSDate date] timeIntervalSince1970]
 @param duration The number of seconds it took for the network communication took to complete
 @param bytesSent The number of bytes sent
 @param bytesReceived The number of bytes received
 */
- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived;

/**
 By default mParticle SDK will remove the query part of all URLs. Use this method to add an exception to the default
 behavior and include the query compoment of any URL containing queryString. You can call this method multiple times, passing a query string at a time.
 @param queryString A string with the query component to be included and reported in network performance measurement.
 */
- (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString;

/**
 Resets all network performance measurement filters and URL exclusions.
 */
- (void)resetNetworkPerformanceExclusionsAndFilters;

#pragma mark - Session management
/**
 Increments the value of a session attribute by the provided amount. If the key does not
 exist among the current session attributes, this method will add the key to the session attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort and the returned value will be nil.
 @param key The attribute key
 @param value The increment amount
 @returns The new value amount or nil, in case of failure
 */
- (nullable NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Set a single session attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to existing session attributes. Passing in a nil value for an
 existing key will remove the session attribute.
 @param key The attribute key
 @param value The attribute value
 */
- (void)setSessionAttribute:(NSString *)key value:(id)value;

/**
 Force uploads queued messages to mParticle.
 */
- (void)upload;

#pragma mark - Surveys
/**
 Returns the survey URL for a given provider.
 @param surveyProvider The survey provider
 @returns A string with the URL to the survey
 @see MPSurveyProvider
 */
- (nullable NSString *)surveyURL:(MPSurveyProvider)surveyProvider;

#pragma mark - User Identity
/**
 Increments the value of a user attribute by the provided amount. If the key does not
 exist among the current user attributes, this method will add the key to the user attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort and the returned value will be nil.
 @param key The attribute key
 @param value The increment amount
 @returns The new value amount or nil, in case of failure
 */
- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Logs a user out.
 */
- (void)logout;

/**
 Sets a single user attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes. Passing in an empty string value (@"") for an
 existing key will remove the user attribute.
 @param key The user attribute key
 @param value The user attribute value
 */
- (void)setUserAttribute:(NSString *)key value:(nullable id)value;

/**
 Sets a list of user attributes associated with a key.
 Passing nil to values for an existing key will remove the user attribute.
 @param key The user attribute list key
 @param values An array of user attributes
 */
- (void)setUserAttribute:(NSString *)key values:(nullable NSArray<NSString *> *)values;

/**
 Sets User/Customer Identity
 @param identityString A string representing the user identity
 @param identityType The user identity type
 */
- (void)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;

/**
 Sets a single user tag or attribute.  The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes.
 @param tag The user tag/attribute
 */
- (void)setUserTag:(NSString *)tag;

/**
 Removes a single user attribute.
 @param key The user attribute key
 */
- (void)removeUserAttribute:(NSString *)key;

#pragma mark - User Segments
/**
 Retrieves user segments from mParticle's servers and returns the result as an array of MPUserSegments objects.
 If the method takes longer than timeout seconds to return, the local cached segments will be returned instead,
 and the newly retrieved segments will update the local cache once the results arrive.
 @param timeout The maximum number of seconds to wait for a response from mParticle's servers. This value can be fractional, like 0.1 (100 milliseconds)
 @param endpointId The endpoint id
 @param completionHandler A block to be called when the results are available. The user segments array is passed to this block
 @returns An array of MPUserSegments objects in the completion handler
 */
- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler;

#pragma mark - Web Views
#if TARGET_OS_IOS == 1
/**
 Updates isIOS flag to true in JS API via given webview.
 @param webView The web view to be initialized
 */
- (void)initializeWebView:(UIWebView *)webView;

/**
 Verifies if the url is mParticle sdk url i.e mp-sdk://
 @param requestUrl The request URL
 */
- (BOOL)isMParticleWebViewSdkUrl:(NSURL *)requestUrl;

/**
 Process log event from hybrid apps that are using iOS UIWebView control.
 @param requestUrl The request URL
 */
- (void)processWebViewLogEvent:(NSURL *)requestUrl;
#endif

@end

NS_ASSUME_NONNULL_END
