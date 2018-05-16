#import "MPKitInstanceValidator.h"
#import "MPEnums.h"
#import "MPIConstants.h"

static NSMutableArray<NSNumber *> *validKitCodes;

@implementation MPKitInstanceValidator

+ (void)initialize {
    NSArray<NSNumber *> *kitCodes = @[@(MPKitInstanceAppboy),
                                      @(MPKitInstanceTune),
                                      @(MPKitInstanceKochava),
                                      @(MPKitInstanceComScore),
                                      @(MPKitInstanceKahuna),
                                      @(MPKitInstanceNielsen),
                                      @(MPKitInstanceForesee),
                                      @(MPKitInstanceAdjust),
                                      @(MPKitInstanceBranchMetrics),
                                      @(MPKitInstanceFlurry),
                                      @(MPKitInstanceLocalytics),
                                      @(MPKitInstanceApteligent),
                                      @(MPKitInstanceWootric),
                                      @(MPKitInstanceAppsFlyer),
                                      @(MPKitInstanceApptentive),
                                      @(MPKitInstanceLeanplum),
                                      @(MPKitInstancePrimer),
                                      @(MPKitInstanceUrbanAirship),
                                      @(MPKitInstanceApptimize),
                                      @(MPKitInstanceButton),
                                      @(MPKitInstanceRevealMobile),
                                      @(MPKitInstanceRadar),
                                      @(MPKitInstanceSkyhook),
                                      @(MPKitInstanceIterable),
                                      @(MPKitInstanceSingular),
                                      @(MPKitInstanceAdobe),
                                      @(MPKitInstanceInstabot),
                                      @(MPKitInstanceCarnival)];

    validKitCodes = [[NSMutableArray alloc] initWithCapacity:kitCodes.count];
    
    for (NSNumber *kitCode in kitCodes) {
        MPKitInstance kitInstance = (MPKitInstance)[kitCode integerValue];
        
        // There should be no default clause in this switch statement
        // In case a new kit is added and we forget to add it to the list above, the code below
        // will generate warning on the next compilation
        switch (kitInstance) {
            case MPKitInstanceAppboy:
            case MPKitInstanceTune:
            case MPKitInstanceKochava:
            case MPKitInstanceComScore:
            case MPKitInstanceKahuna:
            case MPKitInstanceNielsen:
            case MPKitInstanceForesee:
            case MPKitInstanceAdjust:
            case MPKitInstanceBranchMetrics:
            case MPKitInstanceFlurry:
            case MPKitInstanceLocalytics:
            case MPKitInstanceApteligent:
            case MPKitInstanceWootric:
            case MPKitInstanceAppsFlyer:
            case MPKitInstanceApptentive:
            case MPKitInstanceLeanplum:
            case MPKitInstancePrimer:
            case MPKitInstanceUrbanAirship:
            case MPKitInstanceApptimize:
            case MPKitInstanceButton:
            case MPKitInstanceRevealMobile:
            case MPKitInstanceRadar:
            case MPKitInstanceSkyhook:
            case MPKitInstanceIterable:
            case MPKitInstanceSingular:
            case MPKitInstanceAdobe:
            case MPKitInstanceInstabot:
            case MPKitInstanceCarnival:
                [validKitCodes addObject:kitCode];
                break;
        }
    }
}

+ (BOOL)isValidKitCode:(NSNumber *)kitCode {
    if (MPIsNull(kitCode) || ![kitCode isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    return [validKitCodes containsObject:kitCode];
}

+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes {
    if (MPIsNull(kitCodes)) {
        return;
    }
    
    for (NSNumber *kitCode in kitCodes) {
        if (![validKitCodes containsObject:kitCode]) {
            [validKitCodes addObject:kitCode];
        }
    }
}

@end
