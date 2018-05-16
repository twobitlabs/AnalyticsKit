#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Record of consent under the GDPR.
 */
@interface MPGDPRConsent : NSObject <NSCopying>

@property (nonatomic, assign) BOOL consented;
@property (nonatomic, copy, nullable) NSString *document;
@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy, nullable) NSString *location;
@property (nonatomic, copy, nullable) NSString *hardwareId;

@end

NS_ASSUME_NONNULL_END
