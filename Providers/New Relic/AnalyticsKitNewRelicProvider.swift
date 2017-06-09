import Foundation

public class AnalyticsKitNewRelicProvider: NSObject, AnalyticsKitProvider {
    public init(apiKey: String) {
        NewRelicAgent.start(withApplicationToken: apiKey)
    }

    public init(apiKey: String, crashReporting: Bool) {
        NewRelic.enableCrashReporting(crashReporting)
        NewRelicAgent.start(withApplicationToken: apiKey)
    }

    public init(apiKey: String, crashReporting: Bool, disableFeatures featuresToDisable: NRMAFeatureFlags) {
        NewRelic.enableCrashReporting(crashReporting)
        NewRelic.disableFeatures(featuresToDisable)
        NewRelicAgent.start(withApplicationToken: apiKey)
    }

    public func logEvent(_ event: String) {

    }

    public func logEvent(_ event: String, withProperties properties: [String : Any]) {

    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        logEvent(event, withProperties: properties)
    }
}
