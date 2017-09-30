import Foundation

public class AnalyticsKitApsalarProvider: NSObject, AnalyticsKitProvider {
    private var apiKey: String?
    private var secret: String?

    @objc(initWithAPIKey:andSecret:andLaunchOptions:)
    public init(apiKey: String, secret: String, launchOptions options: [AnyHashable: Any]?) {
        Apsalar.startSession(apiKey, withKey: secret, andLaunchOptions: options)
        self.apiKey = apiKey
        self.secret = secret
    }

    // MARK: - Lifecycle

    public func applicationWillEnterForeground() {
        Apsalar.reStartSession(apiKey, withKey: secret)
    }

    public func applicationDidEnterBackground() {
        Apsalar.endSession()
    }

    public func applicationWillTerminate() {
        Apsalar.endSession()
        apiKey = nil
        secret = nil
    }

    // MARK: - Screen Logging

    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String : Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    // MARK: - Event Logging

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    public func logEvent(_ event: String) {
        Apsalar.event(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String : Any]) {
        Apsalar.event(event, withArgs: properties)
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

    // MARK: - Error Logging

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        var args: [String: Any] = [
            "name": name,
            "message": message ?? "nil",
            "ename": exception?.name.rawValue ?? "nil",
            "reason": exception?.reason ?? "nil",
        ]
        if let properties = properties {
            args.merge(properties) { (current, _) in current }
        }
        Apsalar.event("Exceptions", withArgs: args)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        var args: [String: Any] = [
            "name": name,
            "message": message ?? "nil",
            "description": error?.localizedDescription ?? "nil",
        ]
        if let properties = properties {
            args.merge(properties) { (current, _) in current }
        }
        Apsalar.event("Errors", withArgs: args)
    }

    public func uncaughtException(_ exception: NSException) {
        logError("Uncaught Exception", message: "Crash on iOS \(UIDevice.current.systemVersion)", properties: nil, exception: exception)
    }
}
