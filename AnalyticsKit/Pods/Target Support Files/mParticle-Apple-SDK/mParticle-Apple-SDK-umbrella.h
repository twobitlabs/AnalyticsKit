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
#import "MPIHasher.h"
#import "MPKitRegister.h"
#import "MPCommerceEvent.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPProduct+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPCart.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "mParticle.h"
#import "MPKitExecStatus.h"
#import "MPBags.h"
#import "MPEvent.h"
#import "MPDateFormatter.h"
#import "MPKitProtocol.h"
#import "NSArray+MPCaseInsensitive.h"
#import "MPPromotion.h"
#import "MPEnums.h"
#import "MPCommerce.h"
#import "MPUserSegments.h"
#import "MPExtensionProtocol.h"
#import "MPProduct.h"

FOUNDATION_EXPORT double mParticle_Apple_SDKVersionNumber;
FOUNDATION_EXPORT const unsigned char mParticle_Apple_SDKVersionString[];

