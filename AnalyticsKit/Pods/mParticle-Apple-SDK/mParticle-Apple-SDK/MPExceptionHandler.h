#import <Foundation/Foundation.h>

@class MPSession;

@interface MPExceptionHandler : NSObject

@property (nonatomic, weak) MPSession *session;

+ (NSDictionary *)appImageInfo;
+ (NSString *)callStack;
+ (BOOL)isHandlingExceptions;
+ (NSData *)generateLiveExceptionReport;
- (instancetype)initWithSession:(MPSession *)session __attribute__((objc_designated_initializer));
- (void)beginUncaughtExceptionLogging;
- (void)endUncaughtExceptionLogging;

@end
