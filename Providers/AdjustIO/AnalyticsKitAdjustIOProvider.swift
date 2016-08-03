import Foundation

class AnalyticsKitAdjustIOProvider: NSObject, AnalyticsKitProvider {

    //-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken productionEnvironmentEnabled:(BOOL)
    init(withAppToken appToken: String, productionEnvironmentEnabled enabled: Bool) {
        let environment = enabled ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let config = ADJConfig(appToken: appToken, environment: environment)
        Adjust.appDidLaunch(config)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(exception: NSException) { }

    // Logging
    func logScreen(screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    func logEvent(event: String) {
        Adjust.trackEvent(ADJEvent(eventToken: event))
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        let event = ADJEvent(eventToken: event)
        event.addPartnerParameter(key, value: value)
        Adjust.trackEvent(event)
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        let event = ADJEvent(eventToken: event)
        for (key, value) in properties {
            if let value = value as? String {
                event.addPartnerParameter(key, value: value)
            }
        }
        Adjust.trackEvent(event)
    }

    func logEvent(event: String, timed: Bool) {
        
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject], timed: Bool) {

    }

    func endTimedEvent(event: String, withProperties dict: [String: AnyObject]) {

    }

    func logError(name: String, message: String?, exception: NSException?) {

    }

    func logError(name: String, message: String?, error: NSError?) {
        
    }

}
