#import "MPKitRegister.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MParticle.h"

@implementation MPKitRegister

- (instancetype)init {
    id invalidVar = nil;
    self = [self initWithName:invalidVar className:invalidVar];
    if (self) {
        MPILogError(@"MPKitRegister cannot be initialized using the init method");
    }
    
    return nil;
}

- (nullable instancetype)initWithName:(nonnull NSString *)name className:(nonnull NSString *)className {
    Class stringClass = [NSString class];
    BOOL validName = !MPIsNull(name) && [name isKindOfClass:stringClass];
    NSAssert(validName, @"The 'name' variable is not valid.");
    
    BOOL validClassName = !MPIsNull(className) && [className isKindOfClass:stringClass];
    NSAssert(validClassName, @"The 'className' variable is not valid.");
    
    self = [super init];
    if (!self || !validName || !validClassName) {
        return nil;
    }
    
    _name = name;
    _className = className;
    _code = [(id<MPKitProtocol>)NSClassFromString(_className) kitCode];
    
    _wrapperInstance = nil;

    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ {\n", [self class]];
    [description appendFormat:@"    code: %@,\n", _code];
    [description appendFormat:@"    name: %@,\n", _name];
    [description appendString:@"}"];
    
    return description;
}

@end
