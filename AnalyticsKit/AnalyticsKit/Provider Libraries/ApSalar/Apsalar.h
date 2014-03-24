//
//  Apsalar.h
//  Apsalar SDK for iPhone/iOS public API
//
//  Copyright © 2010-2011 Apsalar Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    AP_TRIGGER_SUCCESS,         // An overlay was loaded
    AP_TRIGGER_NOT_SHOWN,       // Overlay not shown, unknown reason
    AP_TRIGGER_NOT_READY,       // Apsalar session not started
    AP_TRIGGER_NO_CONNECTIVITY, // No connectivity needed to do overlay
    AP_TRIGGER_NO_RULE,         // No rules connected to this trigger 
    AP_TRIGGER_UNKNOWN,         // New trigger, not yet registered
    AP_TRIGGER_CURRENTLY_ACTIVE // A trigger is already active
} AP_TRIGGER_RESULT;

@interface Apsalar : NSObject 
+ (void) startSession:(NSString *)apiKey withKey:(NSString *)apiSecret ;
+ (void) startSession:(NSString *)apiKey
              withKey:(NSString *)apiSecret
     andLaunchOptions:(NSDictionary *)launchOptions;
+ (void) startSession:(NSString *)apiKey
              withKey:(NSString *)apiSecret
               andURL:(NSURL *)url;
+ (void) reStartSession:(NSString *)apiKey withKey:(NSString *)apiSecret;
+ (BOOL) sessionStarted;
+ (void) endSession;
+ (void) event:(NSString *)name;
+ (void) event:(NSString *)name withArgs:(NSDictionary *)args;
+ (void) eventWithArgs:(NSString *)name, ...; // use only subclasses of 
                                              // NSObject, not primitive types 
                                              // like int
+ (void) catchExceptions;
+ (Apsalar *) shared;
+ (void) registerCallback:(NSString *)signature
                      obj:(NSObject *)obj
                 selector:(SEL)selector;
+ (NSInteger) trigger:(NSString *)name;
+ (NSTimeInterval) sessionDuration;
+ (NSDate *) sessionStartDate;
+ (NSString *) sessionID;
+ (NSString *) version;
+ (NSString *)apsalarID;
+ (NSString *)apsalarKeyspace;
+ (void) setBufferLimit:(int)size;
@property(nonatomic, readonly) NSString *applicationName;
@property(nonatomic, readonly) NSString *applicationIdentifier;
@property(nonatomic) int contentDisplayTimeout;   
+ (void) setContentDisplayTimeout:(int)seconds;
@property(nonatomic) BOOL triggerActive;
+ (BOOL) triggerActive;
+ (BOOL) processJSRequest:(UIWebView *)webView withURL:(NSURLRequest *)url;
@property(nonatomic) int minSessionDuration;  // Default: 5
+ (void) setMinSessionDuration:(int)seconds;

// IAP
+ (void)setAllowAutoIAPComplete:(BOOL)boolean;
+ (void)iapComplete:(id)transaction;
+ (void)iapComplete:(id)transaction withAttributes:(id)value, ...;

// DEMO
+ (void)setGender:(NSString *)gender;
+ (void)setAge:(id)age;

// BATCHING
+ (int)batchInterval;
+ (void)setBatchInterval:(int)interval;
+ (BOOL)batchesEvents;
+ (void)setBatchesEvents:(BOOL)boolean;
+ (void)sendAllBatches;

@end

@interface ApButton: UIButton {
    @private
    int ap_flags;
}
@property(nonatomic, retain) UIButton *actual;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *btnType;
@property(nonatomic) BOOL connected;
@end

@interface ApFeedbackButton: ApButton
@end
