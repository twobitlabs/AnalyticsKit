import Foundation
import Adjust

public class AnalyticsKitAdjustIOProvider: NSObject, AnalyticsKitProvider {

    //-(id<AnalyticsKitProvider>)initWithAppToken:(NSString *)appToken productionEnvironmentEnabled:(BOOL)
    public init(withAppToken appToken: String, productionEnvironmentEnabled enabled: Bool) {        
        let environment = enabled ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let config = ADJConfig(appToken: appToken, environment: environment)
        Adjust.appDidLaunch(config)
    }

    // Logging
    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    public func logEvent(_ event: String) {
        Adjust.trackEvent(ADJEvent(eventToken: event))
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        let event = ADJEvent(eventToken: event)
        for (key, value) in properties {
            if let value = value as? String {
                event?.addPartnerParameter(key, value: value)
            }
        }
        Adjust.trackEvent(event)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event, withProperties: [:], timed: timed)
    }

    public func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) {
        logEvent(event, withProperties: dict)
    }
}
