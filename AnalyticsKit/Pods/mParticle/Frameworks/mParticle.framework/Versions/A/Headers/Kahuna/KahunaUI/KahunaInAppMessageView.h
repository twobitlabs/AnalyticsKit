//
//  KahunaInAppMessage.h
//  HowToUseKahuna
//
//  Copyright (c) 2014 Kahuna. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Definition for position
typedef enum {
    OnTop,
    InCenter,
    OnBottom
} ShowWhere;

// Definition for sizes. For max width of the screen set the InAppMessageViewWidth to INT_MAX
#define InAppMessageViewWidth INT_MAX
#define InAppMessageViewHeight 60
#define InAppMessageViewInternalPadding 5
#define InAppMessageViewExternalPadding 0
#define InAppMessageImageHeight 40
#define InAppMessageImageWidth 40
#define InAppMessageXButtonHeight 15
#define InAppMessageXButtonWidth 15
#define InAppMessageGoButtonHeight 15
#define InAppMessageGoButtonWidth 20

// Definitions for time. To turn off auto-dismiss set this value to INT_MAX
#define InAppMessageViewAutoDismissInSeconds INT_MAX

// Definitions for color
#define InAppMessageMessageColor [UIColor colorWithRed:75.0/255.0 green:75.0/255.0  blue:75.0/255.0  alpha:1.0]
#define InAppMessageViewBackgroundColor [UIColor colorWithRed:255.0/255.0 green:255.0/255.0  blue:255.0/255.0  alpha:1.0]
#define InAppMessageDimBackgroundColor [UIColor colorWithRed:125.0/255.0 green:125.0/255.0  blue:125.0/255.0  alpha:0.7]
#define InAppMessageGoButtonBackgroundColor [UIColor colorWithRed:213.0/255.0 green:175.0/255.0  blue:80.0/255.0  alpha:1.0]
#define InAppMessageGoButtonTextColor [UIColor colorWithRed:75.0/255.0 green:75.0/255.0  blue:75.0/255.0  alpha:1.0]
#define InAppMessageXButtonColor [UIColor colorWithRed:173.0/255.0 green:36.0/255.0  blue:36.0/255.0  alpha:1.0]

// Definitions for appearance
#define InAppMessageAnimateAppearance true
#define InAppMessageAnimationSpeed 0.5
#define InAppMessageDimBackground true
#define InAppMessageViewRoundedEdges true
#define InAppMessageImageRoundedEdges true
#define InAppMessageViewUseEntireScreenToComputePosition false

// Definition for Texts/Fonts. Adjust these sizes based on the InAppMessageView Width and Height.
#define InAppMessageDeepLinkButtonText @"Go"
#define InAppMessageFont @"Helvetica"
#define InAppMessageTextFontSize 10
#define InAppMessageXButtonFontSize 10
#define InAppMessageGoButtonTextFontSize 10

@interface KahunaInAppMessageView : UIView {
    NSDictionary *deepLinkParams;
    UIView *parentView;
}

- (id)initToShow:(ShowWhere)where onView:(UIView*)onView withMessage:(NSString*)message withImage:(NSData*) imageData withDeepLink:(NSDictionary*)deepLink;

@end
