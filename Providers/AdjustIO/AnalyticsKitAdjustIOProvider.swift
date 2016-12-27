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
    func uncaughtException(_ exception: NSException) { }

    // Logging
    func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    func logEvent(_ event: String) {
        Adjust.trackEvent(ADJEvent(eventToken: event))
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        let event = ADJEvent(eventToken: event)
        event?.addPartnerParameter(key, value: value)
        Adjust.trackEvent(event)
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        let event = ADJEvent(eventToken: event)
        for (key, value) in properties {
            if let value = value as? String {
                event?.addPartnerParameter(key, value: value)
            }
        }
        Adjust.trackEvent(event)
    }

    func logEvent(_ event: String, timed: Bool) {
        
    }

    func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {

    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {

    }

    func logError(_ name: String, message: String?, exception: NSException?) {

    }

    func logError(_ name: String, message: String?, error: NSError?) {
        
    }

}
