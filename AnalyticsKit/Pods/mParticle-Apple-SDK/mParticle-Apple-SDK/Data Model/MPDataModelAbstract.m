#import "MPDataModelAbstract.h"

@implementation MPDataModelAbstract

@synthesize uuid = _uuid;

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPDataModelAbstract *copyObject = [[[self class] alloc] init];
    if (copyObject) {
        copyObject.uuid = [_uuid copy];
    }
    
    return copyObject;
}

@end
