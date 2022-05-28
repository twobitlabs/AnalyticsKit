// -*- mode: objc -*-
//
// Copyright (C) 2012 Chartbeat Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "CBPing.h"
#import "CBReachability.h"
#import <CoreLocation/CoreLocation.h>
#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSUInteger, CBTrackerStatus) {

    CBTrackerStatusNotStarted       = 0,
    CBTrackerStatusUserPaused       = 1, // user manually called stopped the tracker
    CBTrackerStatusStarted          = 2

};

typedef NS_ENUM(NSUInteger, CBTrackerLogLevel) {

    CBTrackerLogLevelVerbose        = 0,
    CBTrackerLogLevelDebug          = 1,
    CBTrackerLogLevelWarning        = 2,
    CBTrackerLogLevelError          = 3

};

extern NSString * const kChartbeatSDKVersion;
extern NSString * const kCBPersistenTokenKey;
extern NSString * const kCBIosUserAgent;

extern uint const kCBNumWordsForSessionKey;
extern int const kDecayDelay;
extern int const kInitialPingInterval;

/**
 * # Chartbeat iOS Tracker.
 *
 * ### Setup
 *
 * Drag the framework file into your project.
 *
 * ### Initialization
 *
 * Import the `CBTracker.h` file in your app's delegate.
 *
 *     #import "CBTracker.h"
 *
 * Initialize the tracker by calling the `startTrackerWithAccountID` method on
 * the tracker singleton obtained via `[CBTracker sharedTracker]`. It is often
 * convenient to call this method directly in the `applicationDidBecomeActive`
 * method of your app delegate. You should also initialize the domain and
 * subDomain settings at this time:
 *
 *     [[CBTracker sharedTracker] startTrackerWithAccountID:1234];
 *     [[CBTracker sharedTracker] setDomain:@"yoursite.com"];
 *     [[CBTracker sharedTracker] setSubDomain:@"yoursite.com"];
 *
 * If your desktop site is tracked in Chartbeat as `yoursite.com`, we recommend
 * you `setDomain` to `yoursite.com`. However, your iOS app tracking can be sent
 * to a separate dashboard if you prefer. Unless you have a specific reason to
 * do otherwise, you should `setSubDomain` to the same value as `setDomain`.
 *
 * If you do not use `setDomain` and `setSubDomain`, your iOS app tracking data
 * will report to a dashboard named for your app bundle identifier. Mostly for
 * debugging purposes, you can add a suffix to the bundle identifier by calling
 * `startTrackerWithAccountID: suffix:`. For example, if the bundle is called
 * `com.example.ios`, and the suffix is `"debug"`, your app will track to
 * `"com.example.ios.debug"`.
 *
 *
 * ### Tracking each View
 *
 * To track a view, your view controller should import `CBTracker.h`, and then
 * in `viewDidAppear`:
 * - Call `setSections` and `setAuthors` to set the section and author
 *   metadata to report with this view. If a view does not have section or
 *   author metadata associated with it, pass an empty array.
 * - call `trackView`. See the comments for `trackView` below for detailed
 *   info on the parameters.
 *
 *     [[CBTracker sharedTracker] setAuthors:@[@"John Smith", @"Jane Doe"]];
 *     [[CBTracker sharedTracker] setSections:@[@"news", @"tech"]];
 *     [[CBTracker sharedTracker] trackView:self.view
 *         viewId:@"/article/date/brand-new-driverless-cars"
 *         title:@"Driverless cars will overpower humanity"];
 *
 * To temporarily pause tracking (rarely needed), call the `stopTracker`
 * method. To resume after a `stopTracker` call, call `trackView` again.
 */
@interface CBTracker : NSObject
{
    NSTimer * dwellTimer;
    uint dwellTime; // track the time spent on each page
    CBPing * ping;
    uint interval;
    uint lastInterval;
    uint initialInterval;
    NSString *userReturnFrequencyHex;
    NSString *subscriptionState;
    BOOL active;
    CBReachability * reachability;
    CLLocation * location;
    CGFloat maxScrollPosition;
    BOOL keyboardVisible;
    /**
     * engagement metrics
     */
    BOOL userReadSinceLastPing;
    BOOL userWroteSinceLastPing;
    uint remainingEngagedSeconds;
    uint engagedSeconds;
    uint engagedSecondsSinceLastPing;
    uint engagementWindow;
    CBTracker *videoTracker;

    /**
     * Is the tracker currently sending pings?
     */
    BOOL sendingPings;
    NSString * lastId;
}

/**
 * Singleton instance of this class for convenience.
 */
+ (CBTracker *)sharedTracker;

/**
 * Initialize the chartbeat tracker library. The tracker will not start until you call trackView
 *
 * @param uid Your chartbeat account id
 * @param domain The domain name to report to.
 */
- (BOOL)setupTrackerWithAccountId:(int)uid_ domain:(NSString *)domain;

/**
 * Stop tracking.
 *
 * Usually not needed. To resume tracking, use `trackView`.
 */
- (void)stopTracker;

/**
 * Set whether the user is in an active state or not. I.e. if the user
 * is just reading a view, not doing any interaction with the app,
 * this should be set to `NO`. The default state is `YES`.
 *
 * @note Calling `trackView` will automatically set `active` to `YES`.
 *
 * @param active `NO` if user is inactive, `YES` otherwise.
 */
- (void)active:(BOOL)active_;

/**
 * Sets the minimum interval, in seconds, to wait between sending
 * chartbeat tracking beacons. The higher the number, the less
 * precise.
 *
 * The default value is 15 seconds.
 *
 * @note This will take effect on the next call to `trackView`
 *
 * @param interval New interval (seconds)
 */
- (void)setInterval:(int)interval;

/**
 * Sets the author metadata to report with the next `trackView` call.
 *
 * @param authors An array of strings; author names to report with the
 *        tracked view.
 */
- (void)setAuthors:(NSArray *)authors;

/**
 * Sets the section metadata to report with the next `trackView` call.
 *
 * @param sections An array of strings; section names to report with the
 *        tracked view.
 */
- (void)setSections:(NSArray *)sections;

/**
 * Start tracking the user as being on a specific view controller. Typically you
 * will want to call this when the view is visible to the user (e.g. in the
 * `viewDidAppear` method). As described in the implementation instructions,
 * you should call `setAuthors` and `setSections` to set the metadata for a
 * view immediately _before_ calling `trackView` for a view controller.
 *
 * @param view The view being tracked (self.view when calling from your view
 *             controller)
 * @param viewId A string unique identifier for this view, starting with a slash
 *               (`'/'`), similar to a relative path on a website. It should
 *               generally look like a url -- for example,
 *               `/article/date/brand-new-driverless-cars`
 * @param title A string title for the content of the view. For example,
 *              `Driverless cars will overpower humanity`.
 */
- (BOOL)trackView:(id)view viewId:(NSString *)viewId_ title:(NSString *)title_;

- (void)setZones:(NSArray *)zones;
- (void)setAppReferrer:(NSString *)appReferrer;

- (void)setLocation:(CLLocation *)location;

- (void)setPushReferrer:(NSString *)pushReferrer;
- (void)userEngaged:(BOOL)writing;
- (void)setUserPaid;
- (void)setUserLoggedIn;
- (void)setUserAnonymous;


/**
 * Set the subDomain name to report tracking data to. Unless you have specific
 * reason to do otherwise, you should set this to the same value you used for
 * `setDomain`.
 *
 * @param subDomain The subDomain name to report to.
 */
- (void)setSubDomain:(NSString *)subDomain;

@property (nonatomic, readonly) uint uid; // Your chartbeat account id
@property (nonatomic) NSString * appid;
@property (nonatomic) NSString * suffix;
@property (nonatomic) UIView * view;
@property (nonatomic) NSString * viewId;
@property (nonatomic) NSString * title;
@property (nonatomic) NSArray * sections;
@property (nonatomic) NSArray * authors;
@property (nonatomic) NSArray * zones;
@property (nonatomic, readonly) NSString * userToken;
@property (nonatomic, readonly) NSString * sessionToken;
@property (nonatomic) NSString * previousSessionToken;
@property (nonatomic) NSString * appReferrer;
@property (nonatomic) NSString * domain;
@property (nonatomic) NSString * subDomain;
@property (nonatomic) NSString * userAgent;
@property (nonatomic) NSDictionary *extraParams;
@property (nonatomic) BOOL firstPing;
@property (nonatomic, readonly) double initializationTime;

/**
 *  turn debug mode on to enable logs and asserts to help with integration,
 Please make sure the debug mode is off when you are building for official release of your app.
 */
@property (nonatomic, assign) BOOL debugMode;

/**
 *  `CBTrackerLogLevel` gives you control over the level of logs you want to see
 */
@property (nonatomic, assign) CBTrackerLogLevel logLevel;

/**
 *  `CBTrackerStatus` shows if the tracker has started or not
 */
@property (nonatomic, assign, readonly) CBTrackerStatus status;

@end
