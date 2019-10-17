#import "MPBaseEvent.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "mParticle.h"
#import "MPILogger.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

@implementation MPBaseEvent

- (instancetype)init {
    return [self initWithEventType:MPEventTypeOther];
}

- (instancetype)initWithEventType:(MPEventType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _timestamp = [NSDate date];
    _messageType = MPMessageTypeUnknown;
    _customAttributes = nil;
    _customFlags = nil;
    self.type = type;
    
    return self;
}

- (void)setCustomAttributes:(NSDictionary<NSString *,id> *)attributes {
    if (_customAttributes && attributes && [_customAttributes isEqualToDictionary:attributes]) {
        return;
    }
    
    NSUInteger numberOfEntries = attributes.count;
    
    NSAssert(numberOfEntries <= LIMIT_ATTR_COUNT, @"Event info has more than 100 key/value pairs.");
    
    if (numberOfEntries > LIMIT_ATTR_COUNT) {
        MPILogError(@"Number of attributes exceeds the maximum number of attributes allowed per event. Discarding attributes.");
        return;
    }
    
    if (([attributes isKindOfClass:[NSDictionary<NSString *,id> class]]) && (numberOfEntries > 0)) {
        __block BOOL respectsConstraints = YES;
        
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > LIMIT_ATTR_VALUE_LENGTH) {
                respectsConstraints = NO;
                *stop = YES;
            }
            
            if (key.length > LIMIT_ATTR_KEY_LENGTH) {
                respectsConstraints = NO;
                *stop = YES;
            }
        }];
        
        if (respectsConstraints) {
            _customAttributes = attributes;
        }
    } else {
        _customAttributes = nil;
    }
}

- (void)setType:(MPEventType)type {
    if (_type == type) {
        return;
    }
    
    if (type < MPEventTypeNavigation || type > MPEventTypeMedia) {
        MPILogWarning(@"An invalid event type was provided. Will default to 'MPEventTypeOther'");
        _type = MPEventTypeOther;
    } else {
        _type = type;
    }
}

- (NSString *)typeName {
    return NSStringFromEventType(_type);
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    MPILogError(@"You must override dictionaryRepresentation in this subclass %@", NSStringFromClass([self class]));
    
    return @{};
}

- (void)addCustomFlag:(NSString *)customFlag withKey:(NSString *)key {
    if (MPIsNull(customFlag)) {
        MPILogError(@"'customFlag' cannot be nil or null.");
        return;
    }
    
    [self addCustomFlags:@[customFlag] withKey:key];
}

- (void)addCustomFlags:(nonnull NSArray<NSString *> *)customFlags withKey:(nonnull NSString *)key {
    if (MPIsNull(customFlags)) {
        MPILogError(@"'customFlags' cannot be nil or null.");
        return;
    }
    
    if (MPIsNull(key)) {
        MPILogError(@"'key' cannot be nil or null.");
        return;
    }
    
    BOOL validDataType = [customFlags isKindOfClass:[NSArray class]];
    NSAssert(validDataType, @"'customFlags' must be of type NSArray or an instance of a class inheriting from NSArray.");
    if (!validDataType) {
        MPILogError(@"'customFlags' must be of type NSArray or an instance of a class inheriting from NSArray.");
        return;
    }
    
    for (id item in customFlags) {
        validDataType = [item isKindOfClass:[NSString class]];
        NSAssert(validDataType, @"'customFlags' array items must be of type NSString or an instance of a class inheriting from NSString.");
        if (!validDataType) {
            MPILogError(@"'customFlags' array items must be of type NSString or an instance of a class inheriting from NSString.");
            return;
        }
    }
    
    NSMutableArray<NSString *> *flags = self.customFlags[key];
    if (!flags) {
        flags = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    [flags addObjectsFromArray:customFlags];
    
    if (!_customFlags) {
        _customFlags = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    self.customFlags[key] = flags;
}

#pragma mark NSObject
- (BOOL)isEqual:(MPEvent *)object {
    return (self.type == object.type) && [self.customAttributes isEqualToDictionary:object.customAttributes];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPBaseEvent *copyObject = [[[self class] allocWithZone:zone] init];
    
    if (copyObject) {
        copyObject.type = _type;
        copyObject.customAttributes = [_customAttributes copy];
        copyObject.messageType = _messageType;
        copyObject.timestamp = [_timestamp copy];
        
        for (NSString *key in [_customFlags allKeys]) {
            [copyObject addCustomFlags:[_customFlags[key] copy] withKey:[key copy]];
        }
    }
    
    return copyObject;
}

@end
