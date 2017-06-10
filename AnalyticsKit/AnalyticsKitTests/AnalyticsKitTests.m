@import XCTest;
@import OCMock;
#import "AnalyticsKit-Swift.h"

@interface AnalyticsKitTests : XCTestCase

@end

@implementation AnalyticsKitTests

-(void)testExample {
    NSArray *providers = @[
                           [[AnalyticsKitAdjustIOProvider alloc] initWithAppToken:@"testkey" productionEnvironmentEnabled:NO],
                           [[AnalyticsKitApsalarProvider alloc] initWithAPIKey:@"" andSecret:@"" andLaunchOptions:nil],
                           [AnalyticsKitCrashlyticsProvider new],
                           [AnalyticsKitDebugProvider new],
                           [[AnalyticsKitFlurryProvider alloc] initWithAPIKey:@"testkey"],
                           // testing multiple google tracker instances
                           [[AnalyticsKitGoogleAnalyticsProvider alloc] initWithTrackingID:@"trackerId1"],
                           [[AnalyticsKitGoogleAnalyticsProvider alloc] initWithTrackingID:@"trackerId2"],
                           // Localytics validates the key when you initialize it, so it can't be empty or fake
                           // This key is for the "AnalyticsKit iOS app"
                           [[AnalyticsKitLocalyticsProvider alloc] initWithAPIKey:@"03a5f224fe2408887ac32dd-68937c2c-fd90-11e4-b9d0-00eba64cb0ec"],
                           [[AnalyticsKitMixpanelProvider alloc] initWithAPIKey:@"xyz123"],
                           [[AnalyticsKitParseProvider alloc] initWithApplicationId:@"x" clientKey:@"y"],
                           [[AnalyticsKitMParticleProvider alloc] initWithKey:@"test-key" secret:@"test-secret" defaultEventType:MPEventTypeOther installationType:MPInstallationTypeAutodetect environment:MPEnvironmentAutoDetect],
                           [AnalyticsKitUnitTestProvider new]
                           ];
    [AnalyticsKit initializeProviders:providers];

    NSException *exception = [[NSException alloc] initWithName:@"blech" reason:nil userInfo:nil];
    NSError *error = [[NSError alloc] initWithDomain:@"blah" code:1 userInfo:nil];

    NSMutableArray *mocks = [NSMutableArray array];
    for (id provider in providers) {
        id mock = [OCMockObject partialMockForObject:provider];
        [mocks addObject:mock];
        [(id<AnalyticsKitProvider>)[mock expect] applicationWillEnterForeground];
        [(id<AnalyticsKitProvider>)[mock expect] applicationDidEnterBackground];
        [(id<AnalyticsKitProvider>)[mock expect] applicationWillTerminate];
        [(id<AnalyticsKitProvider>)[mock expect] uncaughtException:exception];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo"];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo with property" withProperty:@"bar" andValue:@"baz"];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo with properties" withProperties:@{@"bag":@"bagz"}];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo timed" timed:YES];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo timed with properties" withProperties:@{@"bee":@"beez"} timed:YES];
        [(id<AnalyticsKitProvider>)[mock expect] endTimedEvent:@"foo timed done" withProperties:@{@"1":@"2"}];
        [(id<AnalyticsKitProvider>)[mock expect] logScreen:@"foo screen"];
        [(id<AnalyticsKitProvider>)[mock expect] logScreen:@"foo screen with properties" withProperties:@{@"prop":@"value"}];
        [(id<AnalyticsKitProvider>)[mock expect] logError:@"exception" message:@"exception mess" exception:[OCMArg any]];
        [(id<AnalyticsKitProvider>)[mock expect] logError:@"error" message:@"error mess" error:error];
    }

    [AnalyticsKit logEvent:@"foo"];
    [AnalyticsKit logEvent:@"foo with property" withProperty:@"bar" andValue:@"baz"];
    [AnalyticsKit logEvent:@"foo with properties" withProperties:@{@"bag":@"bagz"}];
    [AnalyticsKit logEvent:@"foo timed" timed:YES];
    [AnalyticsKit logEvent:@"foo timed with properties" withProperties:@{@"bee":@"beez"} timed:YES];
    [AnalyticsKit logScreen:@"foo screen"];
    [AnalyticsKit logScreen:@"foo screen with properties" withProperties:@{@"prop":@"value"}];
    [AnalyticsKit applicationWillEnterForeground];
    [AnalyticsKit applicationDidEnterBackground];
    [AnalyticsKit applicationWillTerminate];
    [AnalyticsKit uncaughtException:exception];
    [AnalyticsKit endTimedEvent:@"foo timed done" withProperties:@{@"1":@"2"}];
    [AnalyticsKit logError:@"exception" message:@"exception mess" exception:exception];
    [AnalyticsKit logError:@"error" message:@"error mess" error:error];

    for (id mock in mocks) {
        [mock verify];
    }
}

@end
