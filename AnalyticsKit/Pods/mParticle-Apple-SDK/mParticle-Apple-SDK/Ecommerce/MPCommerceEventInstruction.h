#import <Foundation/Foundation.h>

@class MPEvent;
@class MPProduct;

typedef NS_ENUM(NSUInteger, MPCommerceInstruction) {
    MPCommerceInstructionEvent = 0,
    MPCommerceInstructionTransaction
};

@interface MPCommerceEventInstruction : NSObject

@property (nonatomic, strong, readonly) MPEvent *event;
@property (nonatomic, strong, readonly) MPProduct *product;
@property (nonatomic, unsafe_unretained, readonly) MPCommerceInstruction instruction;

- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event;
- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event product:(MPProduct *)product __attribute__((objc_designated_initializer));

@end
