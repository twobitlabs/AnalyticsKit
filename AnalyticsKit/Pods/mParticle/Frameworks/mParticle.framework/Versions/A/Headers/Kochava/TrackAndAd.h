//
//  TrackAndAd.h
//  TrackAndAd
//
//  Copyright (c) 2013-2014 Kochava. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TrackAndAd : NSObject
@end

@protocol KochavaNetworkAccessDelegate;
@protocol KochavaNetworkAccessDelegate <NSObject>
@optional
- (void) KochavaConnectionDidFinishLoading:(NSDictionary *)responseDict;
- (void) KochavaConnectionDidFailWithError:(NSError *)error;
- (void) KochavaRetrieveAttribution:(NSDictionary *)attributionResponseDict;
- (void) KochavaiBeaconMonitorLocations:(NSDictionary *)iBeaconLocations;
- (void) KochavaInitResult:(NSDictionary *)initResult;
- (void) KochavaInitialResult:(NSDictionary *)initialResult;
@end


@protocol KochavaLocationManagerDelegate;
@protocol KochavaLocationManagerDelegate <NSObject>
@optional
- (void) locationUpdate:(CLLocation*)newLocation;
- (void) iBeaconBarrierCrossed:(NSDictionary*)iBeaconBarrierAction;
@end


#pragma mark - -------------------------------------
#pragma mark - Kochava Client

@protocol KochavaTrackerClientDelegate;

@interface KochavaTracker : NSObject <KochavaNetworkAccessDelegate, KochavaLocationManagerDelegate>

#pragma mark - Swift Bridge
- (KochavaTracker*) swiftInitKochavaWithParams:(id)initDict;
- (void) swiftEnableConsoleLogging:(bool)enableLogging;
- (void) swiftTrackEvent:(id)eventTitle :(id)eventValue;
- (void) swiftIdentityLinkEvent:(id)identityLinkData;
- (void) swiftSpatialEvent:(id)eventTitle :(float)x :(float)y :(float)z;
- (void) swiftSetLimitAdTracking:(bool)limitAdTracking;
- (NSString*) swiftRetrieveAttribution;
- (void) swiftSendDeepLink:(id)url :(id)sourceApplication;
- (bool) swiftPresentInitAd;


#pragma mark - ObjC
- (id) initWithKochavaAppId:(NSString*)appId;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking :(bool)isNewUser;
- (id) initKochavaWithParams:(NSDictionary*)initDict;

- (void) enableConsoleLogging:(bool)enableLogging;

- (void) trackEvent:(NSString*)eventTitle :(NSString*)eventValue;
- (void) identityLinkEvent:(NSDictionary*)identityLinkData;
- (void) spatialEvent:(NSString*)eventTitle :(float)x :(float)y :(float)z;
- (void) setLimitAdTracking:(bool)limitAdTracking;
- (id) retrieveAttribution;
- (void) sendDeepLink:(NSURL*)url :(NSString*)sourceApplication;
- (bool) presentInitAd;

@property (nonatomic, assign) id <KochavaTrackerClientDelegate> trackerDelegate;

@end


@protocol KochavaTrackerClientDelegate <NSObject>
@optional
- (void) Kochava_attributionResult:(NSDictionary*)attributionResult;
- (void) Kochava_presentInitAd:(bool)presentInitAdResult;

- (void) Kochava_iBeaconBarrierCrossed:(NSDictionary*)iBeaconBarrierAction;
- (void) swiftDelegate:(int)testInt;
@end



#pragma mark - -------------------------------------
#pragma mark - Ad Client

@protocol KochavaAdClientDelegate;

@interface KochavaAdClient : UIView <UIWebViewDelegate, UIGestureRecognizerDelegate, KochavaNetworkAccessDelegate>

- (void) displayAdWebView:(UIViewController*)callingController :(UIView*)callingView :(bool)isInterstitial;
- (void) presentClickAd;

@property (nonatomic, assign) id <KochavaAdClientDelegate> adDelegate;
@end

@protocol KochavaAdClientDelegate <NSObject>
@optional
- (void) Kochava_adLoaded:(KochavaAdClient*)adView :(bool)isInterstitial;
- (void) Kochava_fullScreenAdWillLoad:(KochavaAdClient*)adView;
- (void) Kochava_fullScreenAdDidUnload:(KochavaAdClient*)adView;

@end

