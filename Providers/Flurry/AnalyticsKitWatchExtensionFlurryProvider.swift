import Foundation

class AnalyticsKitWatchExtensionFlurryProvider: NSObject, AnalyticsKitProvider {

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(_ exception: NSException) { }

    // Logging
    func logScreen(_ screenName: String) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)")
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)", withParameters: properties)
    }

    func logEvent(_ event: String) {
        FlurryWatch.logWatchEvent(event)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        FlurryWatch.logWatchEvent(event, withParameters: [value: key])
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        FlurryWatch.logWatchEvent(event, withParameters: properties)
    }

    func logEvent(_ event: String, timed: Bool) {

    }

    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {

    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {

    }

    func logError(_ name: String, message: String?, exception: NSException?) {

    }

    func logError(_ name: String, message: String?, error: Error?) {

    }

}
