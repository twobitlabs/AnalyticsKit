import Foundation

public class AnalyticsKitWatchExtensionFlurryProvider: NSObject, AnalyticsKitProvider {

    // Logging
    public func logScreen(_ screenName: String) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        FlurryWatch.logWatchEvent("Screen - \(screenName)", withParameters: properties)
    }

    public func logEvent(_ event: String) {
        FlurryWatch.logWatchEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        FlurryWatch.logWatchEvent(event, withParameters: properties)
    }
}
