#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPArchivist : NSObject

+ (BOOL)archiveDataWithRootObject:(id)object toFile:(NSString *)path error:(NSError ** _Nullable)error;
+ (id)unarchiveObjectOfClass:(Class)cls withFile:(NSString *)path error:(NSError ** _Nullable)error;

@end

NS_ASSUME_NONNULL_END
