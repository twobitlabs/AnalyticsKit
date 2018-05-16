#import <Foundation/Foundation.h>
#import "MPEnums.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@interface MPLocationManager : NSObject

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, strong, nullable) CLLocationManager *locationManager;
@property (nonatomic, unsafe_unretained, readonly) MPLocationAuthorizationRequest authorizationRequest;
@property (nonatomic, unsafe_unretained, readonly) CLLocationAccuracy requestedAccuracy;
@property (nonatomic, unsafe_unretained, readonly) CLLocationDistance requestedDistanceFilter;
@property (nonatomic, unsafe_unretained) BOOL backgroundLocationTracking;

- (nullable instancetype)initWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;
- (void)endLocationTracking;
#endif

+ (BOOL)trackingLocation;

@end
