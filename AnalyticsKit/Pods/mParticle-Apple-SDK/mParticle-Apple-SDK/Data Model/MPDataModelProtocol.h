#import <Foundation/Foundation.h>

@protocol MPDataModelProtocol <NSObject>
- (NSDictionary *)dictionaryRepresentation;
- (NSString *)serializedString;
@end
