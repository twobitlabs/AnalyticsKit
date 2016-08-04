//
//  NSNumber+MPFormatter.m
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

#import "NSNumber+MPFormatter.h"

@implementation NSNumber(MPFormatter)

- (NSNumber *)formatWithNonScientificNotation {
    double minThreshold = 1.0E-5;
    double maxThreshold = 1.0E10;
    double selfAbsoluteValue = fabs([self doubleValue]);
    NSNumber *formattedNumber;
    
    if (selfAbsoluteValue < minThreshold) {
        formattedNumber = @0;
    } else if (selfAbsoluteValue < maxThreshold) {
        formattedNumber = self;
    } else {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.maximumFractionDigits = 5;
        numberFormatter.numberStyle = NSNumberFormatterNoStyle;
        NSString *stringRepresentation = [numberFormatter stringFromNumber:self];
        formattedNumber = @([[numberFormatter numberFromString:stringRepresentation] doubleValue]);
    }
    
    return formattedNumber;
}

@end
