#import "MPEvent.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "EventTypeName.h"
#import "MPILogger.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"

@interface MPEvent()

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlagsDictionary;
@property (nonatomic, unsafe_unretained) MPMessageType messageType;

@end


@implementation MPEvent

@synthesize messageType = _messageType;

- (instancetype)init {
    MPILogError(@"%@ should NOT be initialized using the standard initializer.", [self class]);
    return [self initWithName:@"<<Event With No Name>>" type:MPEventTypeOther];
}

- (instancetype)initWithName:(NSString *)name type:(MPEventType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (!name || name.length == 0) {
        MPILogError(@"'name' is required for MPEvent")
        return nil;
    }
    
    if (name.length > LIMIT_NAME) {
        MPILogError(@"The event name is too long.");
        return nil;
    }
    
    _info = nil;
    _endTime = nil;
    _name = name;
    _startTime = nil;
    _duration = @0;
    self.type = type;

    return self;
}

- (NSString *)description {
    NSString *nameAndType = [[NSString alloc] initWithFormat:@"Event:{\n  Name: %@\n  Type: %@\n", self.name, self.typeName];
    NSMutableString *description = [[NSMutableString alloc] initWithString:nameAndType];
    
    if (self.info) {
        [description appendFormat:@"  Info: %@\n", self.info];
    }
    
    if (self.duration) {
        [description appendFormat:@"  Duration: %@\n", self.duration];
    }
    
    if (_customFlagsDictionary.count > 0) {
        [description appendFormat:@"  Custom Flags: %@\n", _customFlagsDictionary];
    }
    
    [description appendString:@"}"];
    
    return description;
}

- (BOOL)isEqual:(MPEvent *)object {
    BOOL isEqual = _type == object.type &&
                   [_name isEqualToString:object.name] &&
                   [_info isEqualToDictionary:object.info] &&
                   [_duration isEqualToNumber:object.duration];
    
    if (isEqual) {
        if (_category && object.category) {
            isEqual = [_category isEqualToString:object.category];
        } else if (_category || object.category) {
            isEqual = NO;
        }
    }
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPEvent *copyObject = [[MPEvent alloc] initWithName:[_name copy] type:_type];
    
    if (copyObject) {
        copyObject.duration = [_duration copy];
        copyObject.endTime = [_endTime copy];
        copyObject.info = [_info copy];
        copyObject.startTime = [_startTime copy];
        copyObject.category = [_category copy];
        copyObject.messageType = _messageType;
        copyObject.customFlagsDictionary = [_customFlagsDictionary mutableCopy];
        copyObject->_timestamp = [_timestamp copy];
    }
    
    return copyObject;
}

#pragma mark MPEvent+MessageType
- (MPMessageType)messageType {
    return _messageType;
}

- (void)setMessageType:(MPMessageType)messageType {
    _messageType = messageType;
}

#pragma mark Private accessors
- (NSMutableDictionary *)customFlagsDictionary {
    if (_customFlagsDictionary) {
        return _customFlagsDictionary;
    }
    
    _customFlagsDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _customFlagsDictionary;
}

#pragma mark Public accessors
- (void)setCategory:(NSString *)category {
    if (category.length <= LIMIT_NAME) {
        _category = category;
    } else {
        MPILogError(@"The category length is too long. Discarding category.");
        _category = nil;
    }
}

- (NSDictionary *)customFlags {
    return (NSDictionary *)_customFlagsDictionary;
}

- (void)setInfo:(NSDictionary *)info {
    if (_info && info && [_info isEqualToDictionary:info]) {
        return;
    }
    
    NSUInteger numberOfEntries = info.count;
    
    NSAssert(numberOfEntries <= LIMIT_ATTR_COUNT, @"Event info has more than 100 key/value pairs.");

    if (numberOfEntries > LIMIT_ATTR_COUNT) {
        MPILogError(@"Number of attributes exceeds the maximum number of attributes allowed per event. Discarding attributes.");
        return;
    }
    
    if (numberOfEntries > 0) {
        __block BOOL respectsConstraints = YES;
        
        if ([info isKindOfClass:[NSDictionary class]]) {
            [info enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > LIMIT_ATTR_LENGTH) {
                    respectsConstraints = NO;
                    *stop = YES;
                }
                
                if (key.length > LIMIT_NAME) {
                    respectsConstraints = NO;
                    *stop = YES;
                }
            }];
            
            if (respectsConstraints) {
                _info = info;
            }
        } else if ([info isKindOfClass:[MPProduct class]]) {
            _info = [(MPProduct *)info dictionaryRepresentation];
        }
    } else {
        _info = nil;
    }
}

- (void)setName:(NSString *)name {
    if (name.length == 0) {
        MPILogError(@"'name' cannot be nil or empty.")
        return;
    }
    
    if (name.length > LIMIT_NAME) {
        MPILogError(@"The event name is too long.");
        return;
    }
    
    if (![_name isEqualToString:name]) {
        _name = name;
    }
}

- (void)setType:(MPEventType)type {
    if (_type == type) {
        return;
    }
    
    if (type < MPEventTypeNavigation || type > MPEventTypeOther) {
        MPILogWarning(@"An invalid event type was provided. Will default to 'MPEventTypeOther'");
        _type = MPEventTypeOther;
    } else {
        _type = type;
    }
    
    _typeName = nil;
}

- (NSString *)typeName {
    if (_typeName) {
        return _typeName;
    }
    
    [self willChangeValueForKey:@"typeName"];
    
    mParticle::EventType eventType = static_cast<mParticle::EventType>(_type);
    
    _typeName = [NSString stringWithCString:mParticle::EventTypeName::nameForEventType(eventType).c_str()
                                   encoding:NSUTF8StringEncoding];
    
    [self didChangeValueForKey:@"typeName"];
    
    return _typeName;
}

#pragma mark Public methods
- (void)addCustomFlag:(NSString *)customFlag withKey:(NSString *)key {
    if (MPIsNull(customFlag)) {
        MPILogError(@"'customFlag' cannot be nil or null.");
        return;
    }
    
    if (MPIsNull(key)) {
        MPILogError(@"'key' cannot be nil or null.");
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
    
    NSMutableArray<NSString *> *flags = self.customFlagsDictionary[key];
    if (!flags) {
        flags = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    [flags addObjectsFromArray:customFlags];
    self.customFlagsDictionary[key] = flags;
}

@end
