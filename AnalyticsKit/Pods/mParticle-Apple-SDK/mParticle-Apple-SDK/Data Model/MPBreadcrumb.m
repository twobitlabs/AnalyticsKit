#import "MPBreadcrumb.h"
#import "MPIConstants.h"

@interface MPBreadcrumb()
@property (nonatomic, strong) NSString *content;
@end


@implementation MPBreadcrumb

- (instancetype)initWithSessionUUID:(NSString *)sessionUUID breadcrumbId:(int64_t)breadcrumbId UUID:(NSString *)uuid breadcrumbData:(NSData *)breadcrumbData timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (self) {
        _sessionUUID = sessionUUID;
        _breadcrumbId = breadcrumbId;
        _uuid = uuid;
        _timestamp = timestamp;
        _breadcrumbData = breadcrumbData;
        if (breadcrumbData) {
            _content = [[NSString alloc] initWithData:breadcrumbData encoding:NSUTF8StringEncoding];
        }
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Breadcrumb\n UUID: %@\n Content: %@\n timestamp: %.0f\n", self.uuid, self.content, self.timestamp];
}

- (BOOL)isEqual:(MPBreadcrumb *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPBreadcrumb class]]) {
        return NO;
    }
    
    BOOL isEqual = _breadcrumbId == object.breadcrumbId &&
                   _timestamp == object.timestamp &&
                   [_uuid isEqualToString:object.uuid] &&
                   [_sessionUUID isEqualToString:object.sessionUUID] &&
                   [_breadcrumbData isEqualToData:object.breadcrumbData];
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPBreadcrumb *copyObject = [[MPBreadcrumb alloc] initWithSessionUUID:[_sessionUUID copy]
                                                            breadcrumbId:_breadcrumbId
                                                                    UUID:[_uuid copy]
                                                          breadcrumbData:[_breadcrumbData copy]
                                                               timestamp:_timestamp];
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionUUID forKey:@"sessionUUID"];
    [coder encodeInt64:self.breadcrumbId forKey:@"breadcrumbId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.content forKey:@"content"];
    [coder encodeObject:self.breadcrumbData forKey:@"breadcrumbData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *content = [coder decodeObjectForKey:@"content"];
    NSData *breadcrumbData = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    self = [self initWithSessionUUID:[coder decodeObjectOfClass:[NSString class] forKey:@"sessionUUID"]
                        breadcrumbId:[coder decodeInt64ForKey:@"breadcrumbId"]
                                UUID:[coder decodeObjectOfClass:[NSString class] forKey:@"uuid"]
                      breadcrumbData:breadcrumbData
                           timestamp:[coder decodeDoubleForKey:@"timestamp"]];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *breadcrumbInfo = [NSJSONSerialization JSONObjectWithData:_breadcrumbData options:0 error:nil];
    
    NSMutableDictionary *breadcrumbDictionary = [@{kMPMessageTypeKey:kMPMessageTypeLeaveBreadcrumbs,
                                                   kMPTimestampKey:breadcrumbInfo[kMPTimestampKey],
                                                   kMPMessageIdKey:breadcrumbInfo[kMPMessageIdKey],
                                                   kMPSessionIdKey:breadcrumbInfo[kMPSessionIdKey],
                                                   kMPSessionStartTimestamp:breadcrumbInfo[kMPSessionStartTimestamp]
                                                  }
                                                 mutableCopy];

    if (breadcrumbInfo[kMPLeaveBreadcrumbsKey]) {
        breadcrumbDictionary[kMPLeaveBreadcrumbsKey] = breadcrumbInfo[kMPLeaveBreadcrumbsKey];
    }
    
    if (breadcrumbInfo[kMPAttributesKey]) {
        breadcrumbDictionary[kMPAttributesKey] = breadcrumbInfo[kMPAttributesKey];
    }

    return [breadcrumbDictionary copy];
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:self.breadcrumbData encoding:NSUTF8StringEncoding];
    
    return serializedString;
}

@end
