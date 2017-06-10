import Foundation

public class AnalyticsKitGoogleAnalyticsProvider: NSObject, AnalyticsKitProvider {

    // Constants used to parsed dictionnary to match Google Analytics tracker properties
    fileprivate let category = "Category"
    fileprivate let label = "Label"
    fileprivate let action = "Action"
    fileprivate let value = "Value"
    fileprivate let tracker: GAITracker

    public init(withTrackingID trackingId: String) {
        tracker = GAI.sharedInstance().tracker(withTrackingId: trackingId)
    }

    public func uncaughtException(_ exception: NSException) {
        let dict = GAIDictionaryBuilder.createException(withDescription: exception.userInfo?.description ?? "nil", withFatal: 1).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    // Logging
    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    public func logScreen(_ screenName: String) {
        tracker.set(kGAIScreenName, value: screenName)
        let dict = GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        tracker.set(kGAIScreenName, value: screenName)
        guard var dict: [AnyHashable: Any] = GAIDictionaryBuilder.createScreenView().build() as? [AnyHashable: Any] else { return }
        properties.forEach({ (key, value) in dict[key] = value })
        tracker.send(dict)
    }

    public func logEvent(_ event: String) {
        let dict = GAIDictionaryBuilder.createEvent(withCategory: nil, action: event, label: nil, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        let dict = GAIDictionaryBuilder.createEvent(withCategory: key, action: event, label: value, value: nil).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        logEvent(event, withProperties: properties)
    }

    fileprivate func valueFromDictionary(_ dictionary: [String: Any], forKey key: String) -> Any? {
        if let value = dictionary[key.lowercased()] ?? dictionary[key] as Any? {
            return value
        }
        return nil
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        let category = valueFromDictionary(properties, forKey: self.category) as? String
        let label = valueFromDictionary(properties, forKey: self.label) as? String
        let value = valueFromDictionary(properties, forKey: self.value) as? NSNumber

        let dict = GAIDictionaryBuilder.createEvent(withCategory: category, action: event, label: label, value: value).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        // isFatal = NO, presume here, Exception is not fatal.
        let dict = GAIDictionaryBuilder.createException(withDescription: message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        // isFatal = NO, presume here, Exception is not fatal.
        let dict = GAIDictionaryBuilder.createException(withDescription: message ?? "nil", withFatal: 0).build() as [NSObject: AnyObject]
        tracker.send(dict)
    }
}
