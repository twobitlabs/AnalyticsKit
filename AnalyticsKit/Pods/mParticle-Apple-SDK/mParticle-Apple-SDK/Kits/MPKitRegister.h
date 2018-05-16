#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"
#import "MPExtensionProtocol.h"

@interface MPKitRegister : NSObject <MPExtensionKitProtocol>

/**
 Kit code. Obtained from mParticle and informed to the Core SDK
 */
@property (nonatomic, strong, nonnull, readonly) NSNumber *code;

/**
 Instance of the 3rd party kit wrapper implementation. The instance is allocated by the mParticle SDK and uses the class name provided by the className parameter.
 You should not set this property. It's lifecycle is managed by the mParticle SDK
 @see className
 @see MPKitProtocol
 */
@property (nonatomic, strong, nullable) id<MPKitProtocol> wrapperInstance;

/**
 Kit name. Obtained from the 3rd party library provider and informed to the Core SDK
 */
@property (nonatomic, strong, nonnull, readonly) NSString *name;

/**
 Name of the class implementing the wrapper to forward calls to 3rd party kits
 */
@property (nonatomic, strong, nonnull, readonly) NSString *className;

/**
 Allocates and initializes a register to a 3rd party kit implementation
 @param name Kit name. Obtained from the 3rd party library provider and informed to the Core SDK
 @param className Name of the class implementing the wrapper to forward calls to 3rd party kits
 @returns An instance of a kit register or nil if a kit register could not be instantiated
 */
- (nullable instancetype)initWithName:(nonnull NSString *)name className:(nonnull NSString *)className __attribute__((objc_designated_initializer));

@end
