//
//  AnalyticsKitEvent.m
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import "AnalyticsKitEvent.h"

@implementation AnalyticsKitEvent

- (instancetype)initEvent:(NSString *)event {
    return [self initEvent:event withProperties:nil];
}

- (instancetype)initEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.name = event;
        self.properties = dict;
    }
    return self;
}

- (instancetype)initEvent:(NSString *)event withKey:(NSString *)key andValue:(NSString *)value {
    self = [super init];
    if (self) {
        self.name = event;
        if ([key conformsToProtocol:@protocol(NSCopying)] && value != nil) {
            self.properties = @{key : value};
        }
    }
    return self;
}

- (void)setProperty:(id)value forKey:(NSString *)key {
    if ([key conformsToProtocol:@protocol(NSCopying)] && value != nil) {
        NSMutableDictionary *properties = [@{key:value} mutableCopy];
        [properties addEntriesFromDictionary:self.properties];
        self.properties = properties;
    }
}


@end
