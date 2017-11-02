import Foundation
#if COCOAPODS
    import MobileCenter
    import MobileCenterAnalytics
    import MobileCenterCrashes
#endif
public class AnalyticsKitMicrosoftMobileCenterProvider: NSObject, AnalyticsKitProvider {

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
    
    public func logError(_ name: String, message: String?, properties: [String : Any]?, exception: NSException?) {
        var dict = [String : Any]()
        
        if let prop = properties {
            dict = prop
        }
        dict["Exception"] = name
        dict["Message"] = message
        dict["Description"] = exception?.description
        
        MSAnalytics.trackEvent(name, withProperties: properties as? [String : String])
    }
    
    public func logError(_ name: String, message: String?, properties: [String : Any]?, error: Error?) {
        var dict = [String : Any]()
        
        if let prop = properties {
            dict = prop
        }
        dict["Error"] = name
        dict["Message"] = message
        dict["Description"] = error?.localizedDescription
        
        MSAnalytics.trackEvent(name, withProperties: properties as? [String : String])
    }
}

extension AnalyticsKitMicrosoftMobileCenterProvider: MSCrashesDelegate {
    public func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        // return true if the crash report should be processed, otherwise false.
        return true
    }
}
