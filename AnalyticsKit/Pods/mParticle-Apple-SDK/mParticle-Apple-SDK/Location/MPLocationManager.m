#import "MPLocationManager.h"
#import <UIKit/UIKit.h>

static BOOL trackingLocation = NO;

#if TARGET_OS_IOS == 1
@interface MPLocationManager() <CLLocationManagerDelegate>

@end
#endif

@implementation MPLocationManager

#if TARGET_OS_IOS == 1
- (instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    self = [super init];
    
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

    _authorizationRequest = authorizationRequest;
    _requestedAccuracy = accuracy;
    _requestedDistanceFilter = distance;
    trackingLocation = NO;
    _backgroundLocationTracking = YES;
    
    return self;
}

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

#pragma mark Public accessors
- (CLLocationManager *)locationManager {
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
}

#pragma mark Public methods
- (void)endLocationTracking {
    [_locationManager stopUpdatingLocation];
    _locationManager = nil;
    _location = nil;
    trackingLocation = NO;
}
#endif

#pragma mark Class methods
+ (BOOL)trackingLocation {
    return trackingLocation;
}

@end
