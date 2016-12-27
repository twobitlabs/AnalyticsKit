import Foundation

class AnalyticsKitCrashlyticsProvider: NSObject, AnalyticsKitProvider {

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(_ exception: NSException) { }

    // Logging
    func logScreen(_ screenName: String) {
        clsLog("screen: \(screenName)")
        Answers.logCustomEvent(withName: "Screen - \(screenName)", customAttributes: nil)
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        clsLog("screen: \(screenName) properties: \(properties)")
        Answers.logCustomEvent(withName: "Screen - \(screenName)", customAttributes: properties)
    }

    func logEvent(_ event: String) {
        clsLog("event: \(event)")
        Answers.logCustomEvent(withName: event, customAttributes: nil)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        clsLog("event: \(event) properties: \(properties)")
        Answers.logCustomEvent(withName: event, customAttributes: properties)
    }

    func logEvent(_ event: String, timed: Bool) {

    }

    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {

    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {

    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        clsLog("error: \(name) message: \(message ?? "nil") exception: \(exception?.description ?? "nil")")
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        clsLog("error: \(name) message: \(message ?? "nil") error: \(error?.description ?? "nil")")
    }

    fileprivate func clsLog(_ message: String) {
        CLSLogv(message, getVaList([]))
    }

}
