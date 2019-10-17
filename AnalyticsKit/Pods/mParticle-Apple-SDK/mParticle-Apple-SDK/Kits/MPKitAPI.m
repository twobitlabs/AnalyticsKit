#import "MPKitAPI.h"
#import "MPPersistenceController.h"
#import "MPIntegrationAttributes.h"
#import "MPKitContainer.h"
#import "MPILogger.h"
#import "FilteredMParticleUser.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPKitContainer *kitContainer;

@end

@interface MPAttributionResult ()

@property (nonatomic, readwrite) NSNumber *kitCode;
@property (nonatomic, readwrite) NSString *kitName;

@end

@interface MPKitContainer ()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

@end

@interface MPKitAPI ()

@property (nonatomic) NSNumber *kitCode;

@end

@implementation MPKitAPI

- (NSString *)kitName {
    __block NSString *component = nil;
    NSSet<id<MPExtensionKitProtocol>> *kits = [MPKitContainer registeredKits];
    NSNumber *kitCode = _kitCode;
    
    if (kits && kitCode) {
        [kits enumerateObjectsUsingBlock:^(id<MPExtensionKitProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.code.intValue == self->_kitCode.intValue) {
                component = obj.name;
            }
        }];
    }
    
    return component;
}

- (NSString *)logMessageWithFormat:(NSString *)format withParameters:(va_list)valist {
    NSString *formattedOriginalMessage = [[NSString alloc] initWithFormat:format arguments:valist];
    NSString *kitName = [self kitName];
    NSString *prefixedMessage = [NSString stringWithFormat:@"%@ Kit: %@", kitName, formattedOriginalMessage];
    return prefixedMessage;
}

- (void)logError:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogError(@"%@", formattedMessage);
    va_end(args);
}

- (void)logWarning:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogWarning(@"%@", formattedMessage);
    va_end(args);
}

- (void)logDebug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogDebug(@"%@", formattedMessage);
    va_end(args);
}

- (void)logVerbose:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogVerbose(@"%@", formattedMessage);
    va_end(args);
}

- (id)initWithKitCode:(NSNumber *)kitCode {
    self = [super init];
    if (self) {
        _kitCode = kitCode;
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)integrationAttributes {
    NSDictionary *dictionary = [[MParticle sharedInstance].kitContainer integrationAttributesForKit:_kitCode];
    return dictionary;
}

- (void)onAttributionCompleteWithResult:(MPAttributionResult *)result error:(NSError *)error {
    if (error || !result) {
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (_kitCode != nil) {
            userInfo[mParticleKitInstanceKey] = _kitCode;
        }
        
        NSString *errorMessage = nil;
        
        if (error) {
            errorMessage = @"mParticle Kit Attribution Error";
            userInfo[NSUnderlyingErrorKey] = error;
        }
        
        if (!result) {
            errorMessage = @"mParticle Kit Attribution handler was called with nil info and no error";
        }
        
        userInfo[MPKitAPIErrorKey] = errorMessage;
        NSError *attributionError = [NSError errorWithDomain:MPKitAPIErrorDomain code:0 userInfo:userInfo];
        [MParticle sharedInstance].kitContainer.attributionCompletionHandler(nil, attributionError);
        return;
    }
    
    result.kitCode = _kitCode;
    result.kitName = [self kitName];
    
    [MParticle sharedInstance].kitContainer.attributionCompletionHandler(result, nil);
}

#pragma mark Kit Identity methods

- (FilteredMParticleUser *_Nonnull)getCurrentUserWithKit:(id<MPKitProtocol> _Nonnull)kit {
    return [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:[MParticle sharedInstance].kitContainer.kitConfigurations[[[kit class] kitCode]]];
}

- (nullable NSNumber *)incrementUserAttribute:(NSString *_Nonnull)key byValue:(NSNumber *_Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    return [selectedUser incrementUserAttribute:key byValue:value];
}

- (void)setUserAttribute:(NSString *_Nonnull)key value:(id _Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    [selectedUser setUserAttribute:key value:value];
}

- (void)setUserAttributeList:(NSString *_Nonnull)key values:(NSArray<NSString *> *_Nonnull)values forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser setUserAttributeList:key values:values];
    
}

- (void)setUserTag:(NSString *_Nonnull)tag forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser setUserTag:tag];
}

- (void)removeUserAttribute:(NSString *_Nonnull)key forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser removeUserAttribute:key];
}

@end
