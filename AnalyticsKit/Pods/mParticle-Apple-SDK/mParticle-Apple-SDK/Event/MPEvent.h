#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import "MPBaseEvent.h"

/**
 This class represents an event to be logged using the mParticle SDK.
 */
@interface MPEvent : MPBaseEvent

/**
 Setting the category of an MPEvent adds a custom attribute using $Category as the key. Several integrations, such as Google Analytics, 
 will use this key to perform data mapping. Other integrations will receive the attribute as $Category. 
 Please reference the mParticle doc site for more information.
 */
@property (nonatomic, strong, nullable) NSString *category;

/**
A dictionary containing further information about the event. The number of entries is
limited to 100 key value pairs. Keys must be strings (up to 255 characters) and values
can be strings (up to 4096 characters), numbers, booleans, or dates
 @deprecated use customAttributes instead
*/
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *info DEPRECATED_MSG_ATTRIBUTE("use customAttributes instead");

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
 If using the beginTiming/endTiming methods, this property contains the time the
 event ended. Otherwise it is nil.
 */
@property (nonatomic, strong, nullable) NSDate *endTime;

/**
 Initializes an instance of MPEvent
 @param name The name of the event to be logged (required not nil). The event name must not contain more than 255 characters.
 @param type An enum value that indicates the type of event to be logged.
 @returns An instance of MPEvent or nil, if it could not be initialized.
 */
- (nullable instancetype)initWithName:(nonnull NSString *)name type:(MPEventType)type __attribute__((objc_designated_initializer));

/**
 The duration, in milliseconds, of an event. You can set this property directly, use the beginTiming/endTiming methods to calculate it automatically,  or you can calll beginTimedEvent/endTimedEvent from the Mparticle sharedinstance to calculate it automatically.
 */
@property (nonatomic, strong, nullable) NSNumber *duration;

/**
 Start timer for a timed event.
 */
- (void)beginTiming;

/**
 Stop timer for a timed event
 */
- (void)endTiming;

/**
 A Dictionary representation of this instance for uploading a breadcrumb event
 */
- (nullable NSDictionary *)breadcrumbDictionaryRepresentation;

/**
 A Dictionary representation of this instance for uploadinga screen event
 */
- (nullable NSDictionary *)screenDictionaryRepresentation;

@end
