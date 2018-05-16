#import "MPUserAttributeChange.h"
#import "MPIConstants.h"

@implementation MPUserAttributeChange

@synthesize valueToLog = _valueToLog;

- (nullable instancetype)initWithUserAttributes:(nullable NSDictionary<NSString *, id> *)userAttributes key:(nonnull NSString *)key value:(nullable id)value {
    Class NSStringClass = [NSString class];
    Class NSArrayClass = [NSArray class];
    BOOL validKey = !MPIsNull(key) && [key isKindOfClass:NSStringClass];
    BOOL isValueAnArray = [value isKindOfClass:NSArrayClass];
    
    NSAssert(validKey, @"'key' must be a string.");
    NSAssert(value == nil || (value != nil && ([value isKindOfClass:NSStringClass] || [value isKindOfClass:[NSNumber class]] || isValueAnArray) || (NSNull *)value == [NSNull null]), @"'value' must be either nil, string, number, or array of strings.");
    
    if (!validKey || (!userAttributes && !value)) {
        return nil;
    }

    self = [super init];
    if (self) {
        _userAttributes = userAttributes;
        _key = key;
        _value = value;
        _changed = YES;
        _deleted = NO;
        
        id existingValue = userAttributes[key];
        if (existingValue) {
            _isArray = [existingValue isKindOfClass:NSArrayClass] || isValueAnArray;

            BOOL isExistingValueNull = (NSNull *)existingValue == [NSNull null];
            if (value) {
                _changed = isExistingValueNull || ![existingValue isEqual:value];
            } else {
                _changed = !isExistingValueNull;
            }
        } else {
            _isArray = isValueAnArray;
        }
    }
    
    return self;
}

- (id)valueToLog {
    if (!_valueToLog) {
        _valueToLog = _value && !_deleted ? _value : [NSNull null];
    }
    
    return _valueToLog;
}

- (void)setValueToLog:(id)valueToLog {
    _valueToLog = valueToLog ? valueToLog : [NSNull null];
}

@end
