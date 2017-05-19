import Foundation
import Firebase

class AnalyticsKitFirebaseProvider: NSObject, AnalyticsKitProvider {

    private static var eventCharacterSet: CharacterSet = {
        var cs = CharacterSet.alphanumerics
        cs.insert("_")
        return cs.inverted
    }()

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
        logFbEvent(event, parameters: nil)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logFbEvent(event, parameters: [key: value])
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        logFbEvent(event, parameters: properties)
    }

    func logEvent(_ event: String, timed: Bool) {
        logFbEvent(event, parameters: nil)
    }

    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        logFbEvent(event, parameters: dict)
    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {
        // Firebase doesn't support timed events
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        logFbEvent("Exception", parameters: [
            "name": name,
            "message": String(describing: message),
            "exception": String(describing: exception)
        ])
    }

    func logError(_ name: String, message: String?, error: Error?) {
        logFbEvent("Error", parameters: [
            "name": name,
            "message": String(describing: message),
            "error": String(describing: error)
        ])
    }

    fileprivate func logFbEvent(_ event: String, parameters: [String: Any]?) {
        // Firebase event names must be snake cased and since AK is designed for multi-provider we
        // have to convert to be safe.
        var snakeCaseEvent = event.replacingOccurrences(of: "-", with: " ")
        snakeCaseEvent = snakeCaseEvent.replacingOccurrences(of: "_", with: " ")
        snakeCaseEvent = snakeCaseEvent.replacingOccurrences(of: " +", with: "_", options: .regularExpression, range: nil)
        snakeCaseEvent = snakeCaseEvent.lowercased()
        snakeCaseEvent = snakeCaseEvent.components(separatedBy: AnalyticsKitFirebaseProvider.eventCharacterSet).joined()
        Analytics.logEvent(snakeCaseEvent, parameters: parameters)
    }

}
