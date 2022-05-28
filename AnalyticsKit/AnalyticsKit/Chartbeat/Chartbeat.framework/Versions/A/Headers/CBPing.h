// -*- mode: objc -*-
//
// Copyright (C) 2012 Chartbeat Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>

extern NSString * const CBPingURL;
extern NSString * const kCBPagePathKeyForVideo;
extern NSString * const kCBPageDomainKeyForVideo;
extern NSString * const kCBPageAppIdKeyForVideo;
extern NSString * const kCBPageTitleKeyForVideo;
extern NSString * const kCBContentEngagementKeyForVideo;

/* Video Related Keys on Page */
extern NSString * const kCBVideoPathKeyForPage;
extern NSString * const kCBVideoTitleKeyForPage;
extern NSString * const kCBVideoHostKeyForPage;

/* Common Keys */
extern NSString * const kCBPathKey;
extern NSString * const kCBTitleKey;
extern NSString * const kCBHostKey;
extern NSString * const kCBVideoTypeKey;
extern NSString * const kCBVideoDurationKey;
extern NSString * const kCBVideoStateKey;
extern NSString * const kCBVideoThumbnailKey;

@interface CBPing : NSObject {
  /**
   * Did last ping result in an error?
   */
  BOOL lastWasError;
  NSMutableDictionary *previousRequests;

  /**
   * If not null, don't send pings until the given date.
   */
  NSDate* lockOutEnd;

  NSURLConnection *theConnection;
}

@property (nonatomic) BOOL referrerSent;

- (void)trackAccountID:(uint)accountId 
             firstPing:(BOOL)firstPing
                domain:(NSString *)domain 
                subDomain:(NSString *)subDomain
                  path:(NSString *)path
                 title:(NSString *)title 
                   new:(BOOL)new
                 decay:(uint)decay 
             userToken:(NSString *)userToken 
          sessionToken:(NSString *)sessionToken 
             dwellTime:(uint)dwell 
         contentHeight:(CGFloat)height
         contentWidth:(CGFloat)contentWidth
        scrollPosition:(CGFloat)scrollPosition
        maxScrollPosition:(uint)maxScrollPosition
              lastPath:(NSString *)lastPath
               authors:(NSArray *)authors
              sections:(NSArray *)sections
                 zones:(NSArray *)zones
                 appReferrer:(NSString *)appReferrer
                 appid:(NSString *)appid
                 userAgent:(NSString *)userAgent
                 screenHeight:(float)screenHeight
                 screenWidth:(float)screenWidth
                location:(CLLocation *)location
             frequency:(NSString *)frequency
              userRead:(BOOL)userRead
             userWrote:(BOOL)userWrote
        engagedSeconds:(uint)engagedSeconds
engagedSecondsSinceLastPing:(uint)engagedSecondsSinceLastPing
    pingEndpointVersion:(uint)pingEndpointVersion
    sdkVersion:(NSString *)sdkVersion
    siteVisitDepth:(long)siteVisitDepth
    siteVisitReferrer:(NSString *)siteVisitReferrer
    siteVisitUid:(NSString *)siteVisitUid
    subscriptionState:(NSString *)subscriptionState
  previousSessionToken:(NSString *)previousSessionToken;

+ (NSString *)urlEncode:(NSString *)str;

@end
