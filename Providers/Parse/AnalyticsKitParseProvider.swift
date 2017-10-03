import Foundation
import Parse

public class AnalyticsKitParseProvider: NSObject, AnalyticsKitProvider {

    @objc(initWithApplicationId:clientKey:)
    init(applicationId: String, clientKey: String) {
        Parse.setApplicationId(applicationId, clientKey: clientKey)
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    public func uncaughtException(_ exception: NSException) {
        PFAnalytics.trackEvent("Uncaught Exception", dimensions: [
            "version": UIDevice.current.systemVersion,
        ])
    }

    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String : Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    public func logEvent(_ event: String) {
        PFAnalytics.trackEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String : Any]) {
        PFAnalytics.trackEvent(event, dimensions: properties as? [String : String])
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        logEvent(event, withProperties: dict)
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        PFAnalytics.trackEvent(name, dimensions: [
            "message": message ?? "nil",
            "exception": exception?.name.rawValue ?? "nil",
        ])
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        PFAnalytics.trackEvent(name, dimensions: [
            "message": message ?? "nil",
            "error": error?.localizedDescription ?? "nil",
        ])
    }
}
