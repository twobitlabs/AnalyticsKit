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

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        var dimensions: [String: String] = [
            "message": message ?? "nil",
            "exception": exception?.name.rawValue ?? "nil",
        ]
        if let properties = properties {
            let stringsDict = Dictionary(uniqueKeysWithValues: properties.map { ($0, "\($1)") } )
            dimensions.merge(stringsDict) { (current, _) in current }
        }
        PFAnalytics.trackEvent(name, dimensions: dimensions)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        var dimensions: [String: String] = [
            "message": message ?? "nil",
            "error": error?.localizedDescription ?? "nil",
        ]
        if let properties = properties {
            let stringsDict = Dictionary(uniqueKeysWithValues: properties.map { ($0, "\($1)") } )
            dimensions.merge(stringsDict) { (current, _) in current }
        }
        PFAnalytics.trackEvent(name, dimensions: dimensions)
    }
}
