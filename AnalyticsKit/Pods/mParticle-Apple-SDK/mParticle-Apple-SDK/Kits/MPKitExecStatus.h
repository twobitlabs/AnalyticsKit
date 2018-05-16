#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MPKitReturnCode) {
    MPKitReturnCodeSuccess = 0,
    MPKitReturnCodeFail,
    MPKitReturnCodeCannotExecute,
    MPKitReturnCodeUnavailable,
    MPKitReturnCodeIncorrectProductVersion,
    MPKitReturnCodeRequirementsNotMet
};

@interface MPKitExecStatus : NSObject

@property (nonatomic, strong, readonly, nonnull) NSNumber *kitCode;
@property (nonatomic, unsafe_unretained) MPKitReturnCode returnCode;
@property (nonatomic, unsafe_unretained, readonly) NSUInteger forwardCount;
@property (nonatomic, unsafe_unretained, readonly) BOOL success;

- (nonnull instancetype)initWithSDKCode:(nonnull NSNumber *)kitCode returnCode:(MPKitReturnCode)returnCode;
- (nonnull instancetype)initWithSDKCode:(nonnull NSNumber *)kitCode returnCode:(MPKitReturnCode)returnCode forwardCount:(NSUInteger)forwardCount;
- (void)incrementForwardCount;

@end
