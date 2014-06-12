//
//  LocalyticsDatapointHelper.m
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.

#import "LocalyticsDatapointHelper.h"
#import "LocalyticsConstants.h"
#import "LocalyticsUtil.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <ifaddrs.h>

#define PATH_TO_APT                 @"/private/var/lib/apt/"

@implementation LocalyticsDatapointHelper

/*!
 @method appVersion
 @abstract Gets the pretty string for this application's version.
 @return The application's version as a pretty string
 */
+ (NSString *)appVersion
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    if (version == nil || [version isEqualToString:@""])
        version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    return version;
}

/*!
 @method isDeviceJailbroken
 @abstract checks for the existance of apt to determine whether the user is running any
 of the jailbroken app sources.
 @return whether or not the device is jailbroken.
 */
+ (BOOL)isDeviceJailbroken
{
	NSFileManager *sessionFileManager = [NSFileManager defaultManager];
	return [sessionFileManager fileExistsAtPath:PATH_TO_APT];
}

/*!
 @method isDevBuild
 @abstract inspects the embedded provisioning file to determine if the app is using a
 development profile
 @return whether or not the provisioning profile is of type development
 */
+ (BOOL)isDevBuild
{
    BOOL isDevBuild = NO;
    
    @try
    {
        NSString *provisionFilePath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
        
        if (provisionFilePath)
        {
            NSError *error = nil;
            NSString *provisionFileContents = [[NSString alloc] initWithContentsOfFile:provisionFilePath encoding:NSASCIIStringEncoding error:&error];
            if (error == nil && provisionFileContents.length > 0)
            {
                NSScanner *scanner = [[[NSScanner alloc] initWithString:provisionFileContents] autorelease];
                if ([scanner scanUpToString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" intoString:nil])
                {
                    NSString *plistString = nil;
                    if ([scanner scanUpToString:@"</plist>" intoString:&plistString])
                    {
                        if (plistString && plistString.length > 0)
                        {
                            NSDictionary *plist = [[plistString stringByAppendingString:@"</plist>"] propertyList];
                            if (plist && plist.count > 0)
                            {
                                if ([plist valueForKeyPath:@"ProvisionedDevices"])
                                {
                                    if ([[plist valueForKeyPath:@"Entitlements.get-task-allow"] boolValue])
                                    {
                                        isDevBuild = YES;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @catch (NSException *exception)
    {
        LocalyticsLog("Failed to parse embedded.mobileprovision for provisioning profile type. Assuming production.");
    }
    @finally
    {
        return isDevBuild;
    }
}

/*!
 @method deviceModel
 @abstract Gets the device model string.
 @return a platform string identifying the device
 */
+ (NSString *)deviceModel
{
	char *buffer[256] = { 0 };
	size_t size = sizeof(buffer);
	sysctlbyname("hw.machine", buffer, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:(const char*)buffer
											encoding:NSUTF8StringEncoding];
	return platform;
}

/*!
 @method modelSizeString
 @abstract Checks how much disk space is reported and uses that to determine the model
 @return A string identifying the model, e.g. 8GB, 16GB, etc
 */
+ (NSString *)modelSizeString
{
#if TARGET_IPHONE_SIMULATOR
	return @"simulator";
#endif
	
	// User partition
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];
	uint64_t user = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// System partition
	path = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);
	stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];
	uint64_t system = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// Add up and convert to gigabytes
	// TODO: seem to be missing a system partiton or two...
	uint64_t size = (user + system) >> 30;
	
	// Find nearest power of 2 (eg, 1,2,4,8,16,32,etc).  Over 64 and we return 0
	for (NSInteger gig = 1; gig < 257; gig = gig << 1) {
		if (size < gig)
			return [NSString stringWithFormat:@"%ldGB", (long)gig];
	}
	return nil;
}

/*!
 @method availableMemory
 @abstract Reports how much memory is available
 @return A double containing the available free memory
 */
+ (double)availableMemory
{
	double result = NSNotFound;
	
	vm_statistics_data_t stats;
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	if (!host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&stats, &count))
		result = vm_page_size * stats.free_count;
	
	return result;
}

/*!
 @method advertisingIdentifier
 @abstract An alphanumeric string unique to each device, used for advertising only.
 From UIDevice documentation.
 
 @return An identifier unique to this device.
 */
+ (NSString *)advertisingIdentifier
{
	NSString *adId = nil;
	if ([LocalyticsUtil advertisingIdentifierEnabled])
	{
		Class advertisingClass = NSClassFromString(@"ASIdentifierManager");
		if (advertisingClass) {
			SEL adidSelector = NSSelectorFromString(@"advertisingIdentifier");
			adId = [[[advertisingClass performSelector:NSSelectorFromString(@"sharedManager")] performSelector:adidSelector] performSelector:NSSelectorFromString(@"UUIDString")];
		}
	}
	return adId;
}

/*!
 @method advertisingTrackingEnabled
 @abstract A Boolean value that indicates whether the user has limited ad tracking.
 From UIDevice documentation.
 
 @return Whether or not tracking is enabled for this device.
 */
+ (BOOL)advertisingTrackingEnabled
{
	BOOL enabled = YES;
	Class advertisingClass = NSClassFromString(@"ASIdentifierManager");
	if (advertisingClass) {
		SEL trackingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
		enabled = [[advertisingClass performSelector:NSSelectorFromString(@"sharedManager")] performSelector:trackingEnabledSelector];
	}
	return enabled;
}

/*!
 @method identifierForVendor
 @abstract An alphanumeric string that uniquely identifies a device to the app’s vendor.
 From UIDevice documentation.
 
 @return An identifier unique to the app's vendor.
 */
+ (NSString *)identifierForVendor
{
    NSString *vendorId = nil;
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:NSSelectorFromString(@"identifierForVendor")])
    {
        vendorId = [[device performSelector:NSSelectorFromString(@"identifierForVendor")] performSelector:NSSelectorFromString(@"UUIDString")];
    }
	return vendorId;
}

/*!
 @method bundleIdentifier
 @abstract A string that uniquely identifies an app's bundle.
 
 @return An identifier unique to the app's bundle (ie, com.company.app).
 */
+ (NSString *)bundleIdentifier
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

@end
