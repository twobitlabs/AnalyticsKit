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
        if (FirebaseApp.app() == nil) {
            FirebaseApp.configure()
        }
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

    func logError(_ name: String, message: String?, properties: [String : Any]?, exception: NSException?) {
        var loggedProperties: [String: Any] = [
            "name": name,
            "message": String(describing: message).truncateTo(100),
            "exception": String(describing: exception).truncateTo(100)
        ]
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }

        logFbEvent("Exception Logged", parameters: loggedProperties)
    }

    func logError(_ name: String, message: String?, properties: [String : Any]?, error: Error?) {
        var loggedProperties: [String: Any] = [
            "name": name,
            "message": String(describing: message).truncateTo(100),
            "error": String(describing: error).truncateTo(100)
        ]
        if let properties = properties {
            loggedProperties.merge(properties) { (current, _) in current }
        }
        
        // error is a reserved word in firebase so we can't call the event "Error"
        logFbEvent("Error Logged", parameters: loggedProperties)
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
