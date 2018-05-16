#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MPNetworkMeasurementMode) {
    MPNetworkMeasurementModeExclude = 0,
    MPNetworkMeasurementModePreserveQuery,
    MPNetworkMeasurementModeAbridged
};

@interface MPNetworkPerformance : NSObject <NSCopying>

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong, readonly) NSString *POSTBody;
@property (nonatomic, unsafe_unretained) NSTimeInterval startTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval endTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval elapsedTime;
@property (nonatomic, unsafe_unretained) NSUInteger bytesIn;
@property (nonatomic, unsafe_unretained) NSUInteger bytesOut;
@property (nonatomic, unsafe_unretained) NSInteger responseCode;
@property (nonatomic, unsafe_unretained, readonly) MPNetworkMeasurementMode networkMeasurementMode;

- (instancetype)initWithURLRequest:(NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode;
- (void)setStartDate:(NSDate *)date;
- (void)setEndDate:(NSDate *)date;
- (NSDictionary *)dictionaryRepresentation;

@end
