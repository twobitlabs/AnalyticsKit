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

    public func logError(_ name: String, message: String?, exception: NSException?) {
        logEvent("Exceptions", withProperties: [
            "name": name,
            "message": message ?? "nil",
            "ename": exception?.name.rawValue ?? "nil",
            "reason": exception?.reason ?? "nil",
        ])
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        logEvent("Errors", withProperties: [
            "name": name,
            "message": message ?? "nil",
            "description": error?.localizedDescription ?? "nil",
        ])
    }

    public func uncaughtException(_ exception: NSException) {
        logError("Uncaught Exception", message: "Crash on iOS \(UIDevice.current.systemVersion)", exception: exception)
    }
}
