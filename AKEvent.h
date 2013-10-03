//
//  AKEvent.h
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKEvent : NSObject

@property(nonatomic,strong)NSString *name;
@property(nonatomic,strong)NSDictionary *properties;

- (id)initEvent:(NSString *)event withProperties:(NSDictionary *)dict;
- (id)initEvent:(NSString *)event;

@end
