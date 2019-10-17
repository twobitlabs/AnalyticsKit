#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MPTransactionAttributes.h"
#import "FilteredMParticleUser.h"
#import "MPIHasher.h"
#import "MPKitRegister.h"
#import "MPCommerceEvent.h"
#import "MPIdentityApiRequest.h"
#import "MPAliasRequest.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPGDPRConsent.h"
#import "MPProduct+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPCart.h"
#import "MPAliasResponse.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "mParticle.h"
#import "MPKitExecStatus.h"
#import "MPIdentityApi.h"
#import "MPEvent.h"
#import "MPDateFormatter.h"
#import "MPKitAPI.h"
#import "MPKitProtocol.h"
#import "NSArray+MPCaseInsensitive.h"
#import "MPPromotion.h"
#import "MPConsentState.h"
#import "FilteredMPIdentityApiRequest.h"
#import "MPEnums.h"
#import "MParticleUser.h"
#import "MPCommerce.h"
#import "MPUserSegments.h"
#import "MPBaseEvent.h"
#import "MPExtensionProtocol.h"
#import "MPProduct.h"
#import "MPListenerProtocol.h"
#import "MPListenerController.h"

FOUNDATION_EXPORT double mParticle_Apple_SDKVersionNumber;
FOUNDATION_EXPORT const unsigned char mParticle_Apple_SDKVersionString[];

