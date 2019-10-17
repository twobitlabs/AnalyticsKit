#import "MPLocationManager.h"
#import <UIKit/UIKit.h>

static BOOL trackingLocation = NO;

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
@interface MPLocationManager () <CLLocationManagerDelegate>

@end
#endif
#endif

@implementation MPLocationManager

#if TARGET_OS_IOS == 1
- (instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    self = [super init];
    
#ifndef MPARTICLE_LOCATION_DISABLE
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    
    if (!self || authorizationStatus == kCLAuthorizationStatusRestricted || authorizationStatus == kCLAuthorizationStatusDenied) {
        return nil;
    }
    
    self.locationManager.desiredAccuracy = accuracy;
    self.locationManager.distanceFilter = distance;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        NSDictionary *mainBundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        
        if (authorizationRequest == MPLocationAuthorizationRequestAlways &&
            [self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)] &&
            mainBundleInfoDictionary[@"NSLocationAlwaysUsageDescription"])
        {
            [self.locationManager requestAlwaysAuthorization];
        } else if (authorizationRequest == MPLocationAuthorizationRequestWhenInUse &&
                   [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] &&
                   mainBundleInfoDictionary[@"NSLocationWhenInUseUsageDescription"])
        {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager startUpdatingLocation];
        }
    } else {
        [self.locationManager startUpdatingLocation];
    }
#endif
    
    _authorizationRequest = authorizationRequest;
    _requestedAccuracy = accuracy;
    _requestedDistanceFilter = distance;
    trackingLocation = NO;
    _backgroundLocationTracking = YES;
    
    return self;
}

#ifndef MPARTICLE_LOCATION_DISABLE
#pragma mark CLLocationManager Delegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    trackingLocation = (status == kCLAuthorizationStatusAuthorizedAlways) || (status == kCLAuthorizationStatusAuthorizedWhenInUse);
    
    if (trackingLocation) {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.location = newLocation;
}
#pragma clang diagnostic pop
#endif

#pragma mark Public accessors
- (CLLocationManager *)locationManager {
#ifndef MPARTICLE_LOCATION_DISABLE
    if (_locationManager) {
        return _locationManager;
    }
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusRestricted || authorizationStatus == kCLAuthorizationStatusDenied) {
        if (_locationManager) {
            _locationManager = nil;
            _location = nil;
            trackingLocation = NO;
        }
        
        return nil;
    }
    
    [self willChangeValueForKey:@"locationManager"];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [self didChangeValueForKey:@"locationManager"];
    return _locationManager;
#else
    return nil;
#endif
}

#pragma mark Public methods
- (void)endLocationTracking {
#ifndef MPARTICLE_LOCATION_DISABLE
    [_locationManager stopUpdatingLocation];
#endif
    _locationManager = nil;
    _location = nil;
    trackingLocation = NO;
}
#endif // #if TARGET_OS_IOS == 1

#pragma mark Class methods
+ (BOOL)trackingLocation {
#ifndef MPARTICLE_LOCATION_DISABLE
    return trackingLocation;
#else
    return NO;
#endif
}

@end
