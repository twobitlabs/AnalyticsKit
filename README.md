AnalyticsKit : an analytics provider wrapper for iOS

INTRODUCTION
============
The goal of AnalyticsKit is to provide a consistent API for analytics
regardless of which analytics provider you're using behind the scenes.

The benefit of using AnalyticsKit is that if you decide to start using a new 
analytics provider, or add an additional one, you need to write/change much less code!

AnalyticsKit works both in ARC based projects and non-ARC projects.

CONTRIBUTIONS
=============
[Analytics Kit](https://github.com/twobitlabs/AnalyticsKit) relies on the contributions of the open-source community! To submit a fix or an enhancement fork the repository, make your changes, add your name to the *Contributors* section in README.markdown, and send us a pull request! If you're active and do good work we'll add you as a collaborator!

INCLUDED PROVIDERS
==================
* [TestFlight](https://testflightapp.com/)
* [Localytics](http://www.localytics.com/)
* [Flurry](http://www.flurry.com/)
* [Apsalar](http://apsalar.com/)
* [Mixpanel](https://mixpanel.com/)
* [Google Analytics](https://www.google.com/analytics) (version 2.0 beta4)
* [New Relic](http://www.newrelic.com) 
* Debug Provider: that shows an AlertView whenever an error is logged
* Unit Test Provider: that allows you to introspect events that were logged

COCOAPODS
=====

You can setup the project via cocoapods using subspecs. List of supported providers:

* TestFlight - `pod 'AnalyticsKit/TestFlight'`
* Flurry - `pod 'AnalyticsKit/Flurry'`
* Mixpanel - `pod 'AnalyticsKit/Mixpanel'`
* Google Analytics - `pod 'AnalyticsKit/GoogleAnalytics'`
* New Relic - `pod 'AnalyticsKit/NewRelic'`

USAGE
=====
1. Download the provider's SDK and add it to your project

2. Add AnalyticsKit to your project either as a git-submodule or copying the source into your project. In Xcode only include AnalyticsKit.m and AnalyticsKit.h and any providers you plan to use

3. In your AppDelegate's applicationDidFinishLaunchingWithOptions (or in a method called from there), create an AnalyticsKit*Provider (where * is the provider); add it to your loggers array; and call initializeLoggers

```obj-c
// Create the AnalyticsKitApsalarProvider
NSString *apsalarKey = @"myAPIKey";
NSString *apsalarSecret = @"mySecret";
    
//if you don't want your simulator activity to be logged, use bogus keys. We prefer this approach to not inlcuding the provider in simulator builds so that the code running in the simulator is as close as possible to the code running on the device.
#if (TARGET_IPHONE_SIMULATOR)
    apsalarKey = @"XXXXXXXXXXXXXXXXXXXX";
    apsalarSecret = @"XXXXXXXXXXXXXXXXXXXX";
#endif

NSMutableArray *loggers = [NSMutableArray arrayWithObject:[[AnalyticsKitApsalarProvider alloc] initWithAPIKey:apsalarKey andSecret:apsalarSecret andLaunchOptions:launchOptions]];

//if you are using more than one analytics provider, create as many AnalyticsKit*Providers as you need,
//and add them to loggers array

[AnalyticsKit initializeLoggers:loggers];
```

3. Where significant events occur, call AnalyticsKit logEvent: or other appropriate method. Example:

```obj-c
[AnalyticsKit logEvent:@"User logged in" withProperties:eventDict];
```
    
4. You may also want to make AnalyticsKit calls at application lifecycle events, such as applicationDidEnterBackground, applicationWillTerminate, applicationWillEnterForeground

See AnalyticsKit.h for an overview of the methods available. Doublecheck that the methods you call are implemented in the AnalyticsKit*Provider.m that you are using!

Contributors
============
 - [Two Bit Labs](http://twobitlabs.com/)
 - [Todd Huss](https://github.com/thuss)
 - [Susan Detwiler](https://github.com/sherpachick)
 - [Christopher Pickslay](https://github.com/chrispix)
 - [Zac Shenker](https://github.com/zacshenker)
 - [Sinnerschrader Mobile](https://github.com/sinnerschrader-mobile)

