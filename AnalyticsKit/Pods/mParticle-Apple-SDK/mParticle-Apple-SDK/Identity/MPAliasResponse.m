//
//  MPAliasResponse.m
//

#import "MPAliasResponse.h"

@implementation MPAliasResponse

- (BOOL)isSuccessful {
    return _responseCode >= 200 && _responseCode < 300;
}

@end
