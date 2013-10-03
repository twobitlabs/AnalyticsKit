//
//  AKEvent.m
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import "AKEvent.h"

@implementation AKEvent

- (id)initEvent:(NSString *)event withProperties:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.name = [event copy];
        self.properties = dict;
    }
    return self;
}

- (id)initEvent:(NSString *)event {
    return [self initEvent:event withProperties:nil];
}

@end
