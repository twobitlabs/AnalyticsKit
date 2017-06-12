//
//  MPEvent.h
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

#import <Foundation/Foundation.h>
#import "MPEnums.h"

/**
 This class contains the information and represents an event to be logged using
 the mParticle SDK.
 */
@interface MPEvent : NSObject <NSCopying> {
@protected
    NSDate *_timestamp;
    NSString *_typeName;
}

/**
 Setting the category of an MPEvent adds a custom attribute using $Category as the key. Several integrations, such as Google Analytics, 
 will use this key to perform data mapping. Other integrations will receive the attribute as $Category. 
 Please reference the mParticle doc site for more information.
 */
@property (nonatomic, strong, nullable) NSString *category;

/**
 Custom flags are a collection of attributes which by default are not forwarded to kits.
 */
@property (nonatomic, strong, readonly, nonnull) NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags;

/**
 The duration, in milliseconds, of an event. This property can be set by a developer, or
 it can be calculated automatically by the mParticle SDK using the beginTiming/endTiming
 methods.
 @see beginTiming
 */
@property (nonatomic, strong, nullable) NSNumber *duration;

/**
 If using the beginTiming/endTiming methods, this property contains the time the
 event ended. Otherwise it is nil.
 */
@property (nonatomic, strong, nullable) NSDate *endTime;

/**
 A dictionary containing further information about the event. The number of entries is 
 limited to 100 key value pairs. Keys must be strings (up to 255 characters) and values 
 can be strings (up to 255 characters), numbers, booleans, or dates
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *info;

/**
 The name of the event to be logged (required not nil). The event name must not contain
 more than 255 characters.
 */
@property (nonatomic, strong, nonnull) NSString *name;

/**
 If using the beginTiming/endTiming methods, this property contains the time the
 event started. Otherwise it is nil.
 */
@property (nonatomic, strong, nullable) NSDate *startTime;

/**
 String representation of the event type to be logged.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *typeName;

/**
 An enum value that indicates the type of event to be logged. If logging a screen event, this 
 property will be overridden to MPEventTypeNavigation. In all other cases the SDK will honor the type
 assigned to this property.
 @see MPEventType
 */
@property (nonatomic, unsafe_unretained) MPEventType type;

/**
 Initializes an instance of MPEvent
 @param name The name of the event to be logged (required not nil). The event name must not contain more than 255 characters.
 @param type An enum value that indicates the type of event to be logged.
 @returns An instance of MPEvent or nil, if it could not be initialized.
 */
- (nullable instancetype)initWithName:(nonnull NSString *)name type:(MPEventType)type __attribute__((objc_designated_initializer));

/**
 Adds a custom flag associated with a key to the event.
 @param customFlag A string attribute
 @param key The key associated with the custom flag.
 */
- (void)addCustomFlag:(nonnull NSString *)customFlag withKey:(nonnull NSString *)key;

/**
 Adds an array of custom flags associated with a key to the event.
 @param customFlags An array of string attributes
 @param key The key associated with the custom flags.
 */
- (void)addCustomFlags:(nonnull NSArray<NSString *> *)customFlags withKey:(nonnull NSString *)key;

@end
