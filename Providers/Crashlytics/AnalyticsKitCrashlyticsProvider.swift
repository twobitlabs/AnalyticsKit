import Foundation
import Crashlytics

public class AnalyticsKitCrashlyticsProvider: NSObject, AnalyticsKitProvider {
    fileprivate func clsLog(_ message: String) {
        CLSLogv(message, getVaList([]))
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}

    // MARK: - Log Screens

    public func logScreen(_ screenName: String) {
        clsLog("screen: \(screenName)")
        Answers.logCustomEvent(withName: "Screen - \(screenName)", customAttributes: nil)
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        clsLog("screen: \(screenName) properties: \(properties)")
        Answers.logCustomEvent(withName: "Screen - \(screenName)", customAttributes: properties)
    }

    // MARK: - Log Events

    public func logEvent(_ event: String) {
        clsLog("event: \(event)")
        Answers.logCustomEvent(withName: event, customAttributes: nil)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        clsLog("event: \(event) properties: \(properties)")
        Answers.logCustomEvent(withName: event, customAttributes: properties)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event, withProperties: [:], timed: timed)
    }

    public func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        if timed {
            clsLog("timed event started: \(event) properties: \(dict)")
            AnalyticsKitTimedEventHelper.startTimedEventWithName(event, properties: dict, forProvider: self)
            logEvent(event, withProperties: dict)
        } else {
            logEvent(event, withProperties: dict)
        }
    }

    public func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {
        if let timedEvent = AnalyticsKitTimedEventHelper.endTimedEventNamed(event, forProvider: self) {
            clsLog("timed event ended: \(event) properties: \(dict)")
            logEvent(timedEvent.name, withProperties: timedEvent.properties)
        }
    }

    // MARK: - Log Errors

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        clsLog("error: \(name) message: \(message ?? "nil") properties: \(propertiesString(for: properties) ?? "nil") exception name: \(exception?.name.rawValue ?? "nil") reason: \(exception?.reason ?? "nil")")
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        clsLog("error: \(name) message: \(message ?? "nil") properties: \(propertiesString(for: properties) ?? "nil") error: \(error?.localizedDescription ?? "nil")")
    }

    public func uncaughtException(_ exception: NSException) {
        clsLog("uncaught exception: \(exception.name.rawValue) reason: \(exception.reason ?? "nil")")
    }

    private func propertiesString(for properties: [String: Any]?) -> String? {
        guard let properties = properties else { return nil }
        var stringArray = [String]()
        for (key, value) in properties {
            stringArray.append("\(key): \(value)")
        }
        return "[" + stringArray.joined(separator: ", ") + "]"
    }
}
