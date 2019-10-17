#import <Foundation/Foundation.h>
#import "MPEnums.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPBaseEvent : NSObject <NSCopying> 

/**
 The timestamp when the event was created. Is non null but can be set by the client
 */
@property (nonatomic, strong) NSDate *timestamp;

/**
 An enum value that indicates the type of event to be logged. If logging a screen event, this
 property will be overridden to MPEventTypeNavigation. In all other cases the SDK will honor the type
 assigned to this property.
 @see MPEventType
 */
@property (nonatomic, unsafe_unretained) MPEventType type;

/**
 An enum value that indicates the type of message to be sent
 assigned to this property.
 @see MPMessageType
 */
@property (nonatomic, unsafe_unretained) MPMessageType messageType;

/**
 A dictionary containing further information about the event. The number of entries is
 limited to 100 key value pairs. Keys must be strings (up to 255 characters) and values
 can be strings (up to 4096 characters), numbers, booleans, or dates
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *customAttributes;

/**
 Custom flags are a collection of attributes used to trigger functionality in specific integrations. By default, most integrations will ignore custom flags. Reference the documentation for your integrations to see if they make use of custom flags.
 */
@property (nonatomic, strong, readonly, nullable) NSMutableDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags;

/**
 A Dictionary representation of this instance for uploading the event
 Must be overridden by a subclass
 */
@property (nonatomic, readonly) NSDictionary<NSString *, id> *dictionaryRepresentation;

/**
 Initializes an instance of MPBaseEvent
 MPBaseEvent is an abstract parent class so you should always instantiate one of its children rather than the parent.
 @param type An enum value that indicates the type of event to be logged.
 @returns An instance of MPBaseEvent or nil, if it could not be initialized.
 */
- (nullable instancetype)initWithEventType:(MPEventType)type __attribute__((objc_designated_initializer));

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

- (NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
