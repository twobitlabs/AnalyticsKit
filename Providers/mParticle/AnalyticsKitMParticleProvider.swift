import Foundation

let AKMParticleEventType = "mParticleEventType"

class AnalyticsKitMParticleProvider: NSObject, AnalyticsKitProvider {

    let defaultEventType: MPEventType

    init(withKey key: String, secret: String, defaultEventType: MPEventType = .other, installationType: MPInstallationType = .autodetect, environment: MPEnvironment = .autoDetect, proxyAppDelegate: Bool = false) {
        self.defaultEventType = defaultEventType
        MParticle.sharedInstance().start(withKey: key, secret: secret, installationType: installationType, environment: environment, proxyAppDelegate: proxyAppDelegate)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(_ exception: NSException) {
    }

    // Logging
    func logScreen(_ screenName: String) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: nil)
    }

    func logScreen(_ screenName: String, withProperties properties: [String : AnyObject]) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: properties)
    }

    func logEvent(_ event: String) {
        MParticle.sharedInstance().logEvent(event, eventType: defaultEventType, eventInfo: nil)
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        let properties = [key: value]
        MParticle.sharedInstance().logEvent(event, eventType: extractEventTypeFromProperties(properties as [String : AnyObject]), eventInfo: properties)
    }

    func logEvent(_ event: String, withProperties properties: [String: AnyObject]) {
        MParticle.sharedInstance().logEvent(event, eventType: extractEventTypeFromProperties(properties), eventInfo: properties)
    }

    func logEvent(_ event: String, timed: Bool) {
        if timed {
            if MParticle.sharedInstance().event(withName: event) != nil {
                endTimedEvent(event, withProperties: [String: AnyObject]())
            }
            if let event = MPEvent(name: event, type: defaultEventType) {
                MParticle.sharedInstance().beginTimedEvent(event)
            }
        } else {
            logEvent(event)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: AnyObject], timed: Bool) {
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

    func endTimedEvent(_ event: String, withProperties properties: [String: AnyObject]) {
        if let event = MParticle.sharedInstance().event(withName: event) {
            if properties.count > 0 {
                // Replace the parameters if parameters are passed
                event.info = properties
            }
            MParticle.sharedInstance().endTimedEvent(event)
        }
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        if let exception = exception {
            MParticle.sharedInstance().logException(exception)
        } else {
            logError(name, message: message, error: nil)
        }
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        var eventInfo = [String: AnyObject]()
        if let message = message {
            eventInfo["message"] = message as AnyObject?
        }
        if let error = error {
            eventInfo["error"] = error.description as AnyObject?
        }
        MParticle.sharedInstance().logError(name, eventInfo: eventInfo)
    }

    fileprivate func extractEventTypeFromProperties(_ properties: [String: AnyObject]) -> MPEventType {
        if let value = properties[AKMParticleEventType] as? UInt, let eventType = MPEventType(rawValue: value) {
            return eventType
        }
        return defaultEventType
    }

}
