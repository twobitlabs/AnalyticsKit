import Foundation
import mParticle_Apple_SDK

let AKMParticleEventType = "mParticleEventType"

public class AnalyticsKitMParticleProvider: NSObject, AnalyticsKitProvider {

    let defaultEventType: MPEventType

    @objc(initWithOptions:defaultEventType:)
    public init(options: MParticleOptions, defaultEventType: MPEventType = .other) {
        self.defaultEventType = defaultEventType
        MParticle.sharedInstance().start(with: options)
    }

    @objc(initWithKey:secret:defaultEventType:installationType:environment:proxyAppDelegate:)
    public init(key: String, secret: String, defaultEventType: MPEventType = .other, installationType: MPInstallationType = .autodetect, environment: MPEnvironment = .autoDetect, proxyAppDelegate: Bool = false) {
        self.defaultEventType = defaultEventType
        let options = MParticleOptions(key: key, secret: secret)
        options.installType = installationType
        options.environment = environment
        options.proxyAppDelegate = proxyAppDelegate
        MParticle.sharedInstance().start(with: options)
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}

    // Logging
    public func logScreen(_ screenName: String) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: nil)
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: properties)
    }

    public func logEvent(_ event: String) {
        MParticle.sharedInstance().logEvent(event, eventType: defaultEventType, eventInfo: nil)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        MParticle.sharedInstance().logEvent(event, eventType: extractEventTypeFromProperties(properties), eventInfo: properties)
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        if timed {
            if MParticle.sharedInstance().event(withName: event) != nil {
                endTimedEvent(event, withProperties: [String: Any]())
            }
            if let event = MPEvent(name: event, type: defaultEventType) {
                MParticle.sharedInstance().beginTimedEvent(event)
            }
        } else {
            logEvent(event)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        if timed {
            if MParticle.sharedInstance().event(withName: event) != nil {
                endTimedEvent(event, withProperties: properties)
            } else if let mpEvent = MPEvent(name: event, type: extractEventTypeFromProperties(properties)) {
                mpEvent.info = properties
                MParticle.sharedInstance().beginTimedEvent(mpEvent)
            }
        } else {
            logEvent(event, withProperties: properties)
        }
    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        if let event = MParticle.sharedInstance().event(withName: event) {
            if properties.count > 0 {
                // Replace the parameters if parameters are passed
                event.info = properties
            }
            MParticle.sharedInstance().endTimedEvent(event)
        }
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        if let exception = exception {
            MParticle.sharedInstance().logException(exception)
        } else {
            logError(name, message: message, properties: properties, error: nil)
        }
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        var eventInfo = [String: Any]()
        if let message = message {
            eventInfo["message"] = message
        }
        if let error = error {
            eventInfo["error"] = error.localizedDescription
        }
        if let properties = properties {
            eventInfo.merge(properties) { (current, _) in current }
        }
        MParticle.sharedInstance().logError(name, eventInfo: eventInfo)
    }

    fileprivate func extractEventTypeFromProperties(_ properties: [String: Any]) -> MPEventType {
        if let value = properties[AKMParticleEventType] as? UInt, let eventType = MPEventType(rawValue: value) {
            return eventType
        }
        return defaultEventType
    }
}
