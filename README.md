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
* [Parse](http://parse.com/)
* [TestFlight](https://testflightapp.com/)
* [Crashlytics](http://crashlytics.com)
* Debug Provider - shows an AlertView whenever an error is logged
* Unit Test Provider - allows you to inspect logged events

## Unsupported Providers

The following providers are included but not supported. YMMV.

* [New Relic](http://www.newrelic.com)

	We've had a number of problems integrating the New Relic framework into the test app, so we can't verify that events are logged correctly.

If you would like to add support for a new provider or to update the code for an existing one, simply fork the master repo, make your changes, and submit a pull request.

## How to Use

### CocoaPods

__***Please Note__ -- While we welcome contributions, Two Bit Labs does not officially support CocoaPods for AnalyticsKit. If you run into problems integrating AnalyticsKit using CocoaPods, please log a GitHub issue. Due to this we are not able to deploy the latest version, if you would like the latest version you can point the pod to this repo eg.

`pod 'AnalyticsKit', :git => 'https://github.com/twobitlabs/AnalyticsKit.git'`


If your project uses CocoaPods, you can simply include `AnalyticsKit` for full provider support, or you can specify your provider using CocoaPods subspecs.

* AdjustIO - `pod 'AnalyticsKit/AdjustIO'`
* Crashlytics - `pod 'AnalyticsKit/Crashlytics'`
* Flurry - `pod 'AnalyticsKit/Flurry'`
* Google Analytics - `pod 'AnalyticsKit/GoogleAnalytics'`
* Localytics - `pod 'AnalyticsKit/Localytics'`
* Mixpanel - `pod 'AnalyticsKit/Mixpanel'`
* New Relic - `pod 'AnalyticsKit/NewRelic'`
* TestFlight - `pod 'AnalyticsKit/TestFlight'`

__***Please Note__ -- The Parse subspec has been removed, as it won't integrate correctly using CocoaPods.

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

## Apple Watch Analytics

AnalyticsKit now provides support for logging from your Apple Watch Extension.

### Supported Providers

* [Flurry](http://www.flurry.com/)

### Installation
1. If you haven't already done so, follow the installation steps above to add your provider's SDK and AnalyticsKit to your project.
2. Adding Provider's API Key.
 - Flurry: Follow steps outlined in [Flurry's Apple Watch Extension](https://developer.yahoo.com/flurry/docs/analytics/gettingstarted/technicalquickstart/applewatch/) guide to add the API Key to the Extension's info.plist.

Objective-C:

Initialize AnalyticsKit in awakeWithContext

```objc
AnalyticsKitWatchExtensionFlurryProvider *flurry = [AnalyticsKitWatchExtensionFlurryProvider new];
[AnalyticsKit initializeLoggers:@[flurry]];
```

To log an event, simply call the `logEvent:` method.

```objc
[AnalyticsKit logEvent:@"Launching Watch App"];
```

Swift:

Import AnalyticsKit and any providers in your bridging header:
 
```objc
#import "AnalyticsKit.h"
#import "AnalyticsKitWatchExtensionFlurryProvider.h"
```
 
Initialize AnalyticsKit in awakeWithContext
 
```swift
let flurryLogger = AnalyticsKitWatchExtensionFlurryProvider()
AnalyticsKit.initializeLoggers([flurryLogger])
```

To log an event, simply call the `logEvent` method.

```swift
AnalyticsKit.logEvent("Launching Watch App");
```

## Contributors
 - [Two Bit Labs](http://twobitlabs.com/)
 - [Todd Huss](https://github.com/thuss)
 - [Susan Detwiler](https://github.com/sherpachick)
 - [Christopher Pickslay](https://github.com/chrispix)
 - [Zac Shenker](https://github.com/zacshenker)
 - [Sinnerschrader Mobile](https://github.com/sinnerschrader-mobile)
 - [Bradley David Bergeron](https://github.com/bdbergeron) - Parse
 - [Jeremy Medford](https://github.com/jeremymedford)
 - [Sean Woolfolk] (https://github.com/seanw4)
 - [François Benaiteau](https://github.com/netbe)
 - [Ying Quan Tan](https://github.com/brightredchilli)
