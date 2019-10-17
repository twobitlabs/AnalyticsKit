#import "MPEnums.h"
#import "MPIConstants.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@class MPSession;
@class MPCommerceEvent;
@class MPUserAttributeChange;
@class MPUserIdentityChange;
@class MPMessage;

@interface MPMessageBuilder : NSObject {
@protected
    NSMutableDictionary<NSString *, id> *messageDictionary;
    NSString *uuid;
    MPMessageType messageTypeValue;
}

@property (nonatomic, strong, readonly, nonnull) NSString *messageType;
@property (nonatomic, strong, readonly, nullable) MPSession *session;
@property (nonatomic, strong, readonly, nonnull) NSDictionary *messageInfo;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval timestamp;

+ (NSString *_Nullable)stringForMessageType:(MPMessageType)type;
+ (MPMessageType)messageTypeForString:(NSString *_Nonnull)string;
+ (nonnull MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(nullable MPSession *)session messageInfo:(nullable NSDictionary<NSString *, id> *)messageInfo;
+ (nonnull MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(nonnull MPSession *)session userAttributeChange:(nonnull MPUserAttributeChange *)userAttributeChange;
+ (nonnull MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(nonnull MPSession *)session userIdentityChange:(nonnull MPUserIdentityChange *)userIdentityChange;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType session:(nullable MPSession *)session;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType session:(nullable MPSession *)session messageInfo:(nullable NSDictionary<NSString *, id> *)messageInfo;
- (nonnull MPMessageBuilder *)withLaunchInfo:(nonnull NSDictionary *)launchInfo;
- (nonnull MPMessageBuilder *)withTimestamp:(NSTimeInterval)timestamp;
- (nonnull MPMessageBuilder *)withStateTransition:(BOOL)sessionFinalized previousSession:(nullable MPSession *)previousSession;
- (nonnull MPMessage *)build;

#if TARGET_OS_IOS == 1
- (nonnull MPMessageBuilder *)withLocation:(nonnull CLLocation *)location;
#endif

@end

extern NSString * _Nonnull const launchInfoStringFormat;
extern NSString * _Nonnull const kMPHorizontalAccuracyKey;
extern NSString * _Nonnull const kMPLatitudeKey;
extern NSString * _Nonnull const kMPLongitudeKey;
extern NSString * _Nonnull const kMPVerticalAccuracyKey;
extern NSString * _Nonnull const kMPRequestedAccuracy;
extern NSString * _Nonnull const kMPDistanceFilter;
extern NSString * _Nonnull const kMPIsForegroung;
