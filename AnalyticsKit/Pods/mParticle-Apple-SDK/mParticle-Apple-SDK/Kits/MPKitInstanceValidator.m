//
//  MPKitInstanceValidator.m
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
                                      @(MPKitInstanceIterable)];

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
