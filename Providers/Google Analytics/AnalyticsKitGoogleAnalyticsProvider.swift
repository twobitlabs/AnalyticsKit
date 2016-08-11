import Foundation

class AnalyticsKitGoogleAnalyticsProvider: NSObject, AnalyticsKitProvider {

    // Constants used to parsed dictionnary to match Google Analytics tracker properties
    private let category = "Category"
    private let label = "Label"
    private let action = "Action"
    private let value = "Value"
    private let tracker: GAITracker

    init(withTrackingID trackingId: String) {
        tracker = GAI.sharedInstance().trackerWithTrackingId(trackingId)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(exception: NSException) {
        let dict = GAIDictionaryBuilder.createExceptionWithDescription(exception.userInfo?.description ?? "nil", withFatal: 1).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    // Logging
    func logScreen(screenName: String) {
        tracker.set(kGAIScreenName, value: screenName)
        let dict = GAIDictionaryBuilder.createAppView().build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logScreen(screenName: String, withProperties properties: [String : AnyObject]) {

    }

    func logEvent(event: String) {
        let dict = GAIDictionaryBuilder.createEventWithCategory(nil, action: event, label: nil, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        let dict = GAIDictionaryBuilder.createEventWithCategory(key, action: event, label: value, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    private func valueFromDictionary(dictionary: [NSObject: AnyObject], forKey key: String) -> AnyObject? {
        if let value = dictionary[key.lowercaseString] ?? dictionary[key] {
            return value
        }
        return nil
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        let category = valueFromDictionary(properties, forKey: self.category) as? String
        let label = valueFromDictionary(properties, forKey: self.label) as? String
        let value = valueFromDictionary(properties, forKey: self.value) as? NSNumber

        let dict = GAIDictionaryBuilder.createEventWithCategory(category, action: event, label: label, value: value).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logEvent(event: String, timed: Bool) {

    }

    func logEvent(event: String, withProperties dict: [String: AnyObject], timed: Bool) {

    }

    func endTimedEvent(event: String, withProperties dict: [String: AnyObject]) {

    }

    func logError(name: String, message: String?, exception: NSException?) {
        // isFatal = NO, presume here, Exeption is not fatal.
        let dict = GAIDictionaryBuilder.createExceptionWithDescription(message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    func logError(name: String, message: String?, error: NSError?) {
        // isFatal = NO, presume here, Exeption is not fatal.
        let dict = GAIDictionaryBuilder.createExceptionWithDescription(message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

}
