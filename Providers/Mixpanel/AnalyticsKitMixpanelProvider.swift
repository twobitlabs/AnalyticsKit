import Foundation
import Mixpanel

public class AnalyticsKitMixpanelProvider: NSObject, AnalyticsKitProvider {

    @objc(initWithAPIKey:)
    public init(withAPIKey apiKey: String) {
        Mixpanel.sharedInstance(withToken: apiKey)
    }

    public func uncaughtException(_ exception: NSException) {
        Mixpanel.sharedInstance()?.track("Uncaught Exceptions", properties: [
            "ename" : exception.name,
            "reason" : exception.reason ?? "nil",
            "userInfo" : exception.userInfo ?? "nil"
        ])
    }

    // Logging

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}

    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    public func logEvent(_ event: String) {
        Mixpanel.sharedInstance()?.track(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        Mixpanel.sharedInstance()?.track(event, properties: properties)
    }

    public func logEvent(_ event: String, timed: Bool) {
        if timed {
            Mixpanel.sharedInstance()?.timeEvent(event)
        } else {
            Mixpanel.sharedInstance()?.track(event)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        if timed {
            Mixpanel.sharedInstance()?.timeEvent(event)
        } else {
            Mixpanel.sharedInstance()?.track(event, properties: properties)
        }
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        // Mixpanel documentation: timeEvent followed by a track with the same event name would record the duration
        Mixpanel.sharedInstance()?.track(event, properties: properties)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        var loggedProperties = [String: Any]()
        loggedProperties["name"] = name
        loggedProperties["message"] = message
        if let exception = exception {
            loggedProperties["ename"] = exception.name
            loggedProperties["reason"] = exception.reason
            loggedProperties["userInfo"] = exception.userInfo
        }
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }

        Mixpanel.sharedInstance()?.track("Exceptions", properties: loggedProperties)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        var loggedProperties = [String: Any]()
        loggedProperties["name"] = name
        loggedProperties["message"] = message
        if let error = error {
            loggedProperties["description"] = error.localizedDescription
        }
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }

        Mixpanel.sharedInstance()?.track("Errors", properties: loggedProperties)
    }
}
