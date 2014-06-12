//
//  LocalyticsDatapointHelper.h
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.

#import <UIKit/UIKit.h>

@interface LocalyticsDatapointHelper : NSObject

+ (NSString *)appVersion;
+ (BOOL)isDeviceJailbroken;
+ (BOOL)isDevBuild;
+ (NSString *)deviceModel;
+ (NSString *)modelSizeString;
+ (double)availableMemory;
+ (NSString *)advertisingIdentifier;
+ (BOOL)advertisingTrackingEnabled;
+ (NSString *)identifierForVendor;
+ (NSString *)bundleIdentifier;

@end
