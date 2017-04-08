import Foundation

class AnalyticsKitMixpanelProvider: NSObject, AnalyticsKitProvider {

    init(withAPIKey apiKey: String) {
        Mixpanel.sharedInstance(withToken: apiKey)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(_ exception: NSException) {
        Mixpanel.sharedInstance()?.track("Uncaught Exceptions", properties: [
            "ename" : exception.name,
            "reason" : exception.reason ?? "nil",
            "userInfo" : exception.userInfo ?? "nil"
        ] as [AnyHashable: Any])
    }

    // Logging
    func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    func logEvent(_ event: String) {
        Mixpanel.sharedInstance()?.track(event)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        Mixpanel.sharedInstance()?.track(event, properties: properties)
    }

    func logEvent(_ event: String, timed: Bool) {
        if timed {
            Mixpanel.sharedInstance()?.timeEvent(event)
        } else {
            Mixpanel.sharedInstance()?.track(event)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        if timed {
            Mixpanel.sharedInstance()?.timeEvent(event)
        } else {
            Mixpanel.sharedInstance()?.track(event, properties: properties)
        }
    }

    func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        // Mixpanel documentation: timeEvent followed by a track with the same event name would record the duration
        Mixpanel.sharedInstance()?.track(event, properties: properties)
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
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

    func logError(_ name: String, message: String?, error: Error?) {
        var properties = [AnyHashable: Any]()
        properties["name"] = name
        properties["message"] = message
        if let error = error {
            properties["description"] = error.localizedDescription
        }

        Mixpanel.sharedInstance()?.track("Errors", properties: properties)
    }
    
}
