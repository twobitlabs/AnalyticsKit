#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IOS == 1
    #import <CoreTelephony/CTTelephonyNetworkInfo.h>
    #import <CoreTelephony/CTCarrier.h>
#endif

extern NSString * _Nonnull const kMPDeviceInformationKey;


@interface MPDevice : NSObject <NSCopying> 

#if TARGET_OS_IOS == 1
@property (nonatomic, strong, readonly, nullable) CTCarrier *carrier;
@property (nonatomic, strong, readonly, nonnull) NSString *radioAccessTechnology;
#endif

@property (nonatomic, strong, readonly, nullable) NSString *advertiserId;
@property (nonatomic, strong, readonly, nonnull) NSString *architecture;
@property (nonatomic, strong, readonly, nonnull) NSString *brand;
@property (nonatomic, strong, readonly, nullable) NSString *country;
@property (nonatomic, strong, readonly, nonnull) NSString *deviceIdentifier;
@property (nonatomic, strong, readonly, nullable) NSString *language;
@property (nonatomic, strong, readonly, nonnull) NSNumber *limitAdTracking;
@property (nonatomic, strong, readonly, nonnull) NSString *manufacturer __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSString *model;
@property (nonatomic, strong, readonly, nullable) NSString *name;
@property (nonatomic, strong, readonly, nonnull) NSString *platform __attribute__((const));
@property (nonatomic, strong, readonly, nullable) NSString *product;
@property (nonatomic, strong, readonly, nullable) NSString *operatingSystem;
@property (nonatomic, strong, readonly, nonnull) NSString *timezoneOffset;
@property (nonatomic, strong, readonly, nullable) NSString *timezoneDescription;
@property (nonatomic, strong, readonly, nullable) NSString *vendorId;
@property (nonatomic, strong, readonly, nullable) NSString *buildId;
@property (nonatomic, unsafe_unretained, readonly) CGSize screenSize;
@property (nonatomic, unsafe_unretained, readonly) BOOL isDaylightSavingTime;
@property (nonatomic, unsafe_unretained, readonly, getter = isTablet) BOOL tablet;

+ (nonnull NSDictionary *)jailbrokenInfo;
- (nonnull NSDictionary *)dictionaryRepresentation;

@end
