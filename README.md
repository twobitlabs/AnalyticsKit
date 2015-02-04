[![Build Status](https://travis-ci.org/twobitlabs/AnalyticsKit.svg?branch=master)](https://travis-ci.org/twobitlabs/AnalyticsKit)
[![Gitter chat](https://badges.gitter.im/twobitlabs/AnalyticsKit.png)](https://gitter.im/twobitlabs/AnalyticsKit)

# AnalyticsKit

The goal of `AnalyticsKit` is to provide a consistent API for analytics regardless of the provider. With `AnalyticsKit`, you just call one logging method and `AnalyticsKit` relays that logging message to each registered provider. AnalyticsKit works in both Swift and Objective-C projects

## Supported Providers

* [AdjustIO](https://www.adjust.io/)
* [Apsalar](http://apsalar.com/)
* [Flurry](http://www.flurry.com/)
* [Google Analytics](https://www.google.com/analytics)
* [Localytics](http://www.localytics.com/)
* [Mixpanel](https://mixpanel.com/)
* [New Relic](http://www.newrelic.com)
* [Parse](http://parse.com/)
* [TestFlight](https://testflightapp.com/)
* [Crashlytics](http://crashlytics.com)
* Debug Provider - shows an AlertView whenever an error is logged
* Unit Test Provider - allows you to inspect logged events

If you would like to add support for a new provider or to update the code for an existing one, simply fork the master repo, make your changes, and submit a pull request.

## How to Use

### Cocoapods

__***Please Note__ -- While we welcome contributions, Two Bit Labs does not officially support Cocoapods for AnalyticsKit. If you run into problems integrating AnalyticsKit using Cocoapods, please log a GitHub issue.

If your project uses Cocoapods, you can simply include `AnalyticsKit` for full provider support, or you can specify your provider using Cocoapods subspecs.

* AdjustIO - `pod 'AnalyticsKit/AdjustIO'`
* Flurry - `pod 'AnalyticsKit/Flurry'`
* Google Analytics - `pod 'AnalyticsKit/GoogleAnalytics'`
* Localytics - `pod 'AnalyticsKit/Localytics'`
* Mixpanel - `pod 'AnalyticsKit/Mixpanel'`
* New Relic - `pod 'AnalyticsKit/NewRelic'`
* TestFlight - `pod 'AnalyticsKit/TestFlight'`

__***Please Note__ -- The Parse subspec has been removed, as it won't integrate correctly using Cocoapods.

### Installation
1. Download the provider's SDK and add it to your project, or install via cocoapods.
2. Add AnalyticsKit to your project either as a git submodule or copying the source into your project. In Xcode, only include AnalyticsKit.h/.m and any providers you plan to use.
3. In your AppDelegate's applicationDidFinishLaunchingWithOptions: method, create an array with your provider instance(s) and call `initializeLoggers:`. 
 
Objective-C:
 
Initialize AnalyticsKit in applicationDidFinishLaunchingWithOptions

```objc
AnalyticsKitFlurryProvider *flurry = [[AnalyticsKitFlurryProvider alloc] initWithAPIKey:@"[YOUR KEY]"];
[AnalyticsKit initializeLoggers:@[flurry]];
```

To log an event, simply call the `logEvent:` method.

```objc
[AnalyticsKit logEvent:@"Log In" withProperties:infoDict];
```
 
Depending on which analytics providers you use you may need to include the following method calls in your app delegate (or just go ahead and include them to be safe):
 
```objc
[AnalyticsKit applicationWillEnterForeground]; 
[AnalyticsKit applicationDidEnterBackground];  
[AnalyticsKit applicationWillTerminate];  
```
 
Swift:
 
Import AnalyticsKit and any providers in your bridging header:
 
```objc
#import "AnalyticsKit.h"
#import "AnalyticsKitNewRelicProvider.h"
```
 
Initialize AnalyticsKit in application:didFinishLaunchingWithOptions:
 
```swift
let newRelic = AnalyticsKitNewRelicProvider(APIKey: "[YOUR KEY]")
AnalyticsKit.initializeLoggers([newRelic])
```
 
Depending on which analytics providers you use you may need to include the following method calls in your app delegate (or just go ahead and include them to be safe):

```swift
AnalyticsKit.applicationWillEnterForeground()
AnalyticsKit.applicationDidEnterBackground() 
AnalyticsKit.applicationWillTerminate]()
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
