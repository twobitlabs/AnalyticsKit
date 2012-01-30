AnalyticsKit : an analytics provider wrapper for iOS

INTRODUCTION
============
The goal of AnalyticsKit is to provide a consistent API for analytics
regardless of which analytics provider you're using behind the scenes.

The benefit of using AnalyticsKit is that if you decide to start using a new 
analytics provider, or add an additional one, you need to write/change much less code!


INCLUDED PROVIDERS
==================
TestFlight
Localytics
Flurry
Apsalar


USAGE
=====
1. Download the provider's SDK and add it to your project

2. In your AppDelegate's applicationDidFinishLaunchingWithOptions (or in a method called from there), create an AnalyticsKit*Provider (where * is the provider); add it to your loggers array; and call initializeLoggers

/******* SAMPLE CODE
 // Create the AnalyticsKitApsalarProvider
    NSString *apsalarKey = @"myAPIKey";
    NSString *apsalarSecret = @"mySecret";
    
//if you don't want your simulator activity to be logged, use bogus keys
#if (TARGET_IPHONE_SIMULATOR)
    apsalarKey = @"XXXXXXXXXXXXXXXXXXXX";
    apsalarSecret = @"XXXXXXXXXXXXXXXXXXXX";
#endif
 
    NSMutableArray *loggers = [[NSMutableArray arrayWithObject:[[[AnalyticsKitApsalarProvider alloc] initWithAPIKey:apsalarKey andSecret:apsalarSecret andLaunchOptions:launchOptions] autorelease]] retain];
    
//if you are using more than one analytics provider, create as many AnalyticsKit*Providers as you need,
//and add them to loggers array

    //initialize AnalyticsKit to send messages to Flurry and TestFlight
    [AnalyticsKit initializeLoggers:loggers];
    
**************/

3. Where significant events occur, call AnalyticsKit logEvent: or other appropriate method. Example:
    [AnalyticsKit logEvent:@"Notifications - Displaying Webview For Notification" withProperties:eventDict];
    
4. You may also want to make AnalyticsKit calls at application lifecycle events, such as applicationDidEnterBackground, applicationWillTerminate, applicationWillEnterForeground

----> SEE ANALYTICSKIT.H for an overview of the methods available. Doublecheck that the methods you call are implemented in the AnalyticsKit*Provider.m that you are using!



