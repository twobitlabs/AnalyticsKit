#import "NSArray+MPCaseInsensitive.h"

@implementation NSArray (MPCaseInsensitive)

- (BOOL)caseInsensitiveContainsObject:(nonnull NSString *)object {
    __block BOOL result = NO;
    Class NSStringClass = [NSString class];
    [self enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSStringClass]) {
            if ([object caseInsensitiveCompare:obj] == NSOrderedSame) {
                result = YES;
                *stop = YES;
            }
        }
    }];
    return result;
}

@end
