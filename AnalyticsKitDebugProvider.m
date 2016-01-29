
#import "AnalyticsKitDebugProvider.h"

@interface AnalyticsKitDebugProvider()

// borrowing from https://github.com/dbettermann/DBAlertController/blob/master/Source/DBAlertController.swift
@property(nonatomic,strong)UIWindow *alertWindow;

@end

@implementation AnalyticsKitDebugProvider

#pragma mark -
#pragma mark Lifecycle

-(void)applicationWillEnterForeground{}

-(void)applicationDidEnterBackground{}

-(void)applicationWillTerminate{}

-(void)uncaughtException:(NSException *)exception{}

#pragma mark -
#pragma mark Event Logging

-(void)logScreen:(NSString *)screenName{}

-(void)logEvent:(NSString *)value {}

-(void)logEvent:(NSString *)event withProperty:(NSString *)key andValue:(NSString *)value {}

-(void)logEvent:(NSString *)event withProperties:(NSDictionary *)dict {}

-(void)logEvent:(NSString *)eventName timed:(BOOL)timed{}

-(void)logEvent:(NSString *)eventName withProperties:(NSDictionary *)dict timed:(BOOL)timed{}

-(void)endTimedEvent:(NSString *)eventName withProperties:(NSDictionary *)dict{}

-(void)showDebugAlert:(NSString *)message{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.alertWindow != nil) {
                [[self.alertWindow rootViewController] dismissViewControllerAnimated:NO completion:nil];
                self.alertWindow.rootViewController = nil;
                self.alertWindow.hidden = true;
                self.alertWindow = nil;
            }

            UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            self.alertWindow = alertWindow;
            alertWindow.rootViewController = [UIViewController new];
            alertWindow.backgroundColor = [UIColor clearColor];
            [alertWindow makeKeyAndVisible];

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AnalyticsKit Received Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            __weak AnalyticsKitDebugProvider *weakSelf = self;
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                weakSelf.alertWindow.rootViewController = nil;
                weakSelf.alertWindow.hidden = true;
                weakSelf.alertWindow = nil;
            }]];

            [[alertWindow rootViewController] presentViewController:alertController animated:YES completion:nil];
        }];
}

-(void)logError:(NSString *)name message:(NSString *)message exception:(NSException *)exception{
    NSString *detail = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", name, message, exception];
    [self showDebugAlert:detail];
}

-(void)logError:(NSString *)name message:(NSString *)message error:(NSError *)error{
    NSString *detail = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", name, message, error];    
    [self showDebugAlert:detail];
}

@end
