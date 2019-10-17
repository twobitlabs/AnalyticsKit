#import "MPKitActivity.h"
#import "MPEnums.h"
#import "MPExtensionProtocol.h"
#import "MPKitContainer.h"
#import "MPKitProtocol.h"
#import "MPKitRegister.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPKitContainer *kitContainer;

@end

#pragma mark - MPKitActivityMapping
@interface MPKitActivityMapping : NSObject

@property (nonatomic, strong, readonly) NSNumber *integrationId;
@property (nonatomic, copy, readonly) void (^handler)(id kitInstance);

- (instancetype)initWithKitCode:(NSNumber *)integrationId handler:(void (^)(id kitInstance))handler;

@end

@implementation MPKitActivityMapping

- (instancetype)initWithKitCode:(NSNumber *)integrationId handler:(void (^)(id kitInstance))handler {
    self = [super init];
    if (self) {
        _integrationId = integrationId;
        _handler = handler;
    }
    
    return self;
}

@end


#pragma - MPKitActivity
@interface MPKitActivity()

@property (nonatomic, strong) NSMutableArray<MPKitActivityMapping *> *activityMappings;

@end


@implementation MPKitActivity

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKitDidBecomeActive:)
                                                     name:mParticleKitDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:mParticleKitDidBecomeActiveNotification
                                                  object:nil];
}

#pragma mark Private accessors
- (NSMutableArray<MPKitActivityMapping *> *)activityMappings {
    if (!_activityMappings) {
        _activityMappings = [[NSMutableArray alloc] initWithCapacity:2];
    }
    
    return _activityMappings;
}

#pragma mark Private methods
- (void)kitInstanceAndConfiguration:(NSNumber *)integrationId handler:(void(^)(id instance, NSDictionary *configuration))handler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol> kitRegister = [[[[MParticle sharedInstance].kitContainer activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    id<MPKitProtocol> wrapperInstance = kitRegister.wrapperInstance;
    
    id kitInstance = [wrapperInstance respondsToSelector:@selector(providerKitInstance)] ? [wrapperInstance providerKitInstance] : nil;
    NSDictionary *kitConfiguration = [wrapperInstance respondsToSelector:@selector(configuration)] ? [wrapperInstance configuration] : nil;

    handler(kitInstance, kitConfiguration);
}

#pragma mark Public methods
- (BOOL)isKitActive:(nonnull NSNumber *)integrationId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol> kitRegister = [[[[MParticle sharedInstance].kitContainer activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    
    return kitRegister != nil;
}

- (nullable id)kitInstance:(nonnull NSNumber *)integrationId {
    __block id kitInstance = nil;
    
    [self kitInstanceAndConfiguration:integrationId handler:^(id instance, NSDictionary *configuration) {
        kitInstance = instance;
    }];
    
    return kitInstance;
}

- (void)kitInstance:(nonnull NSNumber *)integrationId withHandler:(void (^ _Nonnull)(id _Nullable kitInstance))handler {
    __block id kitInstance = nil;
    __block NSDictionary *kitConfiguration = nil;
    
    [self kitInstanceAndConfiguration:integrationId handler:^(id instance, NSDictionary *configuration) {
        kitInstance = instance;
        kitConfiguration = configuration;
    }];
    
    if (kitInstance) {
        handler(kitInstance);
    } else {
        MPKitActivityMapping *activityMapping = [[MPKitActivityMapping alloc] initWithKitCode:integrationId handler:handler];
        [self.activityMappings addObject:activityMapping];
    }
}

#pragma mark Notification handlers
- (void)handleKitDidBecomeActive:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *integrationId = userInfo[mParticleKitInstanceKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"integrationId == %@", integrationId];
    NSArray *activities = [self.activityMappings filteredArrayUsingPredicate:predicate];
    
    if (activities.count == 0) {
        return;
    }
    
    for (MPKitActivityMapping *activityMapping in activities) {
        [self kitInstanceAndConfiguration:activityMapping.integrationId
                                  handler:^(id instance, NSDictionary *configuration) {
                                      activityMapping.handler(instance);
                                  }];
    }
}

@end
