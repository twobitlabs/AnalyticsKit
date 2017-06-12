//
//  MPAppboy.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPAppboy.h"

@implementation MPAppboy

#pragma mark NSCoding
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
    
    _userInfoPerUser = [coder decodeObjectForKey:@"userInfoPerUser"];
    _pushToken = [coder decodeObjectForKey:@"pushToken"];
    _deviceIdentifier = [coder decodeObjectForKey:@"deviceIdentifier"];
    _sessionsPerUser = [coder decodeObjectForKey:@"sessionsPerUser"];
    _feedArrayUpdateTime = [coder decodeObjectForKey:@"feedArrayUpdateTime"];
    _acksPerUser = [coder decodeObjectForKey:@"acksPerUser"];
    _externalUserId = [coder decodeObjectForKey:@"externalUserId"];
    
    return self;
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
