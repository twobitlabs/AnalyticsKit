#import <Foundation/Foundation.h>

@class MPAttributionResult;
@class FilteredMParticleUser;
@protocol MPKitProtocol;

@interface MPKitAPI : NSObject

- (void)logError:(NSString *_Nullable)format, ...;
- (void)logWarning:(NSString *_Nullable)format, ...;
- (void)logDebug:(NSString *_Nullable)format, ...;
- (void)logVerbose:(NSString *_Nullable)format, ...;

- (NSDictionary<NSString *, NSString *> *_Nullable)integrationAttributes;
- (void)onAttributionCompleteWithResult:(MPAttributionResult *_Nullable)result error:(NSError *_Nullable)error;

- (FilteredMParticleUser *_Nonnull)getCurrentUserWithKit:(id<MPKitProtocol> _Nonnull)kit;
- (nullable NSNumber *)incrementUserAttribute:(NSString *_Nonnull)key byValue:(NSNumber *_Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser;
- (void)setUserAttribute:(NSString *_Nonnull)key value:(id _Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser;
- (void)setUserAttributeList:(NSString *_Nonnull)key values:(NSArray<NSString *> * _Nonnull)values forUser:(FilteredMParticleUser *_Nonnull)filteredUser;
- (void)setUserTag:(NSString *_Nonnull)tag forUser:(FilteredMParticleUser *_Nonnull)filteredUser;
- (void)removeUserAttribute:(NSString *_Nonnull)key forUser:(FilteredMParticleUser *_Nonnull)filteredUser;


@end
