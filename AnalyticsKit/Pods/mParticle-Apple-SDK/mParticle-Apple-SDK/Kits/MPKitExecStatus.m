#import "MPKitExecStatus.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "mParticle.h"

@implementation MPKitExecStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        _returnCode = MPKitReturnCodeFail;
        _forwardCount = 0;
    }
    
    return self;
}

- (instancetype)initWithSDKCode:(NSNumber *)integrationId returnCode:(MPKitReturnCode)returnCode {
    return [self initWithSDKCode:integrationId returnCode:returnCode forwardCount:(returnCode == MPKitReturnCodeSuccess ? 1 : 0)];
}

- (instancetype)initWithSDKCode:(NSNumber *)integrationId returnCode:(MPKitReturnCode)returnCode forwardCount:(NSUInteger)forwardCount {
    BOOL validReturnCode = returnCode >= MPKitReturnCodeSuccess && returnCode <= MPKitReturnCodeRequirementsNotMet;
    if (!validReturnCode) MPILogDebug(@"The 'returnCode': %lu variable is not valid.", (unsigned long)returnCode);

    if (!validReturnCode) {
        return nil;
    }

    self = [self init];
    if (self) {
        _integrationId = integrationId;
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
