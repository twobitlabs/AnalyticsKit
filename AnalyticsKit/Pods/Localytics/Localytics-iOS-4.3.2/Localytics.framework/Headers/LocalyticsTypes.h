//
//  LocalyticsTypes.h
//  Copyright (C) 2017 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.
//

typedef NS_ENUM(NSUInteger, LLInAppMessageDismissButtonLocation){
    LLInAppMessageDismissButtonLocationLeft,
    LLInAppMessageDismissButtonLocationRight
};

typedef NS_ENUM(NSInteger, LLRegionEvent){
    LLRegionEventEnter,
    LLRegionEventExit
};

typedef NS_ENUM(NSInteger, LLProfileScope){
    LLProfileScopeApplication,
    LLProfileScopeOrganization
};

typedef NS_ENUM(NSInteger, LLInAppMessageType) {
    LLInAppMessageTypeTop,
    LLInAppMessageTypeBottom,
    LLInAppMessageTypeCenter,
    LLInAppMessageTypeFull
};

typedef NS_ENUM(NSInteger, LLImpressionType) {
    LLImpressionTypeClick,
    LLImpressionTypeDismiss
};
