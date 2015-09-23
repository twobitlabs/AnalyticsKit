//
//  Localytics.h
//  Copyright (C) 2014 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define LOCALYTICS_LIBRARY_VERSION      @"3.5.0"

typedef NS_ENUM(NSUInteger, LLInAppMessageDismissButtonLocation){
    LLInAppMessageDismissButtonLocationLeft,
    LLInAppMessageDismissButtonLocationRight
};

typedef NS_ENUM(NSInteger, LLProfileScope){
    LLProfileScopeApplication,
    LLProfileScopeOrganization
};

@protocol LLMessagingDelegate;
@protocol LLAnalyticsDelegate;

/** 
 @discussion The class which manages creating, collecting, & uploading a Localytics session.
 Please see the following guides for information on how to best use this
 library, sample code, and other useful information:
 <ul>
 <li><a href="http://wiki.localytics.com/index.php?title=Developer's_Integration_Guide">
 Main Developer's Integration Guide</a></li>
 </ul>
 
 <strong>Best Practices</strong>
 <ul>
 <li>Integrate Localytics in <code>applicationDidFinishLaunching</code>.</li>
 <li>Open your session and begin your uploads in <code>applicationDidBecomeActive</code>. This way the
 upload has time to complete and it all happens before your users have a
 chance to begin any data intensive actions of their own.</li>
 <li>Close the session in <code>applicationWillResignActive</code>.</li>
 <li>Do not call any Localytics functions inside a loop.  Instead, calls
 such as <code>tagEvent</code> should follow user actions.  This limits the
 amount of data which is stored and uploaded.</li>
 <li>Do not instantiate a Localtyics object, instead use only the exposed class methods.</li>
 </ul>
 */

@interface Localytics : NSObject

#pragma mark - SDK Integration
/** ---------------------------------------------------------------------------------------
 * @name Localytics SDK Integration
 *  ---------------------------------------------------------------------------------------
 */

/** Auto-integrates the Localytic SDK into the application.

 Use this method to automatically integrate the Localytics SDK in a single line of code. Automatic
 integration is accomplished by proxing the AppDelegate and "inserting" a Localytics AppDelegate
 behind the applications AppDelegate. The proxy will first call the applications AppDelegate and
 then call the Localytics AppDelegate.
 
 @param appKey The unique key for each application generated at www.localytics.com
 @param launchOptions The launchOptions provided by application:DidFinishLaunchingWithOptions:
 */
+ (void)autoIntegrate:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions;

/** Manually integrate the Localytic SDK into the application.
 
 Use this method to manually integrate the Localytics SDK. The developer still has to make sure to
 open and close the Localytics session as well as call upload to ensure data is uploaded to 
 Localytics
 
 @param appKey The unique key for each application generated at www.localytics.com
 @see openSession
 @see closeSession
 @see upload
 */
+ (void)integrate:(NSString *)appKey;

/** Opens the Localytics session.
 The session time as presented on the website is the time between <code>open</code> and the
 final <code>close</code> so it is recommended to open the session as early as possible, and close
 it at the last moment. It is recommended that this call be placed in <code>applicationDidBecomeActive</code>.
 <br>
 If for any reason this is called more than once every subsequent open call will be ignored.

 Resumes the Localytics session.  When the App enters the background, the session is
 closed and the time of closing is recorded.  When the app returns to the foreground, the session
 is resumed.  If the time since closing is greater than BACKGROUND_SESSION_TIMEOUT, (15 seconds
 by default) a new session is created, and uploading is triggered.  Otherwise, the previous session
 is reopened.
 */
+ (void)openSession;

/** Closes the Localytics session.  This should be called in
 <code>applicationWillResignActive</code>.
 <br>
 If close is not called, the session will still be uploaded but no
 events will be processed and the session time will not appear. This is
 because the session is not yet closed so it should not be used in
 comparison with sessions which are closed.
 */
+ (void)closeSession;

/** Creates a low priority thread which uploads any Localytics data already stored
 on the device.  This should be done early in the process life in order to
 guarantee as much time as possible for slow connections to complete.  It is also reasonable
 to upload again when the application is exiting because if the upload is cancelled the data
 will just get uploaded the next time the app comes up.
 */
+ (void)upload;

#pragma mark - Event Tagging
/** ---------------------------------------------------------------------------------------
 * @name Event Tagging
 *  ---------------------------------------------------------------------------------------
 */

/** Tag an event
 @param eventName The name of the event which occurred.
 @see tagEvent:attributes:customerValueIncrease:
 */
+ (void)tagEvent:(NSString *)eventName;

/** Tag an event with attributes
 @param eventName The name of the event which occurred.
 @param attributes An object/hash/dictionary of key-value pairs, contains
 contextual data specific to the event.
 @see tagEvent:attributes:customerValueIncrease:
 */
+ (void)tagEvent:(NSString *)eventName attributes:(NSDictionary *)attributes;

/** Allows a session to tag a particular event as having occurred.  For
 example, if a view has three buttons, it might make sense to tag
 each button click with the name of the button which was clicked.
 For another example, in a game with many levels it might be valuable
 to create a new tag every time the user gets to a new level in order
 to determine how far the average user is progressing in the game.
 <br>
 <strong>Tagging Best Practices</strong>
 <ul>
 <li>DO NOT use tags to record personally identifiable information.</li>
 <li>The best way to use tags is to create all the tag strings as predefined
 constants and only use those.  This is more efficient and removes the risk of
 collecting personal information.</li>
 <li>Do not set tags inside loops or any other place which gets called
 frequently.  This can cause a lot of data to be stored and uploaded.</li>
 </ul>
 <br>
 See the tagging guide at: http://wiki.localytics.com/
 @param eventName The name of the event which occurred.
 @param attributes (Optional) An object/hash/dictionary of key-value pairs, contains
 contextual data specific to the event.
 @param customerValueIncrease (Optional) Numeric value, added to customer lifetime value.
 Integer expected. Try to use lowest possible unit, such as cents for US currency.
 */
+ (void)tagEvent:(NSString *)eventName attributes:(NSDictionary *)attributes customerValueIncrease:(NSNumber *)customerValueIncrease;

#pragma mark - Tag Screen Method

/** Allows tagging the flow of screens encountered during the session.
 @param screenName The name of the screen
 */

+ (void)tagScreen:(NSString *)screenName;

#pragma mark - Custom Dimensions
/** ---------------------------------------------------------------------------------------
 * @name Custom Dimensions
 *  ---------------------------------------------------------------------------------------
 */

/** Sets the value of a custom dimension. Custom dimensions are dimensions
 which contain user defined data unlike the predefined dimensions such as carrier, model, and country.
 Once a value for a custom dimension is set, the device it was set on will continue to upload that value
 until the value is changed. To clear a value pass nil as the value.
 The proper use of custom dimensions involves defining a dimension with less than ten distinct possible
 values and assigning it to one of the four available custom dimensions. Once assigned this definition should
 never be changed without changing the App Key otherwise old installs of the application will pollute new data.
 @param value The value to set the custom dimension to
 @param dimension The dimension to set the value of
 @see valueForCustomDimension:
 */
+ (void)setValue:(NSString *)value forCustomDimension:(NSUInteger)dimension;

/** Gets the custom value for a given dimension. Avoid calling this on the main thread, as it
 may take some time for all pending database execution.
 @param dimension The custom dimension to return a value for
 @return The current value for the given custom dimension
 @see setValue:forCustomDimension:
 */
+ (NSString *)valueForCustomDimension:(NSUInteger)dimension;

#pragma mark - Identifiers
/** ---------------------------------------------------------------------------------------
 * @name Identifiers
 *  ---------------------------------------------------------------------------------------
 */

/** Sets the value of a custom identifier. Identifiers are a form of key/value storage
 which contain custom user data. Identifiers might include things like email addresses,
 customer IDs, twitter handles, and facebook IDs. Once a value is set, the device it was set 
 on will continue to upload that value until the value is changed.
 To delete a property, pass in nil as the value.
 @param value The value to set the identifier to. To delete a propert set the value to nil
 @param identifier The name of the identifier to have it's value set
 @see valueForIdentifier:
 */
+ (void)setValue:(NSString *)value forIdentifier:(NSString *)identifier;

/** Gets the identifier value for a given identifier. Avoid calling this on the main thread, as it
 may take some time for all pending database execution.
 @param identifier The identifier to return a value for
 @return The current value for the given identifier
 @see setValue:forCustomDimension:
 */
+ (NSString *)valueForIdentifier:(NSString *)identifier;

/** This is an identifier helper method. This method acts the same as calling
    [Localytics setValue:userId forIdentifier:@"customer_id"]
 @param customerId The user id to set the 'customer_id' identifier to
 */
+ (void)setCustomerId:(NSString *)customerId;

/** Gets the customer id. Avoid calling this on the main thread, as it
 may take some time for all pending database execution.
 @return The current value for customer id
 */
+ (NSString *)customerId;

/** Stores the user's location.  This will be used in all event and session calls.
 If your application has already collected the user's location, it may be passed to Localytics
 via this function.  This will cause all events and the session close to include the location
 information.  It is not required that you call this function.
 @param location The user's location.
 */
+ (void)setLocation:(CLLocationCoordinate2D)location;

#pragma mark - Profile
/** ---------------------------------------------------------------------------------------
 * @name Profile
 *  ---------------------------------------------------------------------------------------
 */

/** Sets the value of a profile attribute.
 @param value The value to set the profile attribute to. value can be one of the following: NSString,
 NSNumber(long & int), NSDate, NSArray of Strings, NSArray of NSNumbers(long & int), NSArray of Date,
 nil. Passing in a 'nil' value will result in that attribute being deleted from the profile
 @param attribute The name of the profile attribute to be set
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)setValue:(NSObject<NSCopying> *)value forProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Sets the value of a profile attribute (scope: Application).
 @param value The value to set the profile attribute to. value can be one of the following: NSString,
 NSNumber(long & int), NSDate, NSArray of Strings, NSArray of NSNumbers(long & int), NSArray of Date,
 nil. Passing in a 'nil' value will result in that attribute being deleted from the profile
 @param attribute The name of the profile attribute to be set
 */
+ (void)setValue:(NSObject<NSCopying> *)value forProfileAttribute:(NSString *)attribute;

/** Adds values to a profile attribute that is a set
 @param values The value to be added to the profile attributes set
 @param attribute The name of the profile attribute to have it's set modified
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)addValues:(NSArray *)values toSetForProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Adds values to a profile attribute that is a set (scope: Application).
 @param values The value to be added to the profile attributes set
 @param attribute The name of the profile attribute to have it's set modified
 */
+ (void)addValues:(NSArray *)values toSetForProfileAttribute:(NSString *)attribute;

/** Removes values from a profile attribute that is a set
 @param values The value to be removed from the profile attributes set
 @param attribute The name of the profile attribute to have it's set modified
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)removeValues:(NSArray *)values fromSetForProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Removes values from a profile attribute that is a set (scope: Application).
 @param values The value to be removed from the profile attributes set
 @param attribute The name of the profile attribute to have it's set modified
 */
+ (void)removeValues:(NSArray *)values fromSetForProfileAttribute:(NSString *)attribute;

/** Increment the value of a profile attribute.
 @param value An NSInteger to be added to an existing profile attribute value.
 @param attribute The name of the profile attribute to have it's value incremented
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)incrementValueBy:(NSInteger)value forProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Increment the value of a profile attribute (scope: Application).
 @param value An NSInteger to be added to an existing profile attribute value.
 @param attribute The name of the profile attribute to have it's value incremented
 */
+ (void)incrementValueBy:(NSInteger)value forProfileAttribute:(NSString *)attribute;

/** Decrement the value of a profile attribute.
 @param value An NSInteger to be subtracted from an existing profile attribute value.
 @param attribute The name of the profile attribute to have it's value decremented
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)decrementValueBy:(NSInteger)value forProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Decrement the value of a profile attribute (scope: Application).
 @param value An NSInteger to be subtracted from an existing profile attribute value.
 @param attribute The name of the profile attribute to have it's value decremented
 */
+ (void)decrementValueBy:(NSInteger)value forProfileAttribute:(NSString *)attribute;

/** Delete a profile attribute
 @param attribute The name of the attribute to be deleted
 @param scope The scope of the attribute governs the visability of the profile attribute (application
 only or organization wide)
 */
+ (void)deleteProfileAttribute:(NSString *)attribute withScope:(LLProfileScope)scope;

/** Delete a profile attribute (scope: Application)
 @param attribute The name of the attribute to be deleted
 */
+ (void)deleteProfileAttribute:(NSString *)attribute;

/** Convenience method to set a customer's email as both a profile attribute and
 as a customer identifier (scope: Organization)
 @param email Customer's email
 */
+ (void)setCustomerEmail:(NSString *)email;

/** Convenience method to set a customer's first name as both a profile attribute and
 as a customer identifier (scope: Organization)
 @param firstName Customer's first name
 */
+ (void)setCustomerFirstName:(NSString *)firstName;

/** Convenience method to set a customer's last name as both a profile attribute and
 as a customer identifier (scope: Organization)
 @param lastName Customer's last name
 */
+ (void)setCustomerLastName:(NSString *)lastName;

/** Convenience method to set a customer's full name as both a profile attribute and
 as a customer identifier (scope: Organization)
 @param fullName Customer's full name
 */
+ (void)setCustomerFullName:(NSString *)fullName;

#pragma mark - Push
/** ---------------------------------------------------------------------------------------
 * @name Push
 *  ---------------------------------------------------------------------------------------
 */

/** Returns the device's APNS token if one has been set via setPushToken: previously.
 @return The device's APNS token if one has been set otherwise nil
 @see setPushToken:
 */
+ (NSString *)pushToken;

/** Stores the device's APNS token. This will be used in all event and session calls.
 @param pushToken The devices APNS token returned by application:didRegisterForRemoteNotificationsWithDeviceToken:
 @see pushToken
 */
+ (void)setPushToken:(NSData *)pushToken;

/** Used to record performance data for push notifications
 @param notificationInfo The dictionary from either didFinishLaunchingWithOptions or
 didReceiveRemoteNotification should be passed on to this method
 */
+ (void)handlePushNotificationOpened:(NSDictionary *)notificationInfo;

#pragma mark - In-App Message
/** ---------------------------------------------------------------------------------------
 * @name In-App Message
 *  ---------------------------------------------------------------------------------------
 */

/**
 @param url The URL to be handled
 @return YES if the URL was successfully handled or NO if the attempt to handle the
 URL failed.
 */
+ (BOOL)handleTestModeURL:(NSURL *)url;

/** Set the image to be used for dimissing an In-App message
 @param image The image to be used for dismissing an In-App message. By default this is a
 circle with an 'X' in the middle of it
 */
+ (void)setInAppMessageDismissButtonImage:(UIImage *)image;

/** Set the image to be used for dimissing an In-App message by providing the name of the
 image to be loaded and used
 @param imageName The name of an image to be loaded and used for dismissing an In-App
 message. By default the image is a circle with an 'X' in the middle of it
 */
+ (void)setInAppMessageDismissButtonImageWithName:(NSString *)imageName;

/** Set the location of the dismiss button on an In-App msg
 @param location The location of the button (left or right)
 @see InAppDismissButtonLocation
 */
+ (void)setInAppMessageDismissButtonLocation:(LLInAppMessageDismissButtonLocation)location;

/** Returns the location of the dismiss button on an In-App msg
 @return InAppDismissButtonLocation
 @see InAppDismissButtonLocation
 */
+ (LLInAppMessageDismissButtonLocation)inAppMessageDismissButtonLocation;

+ (void)triggerInAppMessage:(NSString *)triggerName;
+ (void)triggerInAppMessage:(NSString *)triggerName withAttributes:(NSDictionary *)attributes;

+ (void)dismissCurrentInAppMessage;

#pragma mark - Developer Options
/** ---------------------------------------------------------------------------------------
 * @name Developer Options
 *  ---------------------------------------------------------------------------------------
 */

/** Returns whether the Localytics SDK is set to emit logging information
 @return YES if logging is enabled, NO otherwise
 */
+ (BOOL)isLoggingEnabled;

/** Set whether Localytics SDK should emit logging information. By default the Localytics SDK
 is set to not to emit logging information. It is recommended that you only enable logging
 for debugging purposes.
 @param loggingEnabled Set to YES to enable logging or NO to disable it
 */
+ (void)setLoggingEnabled:(BOOL)loggingEnabled;

/** Returns whether or not an IDFA is collected and sent to Localytics
 @return YES if an IDFA is collected, NO otherwise
 @see setCollectAdvertisingIdentifier
 */
+ (BOOL)isCollectingAdvertisingIdentifier;

/** Set whether or not an IDFA is collected and sent to Localytics
 @param collectAdvertisingIdentifier When set to YES an IDFA is collected. No prevents the IDFA
 from being collected. By default an IDFA is collected
 @see isCollectingAdvertisingIdentifier
 */
+ (void)setCollectAdvertisingIdentifier:(BOOL)collectAdvertisingIdentifier;

/** Returns whether or not the application will collect user data.
 @return YES if the user is opted out, NO otherwise. Default is NO
 @see setOptedOut:
 */
+ (BOOL)isOptedOut;

/** Allows the application to control whether or not it will collect user data.
 Even if this call is used, it is necessary to continue calling upload().  No new data will be
 collected, so nothing new will be uploaded but it is necessary to upload an event telling the
 server this user has opted out.
 @param optedOut YES if the user is opted out, NO otherwise.
 @see isOptedOut
 */
+ (void)setOptedOut:(BOOL)optedOut;

/** Returns whether the Localytics SDK is currently in test mode or not. When in test mode
 a small Localytics tab will appear on the left side of the screen which enables a developer
 to see/test all the campaigns currently available to this customer.
 @return YES if test mode is enabled, NO otherwise
 */
+ (BOOL)isTestModeEnabled;

/** Set whether Localytics SDK should enter test mode or not. When set to YES the a small
 Localytics tab will appear on the left side of the screen, enabling a developer to see/test
 all campaigns currently available to this customer.
 Setting testModeEnabled to NO will cause Localytics to exit test mode, if it's currently
 in it.
 @param enabled Set to YES to enable test mode, NO to disable test mode
 */
+ (void)setTestModeEnabled:(BOOL)enabled;

/** Returns the session time out interval. If a user backgrounds the app and then foregrounds
 the app before the session timeout interval expires then the session will be considered as
 resuming. If the user returns after the time out interval expires the old session willl be
 closed and a new session will be initiated.
 @return the session time out interval (defaults to 15 seconds)
 */
+ (NSTimeInterval)sessionTimeoutInterval;

/** Sets the session time out interval. If a user backgrounds the app and then foregrounds
 the app before the session time out interval expires then the session will be considered as
 resuming. If the user returns after the time out interval expires the old session willl be
 closed and a new session will be initiated.
 @param timeoutInterval The session time out interval
 */
+ (void)setSessionTimeoutInterval:(NSTimeInterval)timeoutInterval;

/** Returns the install id
 @return the install id as an NSString
 */
+ (NSString *)installId;

/** Returns the version of the Localytics SDK
 @return the version of the Localytics SDK as an NSString
 */
+ (NSString *)libraryVersion;

/** Returns the app key currently set in Localytics
 @return the app key currently set in Localytics as an NSString
 */
+ (NSString *)appKey;

/** Returns the analytics API hostname
 @return the analyics API hostname currently set in Localytics as an NSString
 */
+ (NSString *)analyticsHost;

/** Sets the analytics API hostname
 @param analyticsHost The hostname for analytics API requests
 */
+ (void)setAnalyticsHost:(NSString *)analyticsHost;

/** Returns the messaging API hostname
 @return the messaging API hostname currently set in Localytics as an NSString
 */
+ (NSString *)messagingHost;

/** Sets the messaging API hostname
 @param messagingHost The hostname for messaging API requests
 */
+ (void)setMessagingHost:(NSString *)messagingHost;

/** Returns the profiles API hostname
 @return the profiles API hostname currently set in Localytics as an NSString
 */
+ (NSString *)profilesHost;

/** Sets the profiles API hostname
 @param profilesHost The hostname for profiles API requests
 */
+ (void)setProfilesHost:(NSString *)profilesHost;

#pragma mark - In-App Message Delegate
/** ---------------------------------------------------------------------------------------
 * @name In-App Message Delegate
 *  ---------------------------------------------------------------------------------------
 */

/** Add a Messaging delegate
 @param delegate An object that implements the LLMessagingDelegate and is called
 when an In-App message will display, did display, will hide, and did hide. Multiple objects
 can be delegates, and each one will receive callbacks.
 @see LLMessagingDelegate
 */
+ (void)addMessagingDelegate:(id<LLMessagingDelegate>)delegate;

/** Remove a Messaging delegate
 @param delegate The delegate previously added that now being removed
 @see LLMessagingDelegate
 */
+ (void)removeMessagingDelegate:(id<LLMessagingDelegate>)delegate;

/** Returns whether the ADID parameter is added to In-App call to action URLs
 @return YES if parameter is added, NO otherwise
 */
+ (BOOL)isInAppAdIdParameterEnabled;

/** Set whether ADID parameter is added to In-App call to action URLs. By default
 the ADID parameter will be added to call to action URLs.
 @param enabled Set to YES to enable the ADID parameter or NO to disable it
 */
+ (void)setInAppAdIdParameterEnabled:(BOOL)enabled;

#pragma mark - Analytics Delegate
/** ---------------------------------------------------------------------------------------
 * @name Analytics Delegate
 *  ---------------------------------------------------------------------------------------
 */

/** Add an Analytics delegate
 @param delegate An object implementing the LLAnalyticsDelegate protocol. Multiple objects
 can be delegates, and each one will receive callbacks.
 @see LLAnalyticsDelegate
 */
+ (void)addAnalyticsDelegate:(id<LLAnalyticsDelegate>)delegate;

/** Remove an Analytics delegate
 @param delegate The delegate previously added that now being removed
 @see LLAnalyticsDelegate
 */
+ (void)removeAnalyticsDelegate:(id<LLAnalyticsDelegate>)delegate;

#pragma mark - WatchKit
/** ---------------------------------------------------------------------------------------
 * @name WatchKit
 *  ---------------------------------------------------------------------------------------
 */

/** Handle calls to the SDK from a WatchKit Extension app
 
 Call this in the UIApplicationDelegate's application:handleWatchKitExtensionRequest:reply: 
 method.
 
 @param userInfo the userInfo provided by application:handleWatchKitExtensionRequest:reply:
 @param reply The reply provided by application:handleWatchKitExtensionRequest:reply:
 @return YES if the Localytics SDK has handled replying to the WatchKit Extension; NO otherwise
 */
+ (BOOL)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *replyInfo))reply;

@end

@protocol LLAnalyticsDelegate <NSObject>
@optional

- (void)localyticsSessionWillOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume;
- (void)localyticsSessionDidOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume;

- (void)localyticsDidTagEvent:(NSString *)eventName
                   attributes:(NSDictionary *)attributes
        customerValueIncrease:(NSNumber *)customerValueIncrease;

- (void)localyticsSessionWillClose;

@end

@protocol LLMessagingDelegate <NSObject>
@optional

- (void)localyticsWillDisplayInAppMessage;
- (void)localyticsDidDisplayInAppMessage;
- (void)localyticsWillDismissInAppMessage;
- (void)localyticsDidDismissInAppMessage;

@end
