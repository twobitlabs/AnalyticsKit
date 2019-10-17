#import "MPAppboy.h"

@implementation MPAppboy

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_userInfoPerUser forKey:@"userInfoPerUser"];
    [coder encodeObject:_pushToken forKey:@"pushToken"];
    [coder encodeObject:_deviceIdentifier forKey:@"deviceIdentifier"];
    [coder encodeObject:_sessionsPerUser forKey:@"sessionsPerUser"];
    [coder encodeObject:_feedArrayUpdateTime forKey:@"feedArrayUpdateTime"];
    [coder encodeObject:_acksPerUser forKey:@"acksPerUser"];
    [coder encodeObject:_externalUserId forKey:@"externalUserId"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _userInfoPerUser = [coder decodeObjectOfClass:[NSString class] forKey:@"userInfoPerUser"];
    _pushToken = [coder decodeObjectOfClass:[NSString class] forKey:@"pushToken"];
    _deviceIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceIdentifier"];
    _sessionsPerUser = [coder decodeObjectOfClass:[NSString class] forKey:@"sessionsPerUser"];
    _feedArrayUpdateTime = [coder decodeObjectOfClass:[NSArray class] forKey:@"feedArrayUpdateTime"];
    _acksPerUser = [coder decodeObjectOfClass:[NSObject class] forKey:@"acksPerUser"];
    _externalUserId = [coder decodeObjectOfClass:[NSString class] forKey:@"externalUserId"];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public methods
- (NSString *)jsonString {
    if (!_deviceIdentifier && !_externalUserId) {
        return nil;
    }
    
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (_deviceIdentifier) {
        jsonDictionary[@"deviceIdentifier"] = _deviceIdentifier;
    }
    
    if (_externalUserId) {
        jsonDictionary[@"externalUserId"] = _externalUserId;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    NSString *jsonString = nil;
    if (!error) {
        jsonString  = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

@end
