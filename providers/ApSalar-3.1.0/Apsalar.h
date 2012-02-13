//
//  Apsalar.h
//  Apsalar SDK for iPhone/iOS public API
//
//  Copyright © 2010-2011 Apsalar Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {                  // APTIMIZER
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
+ (void) startSession:(NSString *)apiKey              // APTIMIZER
              withKey:(NSString *)apiSecret           // APTIMIZER
     andLaunchOptions:(NSDictionary *)launchOptions;  // APTIMIZER
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
+ (void) registerCallback:(NSString *)signature // APTIMIZER
					  obj:(NSObject *)obj       // APTIMIZER
				 selector:(SEL)selector;        // APTIMIZER
+ (NSInteger) trigger:(NSString *)name;         // APTIMIZER
+ (void) callback:(NSString *)url;              // APTIMIZER 
+ (NSTimeInterval) sessionDuration;
+ (NSDate *) sessionStartDate;
+ (NSString *) sessionID;
+ (NSString *) version;
+ (void) setBufferLimit:(int)size;
@property(nonatomic, readonly) NSString *applicationName;
@property(nonatomic, readonly) NSString *applicationIdentifier;
@property(nonatomic) int contentDisplayTimeout;   
+ (void) setContentDisplayTimeout:(int)seconds;
@property(nonatomic) BOOL triggerActive;        // APTIMIZER
+ (BOOL) triggerActive;                         // APTIMIZER
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
