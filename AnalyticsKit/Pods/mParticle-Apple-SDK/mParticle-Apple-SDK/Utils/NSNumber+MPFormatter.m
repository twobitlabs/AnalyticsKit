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
