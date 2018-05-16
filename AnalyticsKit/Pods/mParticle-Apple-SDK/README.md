<img src="https://static.mparticle.com/sdk/mp_logo_black.svg" width="280">

# mParticle Apple SDK

Hello! This is the public repository of the unified mParticle Apple SDK built for the iOS and tvOS platforms.

At mParticle our mission is straightforward: make it really easy for apps and app services to connect and take ownership of your 1st party data. Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing, monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services – check [our site](https://www.mparticle.com), or hit us at <support@mparticle.com> to learn more.


## Overview

This document will help you:

* Obtain the mParticle SDK via [CocoaPods](https://cocoapods.org/?q=mparticle) or via [Carthage](https://github.com/Carthage/Carthage)
* Extend the mParticle SDK with [*Kits*](#currently-supported-kits)
* Initialize the mParticle SDK

The mParticle SDK is composed of the _core_ library and a series of _kit_ libraries that depend on the core. With each integration with a partner we strive to implement as many features as possible in the server-to-server layer, however some times a deeper integration to work side-by-side with a 3rd party SDK comes with greater benefits to our clients. We use the term **Kit** to describe such integrations.

The core SDK takes care of initializing the kits depending on what you've configured in [your app's dashboard](https://app.mparticle.com), so you just have to decide which kits you may use prior to submission to the App Store. You can easily include all of the kits, none of the kits, or individual kits – the choice is yours.


## Get the SDK

The mParticle-Apple-SDK is available via [CocoaPods](https://cocoapods.org/?q=mparticle) or via [Carthage](https://github.com/Carthage/Carthage). Follow the instructions below based on your preference.

#### CocoaPods

To integrate the SDK using CocoaPods, specify it in your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

```ruby
# Uncomment the line below if you're using Swift or would like to use dynamic frameworks (recommended but not required)
# use_frameworks!

target '<Your Target>' do
    pod 'mParticle-Apple-SDK', '~> 7'
end
```

Configuring your `Podfile` with the statement above will include only the _Core_ mParticle SDK.

> If your app targets iOS and tvOS in the same Xcode project, you need to configure the `Podfile` differently in order to use the SDK with multiple platforms. You can find an example of multi-platform configuration [here](https://github.com/mParticle/mparticle-apple-sdk/wiki/Multi-platform-Configuration).

If you'd like to add any kits, you can do so as follows:

```ruby
# Uncomment the line below if you're using Swift or would like to use dynamic frameworks (recommended but not required)
# use_frameworks!

target '<Your Target>' do
    pod 'mParticle-Appboy', '~> 7'
    pod 'mParticle-BranchMetrics', '~> 7'
    pod 'mParticle-Localytics', '~> 7'
end
```

In the cases above, the _Appboy_, _Branch Metrics_, and _Localytics_ kits would be integrated together with the core SDK.

#### Working with Static Libraries

mParticle's iOS SDK and its embedded kits are [dynamic libraries](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/OverviewOfDynamicLibraries.html), meaning their code is loaded into an app's address space only as needed, as opposed to a 'static' library, which is always included in full in the app's executable file. Some mParticle embedded kits rely on static libraries maintained by our partners. A static framework, wrapped in a dynamic library is incompatible with CocoaPods' `use frameworks!` option. Affected kits are: Appboy, AppsFlyer, comScore, Kahuna, Kochava and Localytics.

Attempting to use these kits with `use_frameworks!` will result in the following error message:

`[!] The '<your Target>' target has transitive dependencies that include static binaries: (<path to framework>)`

If you need to reference these kits' methods from user-level code, you must incorporate them manually. To do this:

1. Add the partner SDK (for example, `Appboy-iOS-SDK` or `AppsFlyer-SDK`) directly to your Podfile.
2. Remove the embedded kit pod(`mParticle-<partner name>`) from the Podfile, download the source code from Github and manually drag its `.m` and `.h` files directly into your project.

#### Crash Reporter

For iOS only, you can also choose to install the crash reporter by including it as a separate pod:

```ruby
pod 'mParticle-CrashReporter', '~> 1.3'
```

You can read detailed instructions for including the Crash Reporter at its repository: [mParticle-CrashReporter](https://github.com/mParticle/mParticle-CrashReporter)

> Note you can't use the crash reporter at the same time as the Apteligent kit.

#### Carthage

To integrate the SDK using Carthage, specify it in your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```ogdl
github "mparticle/mparticle-apple-sdk" ~> 7.0
```

If you'd like to add any kits, you can do so as follows:

```ogdl
github "mparticle-integrations/mparticle-apple-integration-branchmetrics" ~> 7.0
```

In this case, only the _Branch Metrics_ kit would be integrated; all other kits would be left out.

#### Currently Supported Kits

Kit | CocoaPods | Carthage
----|:---------:|:-------:
[Adjust](https://github.com/mparticle-integrations/mparticle-apple-integration-adjust)                |  ✓ | ✓
[Appboy](https://github.com/mparticle-integrations/mparticle-apple-integration-appboy)                |  ✓ | ✓
[Adobe](https://github.com/mparticle-integrations/mparticle-apple-integration-adobe)                  |  ✓ | ✓
[AppsFlyer](https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer)          |  ✓ | ✓ 
[Apptentive](https://github.com/mparticle-integrations/mparticle-apple-integration-apptentive)        |  ✓ | ✓ 
[Apptimize](https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize)          |  ✓ |   
[Apteligent](https://github.com/mparticle-integrations/mparticle-apple-integration-apteligent)        |  ✓ |  
[Branch Metrics](https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics) |  ✓ | ✓
[Button](https://github.com/mparticle-integrations/mparticle-apple-integration-button)                |  ✓ | ✓
[comScore](https://github.com/mparticle-integrations/mparticle-apple-integration-comscore)            |  ✓ |  
[Flurry](https://github.com/mparticle-integrations/mparticle-apple-integration-flurry)                |  ✓ |  
[Instabot](https://github.com/mparticle-integrations/mparticle-apple-integration-instabot)            |  ✓ |  
[Iterable](https://github.com/mparticle-integrations/mparticle-apple-integration-iterable)            |  ✓ | ✓ 
[Kahuna](https://github.com/mparticle-integrations/mparticle-apple-integration-kahuna)                |  ✓ |  
[Kochava](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava)              |  ✓ |  
[Leanplum](https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum)            |  ✓ | ✓
[Localytics](https://github.com/mparticle-integrations/mparticle-apple-integration-localytics)        |  ✓ |  
[Primer](https://github.com/mparticle-integrations/mparticle-apple-integration-primer)                |  ✓ | ✓
[Radar](https://github.com/mparticle-integrations/mparticle-apple-integration-radar)                  |  ✓ | 
[Reveal Mobile](https://github.com/mparticle-integrations/mparticle-apple-integration-revealmobile)   |  ✓ |  
[Singular](https://github.com/mparticle-integrations/mparticle-apple-integration-singular)            |  ✓ |  
[Skyhook](https://github.com/mparticle-integrations/mparticle-apple-integration-skyhook)              |  ✓ |  
[Tune](https://github.com/mparticle-integrations/mparticle-apple-integration-tune)                    |  ✓ | ✓
[Urban Airship](https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship)   |  ✓ |  
[Wootric](https://github.com/mparticle-integrations/mparticle-apple-integration-wootric)              |  ✓ |  


## Initialize the SDK

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`. The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that it is imperative for the SDK to be initialized in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

#### Swift

```swift
import mParticle_Apple_SDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
       // Override point for customization after application launch.
        let mParticleOptions = MParticleOptions(key: "<<<App Key Here>>>", secret: "<<<App Secret Here>>>")
        
       //Please see the Identity page for more information on building this object
        let request = MPIdentityApiRequest()
        request.email = "email@example.com"
        mParticleOptions.identifyRequest = request
        mParticleOptions.onIdentifyComplete = { (apiResult, error) in
            NSLog("Identify complete. userId = %@ error = %@", apiResult?.user.userId.stringValue ?? "Null User ID", error?.localizedDescription ?? "No Error Available")
        }
        
       //Start the SDK
        MParticle.sharedInstance().start(with: mParticleOptions)
        
       return true
}
```

#### Objective-C

For apps supporting iOS 8 and above, Apple recommends using the import syntax for **modules** or **semantic import**. However, if you prefer the traditional CocoaPods and static libraries delivery mechanism, that is fully supported as well.

If you are using mParticle as a framework, your import statement will be as follows:

```objective-c
@import mParticle_Apple_SDK;                // Apple recommended syntax, but requires "Enable Modules (C and Objective-C)" in pbxproj
#import <mParticle_Apple_SDK/mParticle.h>   // Works when modules are not enabled

```

Otherwise, for CocoaPods without `use_frameworks!`, you can use either of these statements:

```objective-c
#import <mParticle-Apple-SDK/mParticle.h>
#import "mParticle.h"
```

Next, you'll need to start the SDK:

```objective-c
- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                   secret:@"REPLACE ME"];
    
    //Please see the Identity page for more information on building this object
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    request.email = @"email@example.com";
    mParticleOptions.identifyRequest = request;
    mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
    };
    
    [[MParticle sharedInstance] startWithOptions:mParticleOptions];
    
    return YES;
}
```

Please see [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.


## Example Project with Sample Code

A sample project is provided with the mParticle Apple SDK. It is a multi-platform video streaming app for both iOS and tvOS.

Clone the repository to your local machine

```bash
git clone https://github.com/mParticle/mparticle-apple-sdk.git
```

In order to run either the iOS or tvOS examples, first install the mParticle Apple SDK via [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

1. Change to the `Examples/CocoaPodsExample` directory
2. Run `pod install`
3. Open **Example.xcworkspace** in Xcode, select either the **iOS_Example** or **tvOS_Example** scheme, build and run.


## Read More

Just by initializing the SDK you'll be set up to track user installs, engagement, and much more. Check out our doc site to learn how to add specific event tracking to your app.

* [SDK Documentation](http://docs.mparticle.com/#mobile-sdk-guide)


## Support

Questions? Have an issue? Consult the [Troubleshooting](https://github.com/mParticle/mparticle-apple-sdk/wiki/Troubleshooting) page or contact our **Customer Success** team at <support@mparticle.com>.

## License

The mParticle-Apple-SDK is available under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more info.
