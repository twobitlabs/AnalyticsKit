import Foundation
#if COCOAPODS
import Adjust
#endif

public class AnalyticsKitAdjustIOProvider: NSObject, AnalyticsKitProvider {

    @objc(initWithAppToken:productionEnvironmentEnabled:)
    public init(withAppToken appToken: String, productionEnvironmentEnabled enabled: Bool) {        
        let environment = enabled ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let config = ADJConfig(appToken: appToken, environment: environment)
        Adjust.appDidLaunch(config)
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}
    public func logError(_ name: String, message: String?, exception: NSException?) {}
    public func logError(_ name: String, message: String?, error: Error?) {}

    // Logging
    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    public func logEvent(_ event: String) {
        Adjust.trackEvent(ADJEvent(eventToken: event))
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        let event = ADJEvent(eventToken: event)
        for (key, value) in properties {
            if let value = value as? String {
                event?.addPartnerParameter(key, value: value)
            }
        }
        Adjust.trackEvent(event)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event, withProperties: [:], timed: timed)
    }

    public func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        logEvent(event, withProperties: dict)
    }
}
