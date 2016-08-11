import Foundation

class AnalyticsKitWatchExtensionFlurryProvider: NSObject, AnalyticsKitProvider {

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(exception: NSException) { }

    // Logging
    func logScreen(screenName: String) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)")
    }

    func logScreen(screenName: String, withProperties properties: [String : AnyObject]) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)", withParameters: properties)
    }

    func logEvent(event: String) {
        FlurryWatch.logWatchEvent(event)
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        FlurryWatch.logWatchEvent(event, withParameters: [value: key])
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        FlurryWatch.logWatchEvent(event, withParameters: properties)
    }

    func logEvent(event: String, timed: Bool) {

    }

    func logEvent(event: String, withProperties dict: [String: AnyObject], timed: Bool) {

    }

    func endTimedEvent(event: String, withProperties dict: [String: AnyObject]) {

    }

    func logError(name: String, message: String?, exception: NSException?) {

    }

    func logError(name: String, message: String?, error: NSError?) {

    }

}
