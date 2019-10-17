#import "MPMessage.h"
#import "MPSession.h"
#import "MPILogger.h"
#import "MParticle.h"

@interface MPMessage()

@property (nonatomic, strong) NSData *messageData;
@property (nonatomic, strong) NSString *messageType;

@end


@implementation MPMessage

- (instancetype)initWithSessionId:(NSNumber *)sessionId messageId:(int64_t)messageId UUID:(NSString *)uuid messageType:(NSString *)messageType messageData:(NSData *)messageData timestamp:(NSTimeInterval)timestamp uploadStatus:(MPUploadStatus)uploadStatus userId:(NSNumber *)userId {
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _messageId = messageId;
        _uuid = uuid;
        _messageType = messageType;
        _messageData = messageData;
        _timestamp = timestamp;
        _uploadStatus = uploadStatus;
        _userId = userId;
    }
    
    return self;
}

- (instancetype)initWithSession:(MPSession *)session messageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp userId:(NSNumber *)userId {
    NSNumber *sessionId = nil;
    
    if (session) {
        sessionId = @(session.sessionId);
    }
    
    return [self initWithSessionId:sessionId
                         messageId:0
                              UUID:uuid
                       messageType:messageType
                       messageData:[NSJSONSerialization dataWithJSONObject:messageInfo options:0 error:nil]
                         timestamp:timestamp
                      uploadStatus:uploadStatus
                            userId:userId];
}

- (NSString *)description {
    NSString *serializedString = [self serializedString];
    
    return [NSString stringWithFormat:@"Message\n Id: %lld\n UUID: %@\n Session: %@\n Type: %@\n timestamp: %.0f\n Content: %@\n", self.messageId, self.uuid, self.sessionId, self.messageType, self.timestamp, serializedString];
}

- (BOOL)isEqual:(MPMessage *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPMessage class]]) {
        return NO;
    }
    
    BOOL sessionIdsEqual = (_sessionId == nil && object.sessionId == nil) || [_sessionId isEqual:object.sessionId];
    BOOL isEqual = sessionIdsEqual &&
                   _messageId == object.messageId &&
                   _timestamp == object.timestamp &&
                   [_messageType isEqualToString:object.messageType] &&
                   [_messageData isEqualToData:object.messageData];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMessage *copyObject = [[MPMessage alloc] initWithSessionId:[_sessionId copy]
                                                       messageId:_messageId
                                                            UUID:[_uuid copy]
                                                     messageType:[_messageType copy]
                                                     messageData:[_messageData copy]
                                                       timestamp:_timestamp
                                                    uploadStatus:_uploadStatus
                                                          userId:_userId];
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionId forKey:@"sessionId"];
    [coder encodeInt64:self.messageId forKey:@"messageId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.messageType forKey:@"messageType"];
    [coder encodeObject:self.messageData forKey:@"messageData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeInteger:self.uploadStatus forKey:@"uploadStatus"];
    [coder encodeInt64:_userId.longLongValue forKey:@"mpid"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self initWithSessionId:[coder decodeObjectOfClass:[NSNumber class] forKey:@"sessionId"]
                         messageId:[coder decodeInt64ForKey:@"messageId"]
                              UUID:[coder decodeObjectOfClass:[NSString class] forKey:@"uuid"]
                       messageType:[coder decodeObjectOfClass:[NSString class] forKey:@"messageType"]
                       messageData:[coder decodeObjectOfClass:[NSData class] forKey:@"messageData"]
                         timestamp:[coder decodeDoubleForKey:@"timestamp"]
                      uploadStatus:[coder decodeIntegerForKey:@"uploadStatus"]
                            userId:@([coder decodeInt64ForKey:@"mpid"])];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSError *error = nil;
    NSDictionary *dictionaryRepresentation = nil;
    
    @try {
        dictionaryRepresentation = [NSJSONSerialization JSONObjectWithData:_messageData options:0 error:&error];
        
        if (error != nil) {
            MPILogError(@"Error serializing message.");
        }
    } @catch (NSException *exception) {
        MPILogError(@"Exception serializing message.");
    }
    
    return dictionaryRepresentation;
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:_messageData encoding:NSUTF8StringEncoding];
    return serializedString;
}

@end
