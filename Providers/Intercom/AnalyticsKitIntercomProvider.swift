import Foundation
import Intercom

public class AnalyticsKitIntercomProvider: NSObject, AnalyticsKitProvider {

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    // MARK: - Log Screens

    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    // MARK: - Log Events

    public func logEvent(_ event: String) {
        Intercom.logEvent(withName: event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        Intercom.logEvent(withName: event, metaData: properties)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        logEvent(event, withProperties: properties)
    }

    // MARK: - Log Errors

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        var loggedProperties: [String: Any] = [
            "name": name,
            "message": message ?? "nil",
            "ename": exception?.name.rawValue ?? "nil",
            "reason": exception?.reason ?? "nil",
        ]
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }
        logEvent("Exceptions", withProperties: loggedProperties)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        var loggedProperties: [String: Any] = [
            "name": name,
            "message": message ?? "nil",
            "description": error?.localizedDescription ?? "nil",
        ]
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }
        logEvent("Errors", withProperties: loggedProperties)
    }

    public func uncaughtException(_ exception: NSException) {
        logError("Uncaught Exception", message: "Crash on iOS \(UIDevice.current.systemVersion)", properties: nil, exception: exception)
    }
}
