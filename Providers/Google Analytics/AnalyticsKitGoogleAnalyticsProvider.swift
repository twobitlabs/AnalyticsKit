import Foundation

class AnalyticsKitGoogleAnalyticsProvider: NSObject, AnalyticsKitProvider {

    // Constants used to parsed dictionnary to match Google Analytics tracker properties
    fileprivate let category = "Category"
    fileprivate let label = "Label"
    fileprivate let action = "Action"
    fileprivate let value = "Value"
    fileprivate let tracker: GAITracker

    init(withTrackingID trackingId: String) {
        tracker = GAI.sharedInstance().tracker(withTrackingId: trackingId)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(_ exception: NSException) {
        let dict = GAIDictionaryBuilder.createException(withDescription: exception.userInfo?.description ?? "nil", withFatal: 1).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    // Logging
    func logScreen(_ screenName: String) {
        tracker.set(kGAIScreenName, value: screenName)
        let dict = GAIDictionaryBuilder.createAppView().build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {

    }

    func logEvent(_ event: String) {
        let dict = GAIDictionaryBuilder.createEvent(withCategory: nil, action: event, label: nil, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        let dict = GAIDictionaryBuilder.createEvent(withCategory: key, action: event, label: value, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    fileprivate func valueFromDictionary(_ dictionary: [String: Any], forKey key: String) -> Any? {
        if let value = dictionary[key.lowercased()] ?? dictionary[key] as Any? {
            return value
        }
        return nil
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        let category = valueFromDictionary(properties, forKey: self.category) as? String
        let label = valueFromDictionary(properties, forKey: self.label) as? String
        let value = valueFromDictionary(properties, forKey: self.value) as? NSNumber

        let dict = GAIDictionaryBuilder.createEvent(withCategory: category, action: event, label: label, value: value).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logEvent(_ event: String, timed: Bool) {

    }

    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {

    }

    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) {

    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        // isFatal = NO, presume here, Exeption is not fatal.
        let dict = GAIDictionaryBuilder.createException(withDescription: message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        // isFatal = NO, presume here, Exeption is not fatal.
        let dict = GAIDictionaryBuilder.createException(withDescription: message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

}
