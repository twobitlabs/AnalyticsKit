import Foundation
#if COCOAPODS
    import MobileCenter
    import MobileCenterAnalytics
    import MobileCenterCrashes
#endif
public class AnalyticsKitMicrosftMobileCenterProvider: NSObject, AnalyticsKitProvider {

    public init(withTrackingID trackingId: String) {
        MSMobileCenter.start(trackingId, withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
    }

    public func uncaughtException(_ exception: NSException) {
        MSCrashes.setDelegate(self)
    }

    // Logging
    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    public func logScreen(_ screenName: String) {
        MSAnalytics.trackEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        MSAnalytics.trackEvent("Screen - \(screenName)", withProperties: properties as? [String : String])
    }

    public func logEvent(_ event: String) {
        MSAnalytics.trackEvent(event)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        let properties = [key : value]
        MSAnalytics.trackEvent(event, withProperties: properties as [String : String])
    }

    public func logEvent(_ event: String, timed: Bool) {
        MSAnalytics.trackEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        MSAnalytics.trackEvent(event, withProperties: properties as? [String : String])
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        MSAnalytics.trackEvent(event, withProperties: properties as? [String : String])
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        let dict = ["Exception" : name, "Message" : message, "Description" : exception?.description]
        MSAnalytics.trackEvent(name, withProperties: dict as? [String : String])
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        let dict = ["Error" : name, "Message" : message, "Description" : error?.localizedDescription]
        MSAnalytics.trackEvent(name, withProperties: dict as? [String : String])
    }
}

extension AnalyticsKitMicrosftMobileCenterProvider: MSCrashesDelegate {
    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        // return true if the crash report should be processed, otherwise false.
        return true
    }
}
