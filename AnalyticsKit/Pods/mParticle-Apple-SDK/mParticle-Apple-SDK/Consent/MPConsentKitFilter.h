#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentKitFilterItem : NSObject

@property (nonatomic, assign) BOOL consented;
@property (nonatomic, assign) int javascriptHash;

@end

@interface MPConsentKitFilter : NSObject

@property (nonatomic, assign) BOOL shouldIncludeOnMatch;
@property (nonatomic, strong) NSArray<MPConsentKitFilterItem *> *filterItems;

@end

NS_ASSUME_NONNULL_END
