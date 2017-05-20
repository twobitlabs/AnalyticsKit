import Foundation
import Mixpanel

public class AnalyticsKitMixpanelProvider: NSObject, AnalyticsKitProvider {

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

    public func logError(_ name: String, message: String?, exception: NSException?) {
        var properties = [AnyHashable: Any]()
        properties["name"] = name
        properties["message"] = message
        if let exception = exception {
            properties["ename"] = exception.name
            properties["reason"] = exception.reason
            properties["userInfo"] = exception.userInfo
        }

        Mixpanel.sharedInstance()?.track("Exceptions", properties: properties)
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        var properties = [AnyHashable: Any]()
        properties["name"] = name
        properties["message"] = message
        if let error = error {
            properties["description"] = error.localizedDescription
        }

        Mixpanel.sharedInstance()?.track("Errors", properties: properties)
    }
}
