import Foundation
import Firebase

class AnalyticsKitFirebaseProvider: NSObject, AnalyticsKitProvider {

    override init() {
        super.init()
        FirebaseApp.configure()
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(_ exception: NSException) { }

    // Logging
    func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    func logEvent(_ event: String) {
        Analytics.logEvent(event, parameters: nil)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        Analytics.logEvent(event, parameters: [key: value])
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        Analytics.logEvent(event, parameters: properties)
    }

    func logEvent(_ event: String, timed: Bool) {
        Analytics.logEvent(event, parameters: nil)
    }

    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        Analytics.logEvent(event, parameters: dict)
    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {
        // Firebase doesn't support timed events
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        Analytics.logEvent("Exception", parameters: [
            "name": name,
            "message": String(describing: message),
            "exception": String(describing: exception)
        ])
    }

    func logError(_ name: String, message: String?, error: Error?) {
        Analytics.logEvent("Error", parameters: [
            "name": name,
            "message": String(describing: message),
            "error": String(describing: error)
        ])
    }

}
