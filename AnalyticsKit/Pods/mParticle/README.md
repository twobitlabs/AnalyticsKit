<img src="https://www.mparticle.com/assets/img/logo.svg" width="280">

# mParticle SDK

Your job is to build an awesome app experience that consumers love. You also need several tools and services to make data-driven decisions. Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing, monetization, etc. But embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs. From not being able to move as fast as you want, to bloating and destabilizing your app, to losing control and ownership of your 1st party data.

[mParticle](http://mparticle.com) solves all these problems with one lightweight SDK. Implement new partners without changing code or waiting for app store approval. Improve stability and security within your app. We enable our clients to spend more time innovating and less time integrating.

## Installation 

Add the following to your Podfile:

```
pod 'mParticle', '~> 4'
```

## Initialize the SDK

Call the `startWithKey` method within the application did finish launching delegate call. The mParticle SDK must be initialized with your app key and secret prior to use. 

#### Swift

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    MParticle.sharedInstance().startWithKey("<<<App Key Here>>>", secret:"<<<App Secret Here>>>")
        
    return true
}
```

#### Objective-C

```objective-c
#import <mParticle.h>

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[MParticle sharedInstance] startWithKey:@"<<<App Key Here>>>"
                                      secret:@"<<<App Secret Here>>>"];

    return YES;
}
```

## Documentation

Detailed documentation and other information about mParticle SDK can be found at: [http://docs.mparticle.com](http://docs.mparticle.com)

## Author

mParticle, Inc.

## Support

<support@mparticle.com>

## License

mParticle is available under the mParticle license. See the LICENSE file for more info.
