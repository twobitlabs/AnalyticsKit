import Foundation
import Localytics

public class AnalyticsKitLocalyticsProvider: NSObject, AnalyticsKitProvider {
    @objc(initWithAPIKey:)
    public init(apiKey localyticsKey: String) {
        Localytics.integrate(localyticsKey)
        Localytics.openSession()
    }

    public func applicationWillEnterForeground() {
        Localytics.openSession()
        Localytics.upload()
    }

    public func applicationDidEnterBackground() {
        Localytics.closeSession()
        Localytics.upload()
    }

    public func applicationWillTerminate() {
        Localytics.closeSession()
        Localytics.upload()
    }

    public func uncaughtException(_ exception: NSException) {
        Localytics.tagEvent("Uncaught Exceptions", attributes: [
            "ename": exception.name.rawValue,
            "reason": exception.reason ?? "nil",
        ])
    }

    public func logScreen(_ screenName: String) {
        Localytics.tagScreen(screenName)
    }

    public func logScreen(_ screenName: String, withProperties properties: [String : Any]) {
        logScreen(screenName)
    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    public func logEvent(_ event: String) {
        Localytics.tagEvent(event)
    }
    
    public func logEvent(_ event: String, withProperties properties: [String : Any]) {
        Localytics.tagEvent(event, attributes: properties as? [String : String])
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String : Any], timed: Bool) {
        logEvent(event, withProperties: properties)
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        Localytics.tagEvent("Exceptions", attributes: [
            "name": name,
            "message": message ?? "nil",
            "ename": exception?.name.rawValue ?? "nil",
            "reason": exception?.reason ?? "nil",
        ])
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        Localytics.tagEvent("Exceptions", attributes: [
            "name": name,
            "message": message ?? "nil",
            "description": error?.localizedDescription ?? "nil",
        ])
    }
}
