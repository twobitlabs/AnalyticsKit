//
//  NSString+MPPercentEscape.m
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

#import "NSString+MPPercentEscape.h"

@implementation NSString(MPPercentEscape)

+ (NSString *)percentEscapeString:(NSString *)stringToEscape {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *escapedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                    (__bridge CFStringRef)stringToEscape,
                                                                                                    (__bridge CFStringRef)@"@&=%",
                                                                                                    (__bridge CFStringRef)@"; ",
                                                                                                    kCFStringEncodingUTF8);
#pragma clang diagnostic pop
    
    return escapedString;
}

- (NSString *)percentEscape {
    return [NSString percentEscapeString:self];
}

@end
