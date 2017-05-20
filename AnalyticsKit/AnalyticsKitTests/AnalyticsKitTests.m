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
    
    NSMutableArray *mocks = [NSMutableArray array];
    for (id provider in providers) {
        id mock = [OCMockObject partialMockForObject:provider];
        [mocks addObject:mock];
        [(id<AnalyticsKitProvider>)[mock expect] logEvent:@"foo"];
    }
    
    [AnalyticsKit logEvent:@"foo"];
    
    for (id mock in mocks) {
        [mock verify];
    }
}

@end
