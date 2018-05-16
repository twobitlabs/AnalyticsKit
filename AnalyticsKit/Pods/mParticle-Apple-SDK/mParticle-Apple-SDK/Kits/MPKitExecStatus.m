#import "MPKitExecStatus.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitInstanceValidator.h"

@implementation MPKitExecStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        _returnCode = MPKitReturnCodeFail;
        _forwardCount = 0;
    }
    
    return self;
}

- (instancetype)initWithSDKCode:(NSNumber *)kitCode returnCode:(MPKitReturnCode)returnCode {
    return [self initWithSDKCode:kitCode returnCode:returnCode forwardCount:(returnCode == MPKitReturnCodeSuccess ? 1 : 0)];
}

- (instancetype)initWithSDKCode:(NSNumber *)kitCode returnCode:(MPKitReturnCode)returnCode forwardCount:(NSUInteger)forwardCount {
    BOOL validKitCode = [MPKitInstanceValidator isValidKitCode:kitCode];
    NSAssert(validKitCode, @"The 'kitCode' variable is not valid.");
    
    BOOL validReturnCode = returnCode >= MPKitReturnCodeSuccess && returnCode <= MPKitReturnCodeRequirementsNotMet;
    NSAssert(validReturnCode, @"The 'returnCode' variable is not valid.");

    if (!validKitCode || !validReturnCode) {
        return nil;
    }

    self = [self init];
    if (self) {
        _kitCode = kitCode;
        _returnCode = returnCode;
        _forwardCount = forwardCount;
    }
    
    return self;
}

#pragma mark Public accessors
- (BOOL)success {
    return _returnCode == MPKitReturnCodeSuccess;
}

#pragma mark Public methods
- (void)incrementForwardCount {
    ++_forwardCount;
}

@end
