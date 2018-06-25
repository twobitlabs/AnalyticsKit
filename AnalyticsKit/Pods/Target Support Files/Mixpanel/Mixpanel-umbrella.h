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

#import "Mixpanel.h"
#import "MixpanelPeople.h"
#import "MPTweak.h"
#import "MPTweakInline.h"
#import "MPTweakInlineInternal.h"
#import "MPTweakStore.h"
#import "_MPTweakBindObserver.h"

FOUNDATION_EXPORT double MixpanelVersionNumber;
FOUNDATION_EXPORT const unsigned char MixpanelVersionString[];

