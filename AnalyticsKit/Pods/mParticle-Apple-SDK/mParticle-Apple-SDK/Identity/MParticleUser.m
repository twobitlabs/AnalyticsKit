//
//  MParticleUser.m
//

#import "MParticleUser.h"
#import "MPBackendController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPILogger.h"
#import "mParticle.h"
#import "MPUserSegments.h"
#import "MPUserSegments+Setters.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"

@interface MParticleUser () {
    MPConsentState *_consentState;
}

@property (nonatomic, strong) MPBackendController *backendController;


@end

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPBackendController *backendController;

@end

@interface MPCart ()

- (nonnull instancetype)initWithUserId:(NSNumber *_Nonnull)userId;

@end

@implementation MParticleUser

@synthesize cart = _cart;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backendController = [MParticle sharedInstance].backendController;
    }
    return self;
}

-(MPCart *)cart {
    if (_cart) {
        return _cart;
    }
    _cart = [[MPCart alloc] initWithUserId:self.userId];
    return _cart;
}

-(NSDictionary*) userIdentities {
    NSMutableArray *userIdentitiesArray = [[NSMutableArray alloc] initWithCapacity:10];
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSArray *userIdentityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:_userId];
    if (userIdentityArray) {
        [userIdentitiesArray addObjectsFromArray:userIdentityArray];
    }
    
    NSMutableDictionary *userIdentities = [NSMutableDictionary dictionary];
    [userIdentitiesArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *identity = obj[@"i"];
        NSNumber *type = obj[@"n"];
        [userIdentities setObject:identity forKey:type];
    }];
    return userIdentities;
}

-(NSDictionary*) userAttributes
{
    return [[MParticle sharedInstance].backendController userAttributesForUserId:self.userId];
}

-(void) setUserAttributes:(NSDictionary *)userAttributes
{
    NSDictionary<NSString *, id> *existingUserAttributes = self.userAttributes;
    [existingUserAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self removeUserAttribute:key];
    }];
    
    [userAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull valueOrValues, BOOL * _Nonnull stop) {
        if ([valueOrValues isKindOfClass:[NSArray class]]) {
            NSArray *values = valueOrValues;
            [self setUserAttributeList:key values:values];
        }
        else {
            id value = valueOrValues;
            [self setUserAttribute:key value:value];
        }
    }];
}

- (void)setUserId:(NSNumber *)userId {
    _userId = userId;
    _cart = [[MPCart alloc] initWithUserId:userId];
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController setUserIdentity:identityString
                                   identityType:identityType
                                      timestamp:timestamp
                              completionHandler:^(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                  
                                  if (execStatus == MPExecStatusSuccess) {
                                      MPILogDebug(@"Set user identity: %@", identityString);
                                      
                                      // Forwarding calls to kits
                                      [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserIdentity:identityType:)
                                                                         userIdentity:identityString
                                                                         identityType:identityType
                                                                           kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                               [kit setUserIdentity:identityString identityType:identityType];
                                                                           }];
                                  }
                              }];
    });
}

- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    dispatch_async([MParticle messageQueue], ^{
        
        MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
        if (stateMachine.optOut) {
            return;
        }
        
        NSNumber *newValue = [self.backendController incrementUserAttribute:key byValue:value];
        
        MPILogDebug(@"User attribute %@ incremented by %@. New value: %@", key, value, newValue);
        
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(incrementUserAttribute:byValue:)
                                       userAttributeKey:key
                                                  value:value
                                             kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                 FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:self kitConfiguration:kitConfig];
                                                 
                                                 if ([kit respondsToSelector:@selector(incrementUserAttribute:byValue:)]) {
                                                     [kit incrementUserAttribute:key byValue:value];
                                                 }
                                                 if ([kit respondsToSelector:@selector(onIncrementUserAttribute:)] && filteredUser != nil) {
                                                     [kit onIncrementUserAttribute:filteredUser];
                                                 }
                                             }];
        
        [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                       userAttributeKey:key
                                                  value:newValue
                                             kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                 if (![kit respondsToSelector:@selector(incrementUserAttribute:byValue:)]) {
                                                     FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:self kitConfiguration:kitConfig];
                                                     
                                                     if ([kit respondsToSelector:@selector(setUserAttribute:value:)]) {
                                                         [kit setUserAttribute:key value:newValue];
                                                     }
                                                     if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                                         [kit onSetUserAttribute:filteredUser];
                                                     }
                                                 }
                                             }];
    });
    
    return @0;
}

- (void)setUserAttribute:(nonnull NSString *)key value:(nonnull id)value {
    if ([value isKindOfClass:[NSString class]] && (((NSString *)value).length <= 0)) {
        MPILogDebug(@"User attribute not updated. Please use removeUserAttribute.");
        
        return;
    }
    
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        
        [self.backendController setUserAttribute:key
                                           value:value
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       if (value) {
                                           MPILogDebug(@"Set user attribute - %@:%@", key, value);
                                       } else {
                                           MPILogDebug(@"Reset user attribute - %@", key);
                                       }
                                       
                                       // Forwarding calls to kits
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                                                      userAttributeKey:key
                                                                                 value:value
                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                                                
                                                                                [kit setUserAttribute:key value:value];
                                                                                if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                                                                    [kit onSetUserAttribute:filteredUser];
                                                                                }
                                                                            }];
                                   }
                               }];
    });
}

- (void)setUserAttributeList:(nonnull NSString *)key values:(nonnull NSArray<NSString *> *)values {
    if (values.count == 0) {
        MPILogDebug(@"User attribute not updated. Please use removeUserAttribute.");
        
        return;
    }

    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController setUserAttribute:key
                                          values:values
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, NSArray *values, MPExecStatus execStatus) {
                                   
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       if (values) {
                                           MPILogDebug(@"Set user attribute values - %@:%@", key, values);
                                       } else {
                                           MPILogDebug(@"Reset user attribute - %@", key);
                                       }
                                       
                                       // Forwarding calls to kits
                                       SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
                                       SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
                                       
                                       [[MPKitContainer sharedInstance] forwardSDKCall:setUserAttributeListSelector
                                                                      userAttributeKey:key
                                                                                 value:values
                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                                                if ([kit respondsToSelector:setUserAttributeListSelector]) {
                                                                                    [kit setUserAttribute:key values:values];
                                                                                } else if ([kit respondsToSelector:setUserAttributeSelector]) {
                                                                                    NSString *csvValues = [values componentsJoinedByString:@","];
                                                                                    [kit setUserAttribute:key value:csvValues];
                                                                                } else if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                                                                    [kit onSetUserAttribute:filteredUser];
                                                                                }
                                                                            }];
                                   }
                               }];
    });
}

- (void)setUserTag:(nonnull NSString *)tag {
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController setUserAttribute:tag
                                           value:nil
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       MPILogDebug(@"Set user tag - %@", tag);
                                       
                                       // Forwarding calls to kits
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserTag:)
                                                                      userAttributeKey:tag
                                                                                 value:nil
                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                                                
                                                                                [kit setUserTag:tag];
                                                                                if ([kit respondsToSelector:@selector(onSetUserTag:)] && filteredUser != nil) {
                                                                                    [kit onSetUserTag:filteredUser];
                                                                                }
                                                                            }];
                                   }
                               }];
    });
}

- (void)removeUserAttribute:(nonnull NSString *)key {
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController removeUserAttribute:key
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                                   
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       MPILogDebug(@"Removed user attribute - %@", key);
                                       
                                       // Forwarding calls to kits
                                       [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                                      userAttributeKey:key
                                                                                 value:nil
                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                                                
                                                                                [kit removeUserAttribute:key];
                                                                                if ([kit respondsToSelector:@selector(onRemoveUserAttribute:)] && filteredUser != nil) {
                                                                                    [kit onRemoveUserAttribute:filteredUser];
                                                                                }
                                                                            }];
                                   }
                           }];
    });
}

#pragma mark - User Segments
- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler {
    dispatch_async([MParticle messageQueue], ^{
        MPExecStatus execStatus = [self.backendController fetchSegments:timeout
                                                             endpointId:endpointId
                                                      completionHandler:^(NSArray *segments, NSTimeInterval elapsedTime, NSError *error) {
                                                          if (!segments) {
                                                              completionHandler(nil, error);
                                                              return;
                                                          }
                                                          
                                                          MPUserSegments *userSegments = [[MPUserSegments alloc] initWithSegments:segments];
                                                          completionHandler(userSegments, error);
                                                      }];
        
        if (execStatus == MPExecStatusSuccess) {
            MPILogDebug(@"Fetching user segments");
        } else {
            MPILogError(@"Could not fetch user segments: %@", [self.backendController execStatusDescription:execStatus]);
        }
    });
}

#pragma mark - Consent State

- (void)setConsentState:(MPConsentState *)state {
    [MPPersistenceController setConsentState:state forMpid:self.userId];
}

- (nullable MPConsentState *)consentState {
    return [MPPersistenceController consentStateForMpid:self.userId];
}


@end
