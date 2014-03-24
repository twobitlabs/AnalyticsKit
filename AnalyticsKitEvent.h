//
//  AnalyticsKitEvent.h
//  TeamStream
//
//  Created by Todd Huss on 11/14/12.
//  Copyright (c) 2012 Two Bit Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsKitEvent : NSObject

@property(nonatomic,copy)NSString *name;
@property(nonatomic,strong)NSDictionary *properties;
@property(strong)NSDate *startTime;

- (instancetype)initEvent:(NSString *)event;
- (instancetype)initEvent:(NSString *)event withProperties:(NSDictionary *)dict;
- (instancetype)initEvent:(NSString *)event withKey:(NSString *)key andValue:(NSString *)value;
- (void)setProperty:(id)value forKey:(NSString *)key;

@end
