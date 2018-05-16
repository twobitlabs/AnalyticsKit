#import "MPKitActivity.h"
#import "MPEnums.h"
#import "MPExtensionProtocol.h"
#import "MPKitContainer.h"
#import "MPKitProtocol.h"
#import "MPKitRegister.h"

#pragma mark - MPKitActivityMapping
@interface MPKitActivityMapping : NSObject

@property (nonatomic, strong, readonly) NSNumber *kitCode;
@property (nonatomic, copy, readonly) void (^handler)(id kitInstance);

- (instancetype)initWithKitCode:(NSNumber *)kitCode handler:(void (^)(id kitInstance))handler;

@end

@implementation MPKitActivityMapping

- (instancetype)initWithKitCode:(NSNumber *)kitCode handler:(void (^)(id kitInstance))handler {
    self = [super init];
    if (self) {
        _kitCode = kitCode;
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
- (void)kitInstanceAndConfiguration:(NSNumber *)kitCode handler:(void(^)(id instance, NSDictionary *configuration))handler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol> kitRegister = [[[[MPKitContainer sharedInstance] activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    id<MPKitProtocol> wrapperInstance = kitRegister.wrapperInstance;
    
    id kitInstance = [wrapperInstance respondsToSelector:@selector(providerKitInstance)] ? [wrapperInstance providerKitInstance] : nil;
    NSDictionary *kitConfiguration = [wrapperInstance respondsToSelector:@selector(configuration)] ? [wrapperInstance configuration] : nil;

    handler(kitInstance, kitConfiguration);
}

#pragma mark Public methods
- (BOOL)isKitActive:(nonnull NSNumber *)kitCode {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol> kitRegister = [[[[MPKitContainer sharedInstance] activeKitsRegistry] filteredArrayUsingPredicate:predicate] firstObject];
    
    return kitRegister != nil;
}

- (nullable id)kitInstance:(nonnull NSNumber *)kitCode {
    __block id kitInstance = nil;
    
    [self kitInstanceAndConfiguration:kitCode handler:^(id instance, NSDictionary *configuration) {
        kitInstance = instance;
    }];
    
    return kitInstance;
}

- (void)kitInstance:(nonnull NSNumber *)kitCode withHandler:(void (^ _Nonnull)(id _Nullable kitInstance))handler {
    __block id kitInstance = nil;
    __block NSDictionary *kitConfiguration = nil;
    
    [self kitInstanceAndConfiguration:kitCode handler:^(id instance, NSDictionary *configuration) {
        kitInstance = instance;
        kitConfiguration = configuration;
    }];
    
    if (kitInstance) {
        handler(kitInstance);
    } else {
        MPKitActivityMapping *activityMapping = [[MPKitActivityMapping alloc] initWithKitCode:kitCode handler:handler];
        [self.activityMappings addObject:activityMapping];
    }
}

#pragma mark Notification handlers
- (void)handleKitDidBecomeActive:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *kitCode = userInfo[mParticleKitInstanceKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kitCode == %@", kitCode];
    NSArray *activities = [self.activityMappings filteredArrayUsingPredicate:predicate];
    
    if (activities.count == 0) {
        return;
    }
    
    for (MPKitActivityMapping *activityMapping in activities) {
        [self kitInstanceAndConfiguration:activityMapping.kitCode
                                  handler:^(id instance, NSDictionary *configuration) {
                                      activityMapping.handler(instance);
                                  }];
    }
}

@end
