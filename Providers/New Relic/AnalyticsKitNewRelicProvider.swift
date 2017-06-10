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

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}
    public func logEvent(_ event: String) {}
    public func logEvent(_ event: String, withProperties properties: [String : Any]) {}
    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {}
    public func logEvent(_ event: String, timed: Bool) {}
    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {}
    public func logScreen(_ screenName: String) {}
    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}
    public func logError(_ name: String, message: String?, exception: NSException?) {}
    public func logError(_ name: String, message: String?, error: Error?) {}

}
