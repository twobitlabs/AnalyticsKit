# AnalyticsKit

The goal of `AnalyticsKit` is to provide a consistent API for analytics regardless of the provider. With `AnalyticsKit`, you just call one logging method and `AnalyticsKit` relays that logging message to each registered provider. 

## Supported Providers

* [TestFlight](https://testflightapp.com/)
* [Localytics](http://www.localytics.com/)
* [Flurry](http://www.flurry.com/)
* [Apsalar](http://apsalar.com/)
* [Mixpanel](https://mixpanel.com/)
* [Parse](http://parse.com/)
* [Google Analytics](https://www.google.com/analytics) (version 2.0 beta4)
* [New Relic](http://www.newrelic.com)
* Debug Provider - shows an AlertView whenever an error is logged
* Unit Test Provider - allows you to inspect logged events

If you would like to add support for a new provider or to update the code for an existing one, simply fork the master repo, make your changes, and submit a pull request.

## How to Use

### Cocoapods
If your project uses Cocoapods, you can simply inlcude `AnalyticsKit` for full provider support, or you can specify your provider using Cocoapods subspecs.

* TestFlight - `pod 'AnalyticsKit/TestFlight'`
* Flurry - `pod 'AnalyticsKit/Flurry'`
* Mixpanel - `pod 'AnalyticsKit/Mixpanel'`
* Parse - `pod 'AnalyticsKit/Parse'`
* Google Analytics - `pod 'AnalyticsKit/GoogleAnalytics'`
* New Relic - `pod 'AnalyticsKit/NewRelic'`

### Installation
1. Download the provider's SDK and add it to your project, or install via cocoapods.
2. Add AnalyticsKit to your project either as a git submodule or copying the source into your project. In Xcode, only include AnalyticsKit.h/.m and any providers you plan to use.
3. In your AppDelegate's applicationDidFinishLaunchingWithOptions: method, create an array with your provider instance(s) and call `initializeLoggers:`.

```objc
NSString *flurryKey = @"0123456789ABCDEF";

// If you're running tethered or in the simulator, it's best to use different/fake keys
// instead of bypassing AnalyticsKit completely.
#if DEBUG
	flurryKey = @"0000000000000000";
#endif

AnalyticsKitFlurryProvider *flurry = [[AnalyticsKitFlurryProvider alloc] initWithAPIKey:flurryKey];

[AnalyticsKit initializeLoggers:@[flurry]];
```

To log an event, simply call the `logEvent:` method.

```objc
[AnalyticsKit logEvent:@"Log In" withProperties:infoDict];
```

See AnalyticsKit.h for an exhaustive list of the logging methods available.


## Contributors
 - [Two Bit Labs](http://twobitlabs.com/)
 - [Todd Huss](https://github.com/thuss)
 - [Susan Detwiler](https://github.com/sherpachick)
 - [Christopher Pickslay](https://github.com/chrispix)
 - [Zac Shenker](https://github.com/zacshenker)
 - [Sinnerschrader Mobile](https://github.com/sinnerschrader-mobile)
 - [Bradley David Bergeron](https://github.com/bdbergeron) - Parse
