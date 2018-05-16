#import "MPCommerceEventInstruction.h"

@implementation MPCommerceEventInstruction

- (id)init {
    return [self initWithInstruction:MPCommerceInstructionEvent event:nil product:nil];
}

- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event {
    return [self initWithInstruction:instruction event:event product:nil];
}

- (instancetype)initWithInstruction:(MPCommerceInstruction)instruction event:(MPEvent *)event product:(MPProduct *)product {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _instruction = instruction;
    _event = event;
    _product = product;
    
    return self;
}

@end
