#import "MPListenerController.h"
#import "MPIConstants.h"

static MPListenerController *_sharedInstance = nil;
static dispatch_once_t predicate;

@interface MPListenerController ()

@property (nonatomic, strong) NSMutableArray<id<MPListenerProtocol>> *sdkListeners;

@end

@implementation MPListenerController

#pragma mark Initialization
- (instancetype)init
{
    self = [super init];
    if (self) {
        _sdkListeners = [NSMutableArray array];
    }
    return self;
}

+ (MPListenerController *)sharedInstance {
    dispatch_once(&predicate, ^{
        _sharedInstance = [[MPListenerController alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark Private methods
- (void)addSdkListener:(id<MPListenerProtocol>)sdkListener {
    [self.sdkListeners addObject:sdkListener];
}

- (void)removeSdkListener:(id<MPListenerProtocol>)sdkListener {
    if (self.sdkListeners) {
        [self.sdkListeners removeObject:sdkListener];
    }
}

- (void)onAPICalled:(SEL)apiName {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAPICalled:stackTrace:isExternal:objects:)]) {
            NSArray *stackTrace = [NSThread callStackSymbols];
            NSMutableArray *parameters = [NSMutableArray array];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAPICalled:NSStringFromSelector(apiName) stackTrace:stackTrace isExternal:true objects:parameters];
            });
        }
    }
}

- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1  {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAPICalled:stackTrace:isExternal:objects:)]) {
            NSArray *stackTrace = [NSThread callStackSymbols];
            NSMutableArray *parameters = [NSMutableArray array];
            if (parameter1) {
                [parameters addObject:parameter1];
            } else {
                [parameters addObject:[NSNull null]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAPICalled:NSStringFromSelector(apiName) stackTrace:stackTrace isExternal:true objects:parameters];
            });
        }
    }
}

- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2 {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAPICalled:stackTrace:isExternal:objects:)]) {
            NSArray *stackTrace = [NSThread callStackSymbols];
            NSMutableArray *parameters = [NSMutableArray array];
            if (parameter1) {
                [parameters addObject:parameter1];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter2) {
                [parameters addObject:parameter2];
            } else {
                [parameters addObject:[NSNull null]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAPICalled:NSStringFromSelector(apiName) stackTrace:stackTrace isExternal:true objects:parameters];
            });
        }
    }
}

- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2 parameter3:(nullable NSObject *)parameter3 {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAPICalled:stackTrace:isExternal:objects:)]) {
            NSArray *stackTrace = [NSThread callStackSymbols];
            NSMutableArray *parameters = [NSMutableArray array];
            if (parameter1) {
                [parameters addObject:parameter1];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter2) {
                [parameters addObject:parameter2];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter3) {
                [parameters addObject:parameter3];
            } else {
                [parameters addObject:[NSNull null]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAPICalled:NSStringFromSelector(apiName) stackTrace:stackTrace isExternal:true objects:parameters];
            });
        }
    }
}

- (void)onAPICalled:(SEL)apiName parameter1:(nullable NSObject *)parameter1 parameter2:(nullable NSObject *)parameter2 parameter3:(nullable NSObject *)parameter3 parameter4:(nullable NSObject *)parameter4 {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAPICalled:stackTrace:isExternal:objects:)]) {
            NSArray *stackTrace = [NSThread callStackSymbols];
            NSMutableArray *parameters = [NSMutableArray array];
            if (parameter1) {
                [parameters addObject:parameter1];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter2) {
                [parameters addObject:parameter2];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter3) {
                [parameters addObject:parameter3];
            } else {
                [parameters addObject:[NSNull null]];
            }
            if (parameter4) {
                [parameters addObject:parameter4];
            } else {
                [parameters addObject:[NSNull null]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAPICalled:NSStringFromSelector(apiName) stackTrace:stackTrace isExternal:true objects:parameters];
            });
        }
    }
}

- (void)onEntityStored:(MPDatabaseTable)tableName primaryKey:(nonnull NSNumber *)primaryKey message:(nonnull NSString *)message {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onEntityStored:primaryKey:message:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onEntityStored:tableName primaryKey:primaryKey message:message];
            });
        }
    }
}

- (void)onNetworkRequestStarted:(MPEndpoint)type url:(nonnull NSString *)url body:(nonnull NSObject *)body {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onNetworkRequestStarted:url:body:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onNetworkRequestStarted:type url:url body:body];
            });
        }
    }
}

- (void)onNetworkRequestFinished:(MPEndpoint)type url:(nonnull NSString *)url body:(nonnull NSObject *)body responseCode:(NSInteger)responseCode {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onNetworkRequestFinished:url:body:responseCode:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onNetworkRequestFinished:type url:url body:body responseCode:responseCode];
            });
        }
    }
}

- (void)onKitApiCalled:(nonnull NSString *)methodName kitId:(int)kitId used:(BOOL)used objects:(nonnull NSArray *)objects {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onKitApiCalled:kitId:used:objects:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onKitApiCalled:methodName kitId:kitId used:used objects:objects];
            });
        }
    }
}

- (void)onKitDetected:(int)kitId {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onKitDetected:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onKitDetected:kitId];
            });
        }
    }
}

- (void)onKitConfigReceived:(int)kitId configuration:(nonnull NSDictionary *)configuration {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onKitConfigReceived:configuration:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onKitConfigReceived:kitId configuration:configuration];
            });
        }
    }
}

- (void)onKitStarted:(int)kitId {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onKitStarted:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onKitStarted:kitId];
            });
        }
    }
}

- (void)onKitExcluded:(int)kitId reason:(nonnull NSString *)reason {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onKitExcluded:reason:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onKitExcluded:kitId reason:reason];
            });
        }
    }
}

- (void)onSessionUpdated:(nullable MParticleSession *)session {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onSessionUpdated:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onSessionUpdated:session];
            });
        }
    }
}

- (void)onAliasRequestFinished:(nullable MPAliasResponse *)aliasResponse {
    for (id<MPListenerProtocol>delegate in self.sdkListeners) {
        if ([delegate respondsToSelector:@selector(onAliasRequestFinished:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onAliasRequestFinished:aliasResponse];
            });
        }
    }
}

@end
