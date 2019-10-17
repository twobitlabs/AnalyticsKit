//
//  MPAliasRequest.m
//

#import "MPAliasRequest.h"
#import "MParticle.h"

@interface MPAliasRequest ()

@property (nonatomic, strong, readwrite) NSNumber *sourceMPID;
@property (nonatomic, strong, readwrite) NSNumber *destinationMPID;
@property (nonatomic, strong, readwrite) NSDate *startTime;
@property (nonatomic, strong, readwrite) NSDate *endTime;
@property (nonatomic, assign, readwrite) BOOL usedFirstLastSeen;

@end


@implementation MPAliasRequest

+ (MPAliasRequest *)requestWithSourceUser:(MParticleUser *) sourceUser destinationUser:(MParticleUser *)destinationUser {
    MPAliasRequest *aliasRequest = [[MPAliasRequest alloc] init];
    aliasRequest.sourceMPID = sourceUser.userId;
    aliasRequest.destinationMPID = destinationUser.userId;
    aliasRequest.startTime = sourceUser.firstSeen;
    aliasRequest.endTime = sourceUser.lastSeen;
    aliasRequest.usedFirstLastSeen = YES;
    return aliasRequest;
}

+ (MPAliasRequest *)requestWithSourceMPID:(NSNumber *) sourceMPID destinationMPID:(NSNumber *)destinationMPID startTime:(NSDate *)startTime endTime:(NSDate *)endTime {
    MPAliasRequest *aliasRequest = [[MPAliasRequest alloc] init];
    aliasRequest.sourceMPID = sourceMPID;
    aliasRequest.destinationMPID = destinationMPID;
    aliasRequest.startTime = startTime;
    aliasRequest.endTime = endTime;
    aliasRequest.usedFirstLastSeen = NO;
    return aliasRequest;
}

@end
