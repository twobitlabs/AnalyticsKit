import Foundation

class AnalyticsKitCrashlyticsProvider: NSObject, AnalyticsKitProvider {

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(exception: NSException) { }

    // Logging
    func logScreen(screenName: String) {
        clsLog("screen: \(screenName)")
        Answers.logCustomEventWithName("Screen - \(screenName)", customAttributes: nil)
    }

    func logScreen(screenName: String, withProperties properties: [String : AnyObject]) {
        clsLog("screen: \(screenName) properties: \(properties)")
        Answers.logCustomEventWithName("Screen - \(screenName)", customAttributes: properties)
    }

    func logEvent(event: String) {
        clsLog("event: \(event)")
        Answers.logCustomEventWithName(event, customAttributes: nil)
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        clsLog("event: \(event) properties: \(properties)")
        Answers.logCustomEventWithName(event, customAttributes: properties)
    }

    func logEvent(event: String, timed: Bool) {

    }

    func logEvent(event: String, withProperties dict: [String: AnyObject], timed: Bool) {

    }

    func endTimedEvent(event: String, withProperties dict: [String: AnyObject]) {

    }

    func logError(name: String, message: String?, exception: NSException?) {
        clsLog("error: \(name) message: \(message ?? "nil") exception: \(exception ?? "nil")")
    }

    func logError(name: String, message: String?, error: NSError?) {
        clsLog("error: \(name) message: \(message ?? "nil") error: \(error ?? "nil")")
    }

    private func clsLog(message: String) {
        CLSLogv(message, getVaList([]))
    }

}
