#import "MPEvent.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPILogger.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MParticle.h"

@interface MParticle()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;

@end

NSString *const kMPEventCategoryKey = @"$Category";
NSString *const kMPAttrsEventLengthKey = @"EventLength";

@implementation MPEvent

@synthesize messageType = _messageType;

- (instancetype)init {
    return [self initWithEventType:MPEventTypeOther];
}

- (instancetype)initWithEventType:(MPEventType)type {
    return [self initWithName:@"<<Event With No Name>>" type:type];
}

- (instancetype)initWithName:(NSString *)name type:(MPEventType)type {
    self = [super initWithEventType:type];
    if (!self) {
        return nil;
    }
    
    if (!name || name.length == 0) {
        MPILogError(@"'name' is required for MPEvent")
        return nil;
    }
    
    if (name.length > LIMIT_ATTR_KEY_LENGTH) {
        MPILogError(@"The event name is too long.");
        return nil;
    }
    
    _endTime = nil;
    _name = name;
    _startTime = nil;
    _duration = @0;
    _messageType = MPMessageTypeEvent;

    return self;
}

- (NSString *)description {
    NSString *nameAndType = [[NSString alloc] initWithFormat:@"Event:{\n  Name: %@\n  Type: %@\n", self.name, self.typeName];
    NSMutableString *description = [[NSMutableString alloc] initWithString:nameAndType];
    
    if (self.customAttributes) {
        [description appendFormat:@"  Attributes: %@\n", self.customAttributes];
    }
    
    if (self.duration != nil) {
        [description appendFormat:@"  Duration: %@\n", self.duration];
    }
    
    if (self.customFlags.count > 0) {
        [description appendFormat:@"  Custom Flags: %@\n", self.customFlags];
    }
    
    [description appendString:@"}"];
    
    return description;
}

#pragma mark NSObject
- (BOOL)isEqual:(MPEvent *)object {
    BOOL isEqual = [super isEqual:object] &&
                    [_name isEqualToString:object.name] &&
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
    MPEvent *copyObject = [super copyWithZone:zone];
    
    if (copyObject) {
        copyObject.name = [_name copy];
        copyObject.duration = [_duration copy];
        copyObject.endTime = [_endTime copy];
        copyObject.startTime = [_startTime copy];
        copyObject.category = [_category copy];
    }
    
    return copyObject;
}

#pragma mark Public accessors
- (void)setCategory:(NSString *)category {
    if (category.length <= LIMIT_ATTR_VALUE_LENGTH) {
        _category = category;
    } else {
        MPILogError(@"The category length is too long. Discarding category.");
        _category = nil;
    }
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *eventDictionary = [@{kMPEventNameKey:self.name,
                                                              kMPEventTypeKey:self.typeName,
                                                              kMPEventCounterKey:@([MParticle sharedInstance].stateMachine.currentSession.eventCounter)}
                                                            mutableCopy];
    
    NSDictionary *info = self.customAttributes;
    NSString *category = self.category;
    NSInteger numberOfItems = (info ? info.count : 0) + (category ? 1 : 0);
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:numberOfItems];
    
    if (self.duration != nil) {
        eventDictionary[kMPEventLength] = self.duration;
        
        if (!info || info[kMPAttrsEventLengthKey] == nil) { // Does not override "EventLength" if it already exists
            attributes[kMPAttrsEventLengthKey] = self.duration;
        }
    } else {
        eventDictionary[kMPEventLength] = @0;
    }
    
    if (self.startTime) {
        eventDictionary[kMPEventStartTimestamp] = MPMilliseconds([self.startTime timeIntervalSince1970]);
    } else {
        eventDictionary[kMPEventStartTimestamp] = MPCurrentEpochInMilliseconds;
    }
    
    if (numberOfItems > 0) {
        if (info) {
            [attributes addEntriesFromDictionary:info];
        }
        
        if (category) {
            if (category.length <= LIMIT_ATTR_VALUE_LENGTH) {
                attributes[kMPEventCategoryKey] = category;
            } else {
                MPILogError(@"The event category is too long. Discarding category.");
            }
        }
    }
    
    if (attributes.count > 0) {
        eventDictionary[kMPAttributesKey] = attributes;
    }
    
    if (self.customFlags) {
        eventDictionary[kMPEventCustomFlags] = self.customFlags;
    }
    
    return eventDictionary;
}

- (NSDictionary *)info {
    return [self.customAttributes copy];
}

- (void)setInfo:(NSDictionary *)info {
    self.customAttributes = info;
}

- (void)setName:(NSString *)name {
    if (name.length == 0) {
        MPILogError(@"'name' cannot be nil or empty.")
        return;
    }
    
    if (name.length > LIMIT_ATTR_KEY_LENGTH) {
        MPILogError(@"The event name is too long.");
        return;
    }
    
    if (![_name isEqualToString:name]) {
        _name = name;
    }
}

#pragma mark Public category methods
- (void)beginTiming {
    self.startTime = [NSDate date];
    self.duration = nil;
    
    if (self.endTime) {
        self.endTime = nil;
    }
}

- (NSDictionary *)breadcrumbDictionaryRepresentation {
    NSMutableDictionary *eventDictionary = [@{kMPLeaveBreadcrumbsKey:self.name,
                                              kMPEventStartTimestamp:MPCurrentEpochInMilliseconds}
                                            mutableCopy];
    
    if (self.customAttributes) {
        eventDictionary[kMPAttributesKey] = self.customAttributes;
    }
    
    return eventDictionary;
}

- (void)endTiming {
    [self willChangeValueForKey:@"endTime"];
    
    if (self.startTime) {
        self.endTime = [NSDate date];
        
        NSTimeInterval secondsElapsed = [self.endTime timeIntervalSince1970] - [self.startTime timeIntervalSince1970];
        self.duration = MPMilliseconds(secondsElapsed);
    } else {
        self.duration = nil;
        self.endTime = nil;
    }
    
    [self didChangeValueForKey:@"endTime"];
}

- (NSDictionary *)screenDictionaryRepresentation {
    NSMutableDictionary *eventDictionary = [@{kMPEventNameKey:self.name,
                                              kMPEventStartTimestamp:MPCurrentEpochInMilliseconds}
                                            mutableCopy];
    
    if (self.duration != nil) {
        eventDictionary[kMPEventLength] = self.duration;
    } else {
        eventDictionary[kMPEventLength] = @0;
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    if (self.customAttributes) {
        [attributes addEntriesFromDictionary:self.customAttributes];
    }
    
    if (self.duration && self.customAttributes[kMPAttrsEventLengthKey] == nil) { // Does not override "EventLength" if it already exists
        attributes[kMPAttrsEventLengthKey] = self.duration;
    }
    
    if (attributes.count > 0) {
        eventDictionary[kMPAttributesKey] = attributes;
    }
    
    if (self.customFlags) {
        eventDictionary[kMPEventCustomFlags] = self.customFlags;
    }
    
    return eventDictionary;
}

@end
