#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPGDPRConsent;

/**
 * ConsentState represents the set of purposes and regulations for which a user
 * has consented for data collection.
 */
@interface MPConsentState : NSObject

/**
 * Retrieve the current GDPR consent state for this user.
 *
 * Note that all purpose keys will be lower-cased and trimmed.
 */
- (nullable NSDictionary<NSString *, MPGDPRConsent *> *)gdprConsentState;

/**
 * Add or override a single GDPR consent state.
 *
 * Note that all purpose keys will be lower-cased and trimmed.
 */
- (void)addGDPRConsentState:(MPGDPRConsent *)consent purpose:(NSString *)purpose;

/**
 * Remove a single GDPR consent state for this builder.
 *
 * Note that all purpose keys will be lower-cased and trimmed.
 */
- (void)removeGDPRConsentStateWithPurpose:(NSString *)purpose;

/**
 * Set/replace the entire GDPR consent state of this builder.
 *
 * Note that all purpose keys will be lower-cased and trimmed.
 */
- (void)setGDPRConsentState:(nullable NSDictionary<NSString *, MPGDPRConsent *> *)consentState;

@end

NS_ASSUME_NONNULL_END
