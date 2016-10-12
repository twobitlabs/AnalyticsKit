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
        Mixpanel.sharedInstance().track("Uncaught Exceptions", properties: [
            "ename" : exception.name,
            "reason" : exception.reason ?? "nil",
            "userInfo" : exception.userInfo ?? "nil"
        ] as [AnyHashable: Any])
    }

    // Logging
    func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    func logScreen(_ screenName: String, withProperties properties: [String : AnyObject]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    func logEvent(_ event: String) {
        Mixpanel.sharedInstance().track(event)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value as AnyObject])
    }

    func logEvent(_ event: String, withProperties properties: [String: AnyObject]) {
        Mixpanel.sharedInstance().track(event, properties: properties)
    }

    func logEvent(_ event: String, timed: Bool) {
        if timed {
            Mixpanel.sharedInstance().timeEvent(event)
        } else {
            Mixpanel.sharedInstance().track(event)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: AnyObject], timed: Bool) {
        if timed {
            Mixpanel.sharedInstance().timeEvent(event)
        } else {
            Mixpanel.sharedInstance().track(event, properties: properties)
        }
    }

    func endTimedEvent(_ event: String, withProperties properties: [String: AnyObject]) {
        // Mixpanel documentation: timeEvent followed by a track with the same event name would record the duration
        Mixpanel.sharedInstance().track(event, properties: properties)
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        Mixpanel.sharedInstance().track("Exceptions", properties: [
            "name" : name,
            "message" : message,
            "ename" : exception?.name ?? "nil",
            "reason" : exception?.reason ?? "nil",
            "userInfo" : exception?.userInfo ?? "nil"
        ] as [AnyHashable: Any])
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        Mixpanel.sharedInstance().track("Errors", properties: [
            "name" : name,
            "message" : message,
            "description" : error?.localizedDescription ?? "nil",
            "code" : "\(error?.code ?? 0)",
            "domain" : error?.domain  ?? "nil",
            "userInfo" : error?.userInfo.description  ?? "nil"
        ] as [AnyHashable: Any])
    }
    
}
