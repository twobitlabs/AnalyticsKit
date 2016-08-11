import Foundation

let AKMParticleEventType = "mParticleEventType"

class AnalyticsKitMParticleProvider: NSObject, AnalyticsKitProvider {

    let defaultEventType: MPEventType

    init(withKey key: String, secret: String, defaultEventType: MPEventType = .Other, installationType: MPInstallationType = .Autodetect, environment: MPEnvironment = .AutoDetect, proxyAppDelegate: Bool = false) {
        self.defaultEventType = defaultEventType
        MParticle.sharedInstance().startWithKey(key, secret: secret, installationType: installationType, environment: environment, proxyAppDelegate: proxyAppDelegate)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(exception: NSException) {
    }

    // Logging
    func logScreen(screenName: String) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: nil)
    }

    func logScreen(screenName: String, withProperties properties: [String : AnyObject]) {
        MParticle.sharedInstance().logScreen(screenName, eventInfo: properties)
    }

    func logEvent(event: String) {
        MParticle.sharedInstance().logEvent(event, eventType: defaultEventType, eventInfo: nil)
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        let properties = [key: value]
        MParticle.sharedInstance().logEvent(event, eventType: extractEventTypeFromProperties(properties), eventInfo: properties)
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        MParticle.sharedInstance().logEvent(event, eventType: extractEventTypeFromProperties(properties), eventInfo: properties)
    }

    func logEvent(event: String, timed: Bool) {
        if timed {
            if MParticle.sharedInstance().eventWithName(event) != nil {
                endTimedEvent(event, withProperties: [String: AnyObject]())
            } else if let event = MPEvent(name: event, type: defaultEventType) {
                MParticle.sharedInstance().beginTimedEvent(event)
            }
        } else {
            logEvent(event)
        }
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject], timed: Bool) {
        if timed {
            if MParticle.sharedInstance().eventWithName(event) != nil {
                endTimedEvent(event, withProperties: properties)
            } else if let mpEvent = MPEvent(name: event, type: extractEventTypeFromProperties(properties)) {
                mpEvent.info = properties
                MParticle.sharedInstance().beginTimedEvent(mpEvent)
            }
        } else {
            logEvent(event, withProperties: properties)
        }
    }

    func endTimedEvent(event: String, withProperties properties: [String: AnyObject]) {
        if let event = MParticle.sharedInstance().eventWithName(event) {
            if properties.count > 0 {
                // Replace the parameters if parameters are passed
                event.info = properties
            }
            MParticle.sharedInstance().endTimedEvent(event)
        }
    }

    func logError(name: String, message: String?, exception: NSException?) {
        if let exception = exception {
            MParticle.sharedInstance().logException(exception)
        } else {
            logError(name, message: message, error: nil)
        }
    }

    func logError(name: String, message: String?, error: NSError?) {
        var eventInfo = [String: AnyObject]()
        if let message = message {
            eventInfo["message"] = message
        }
        if let error = error {
            eventInfo["error"] = error.description
        }
        MParticle.sharedInstance().logError(name, eventInfo: eventInfo)
    }

    private func extractEventTypeFromProperties(properties: [String: AnyObject]) -> MPEventType {
        if let value = properties[AKMParticleEventType] as? UInt, eventType = MPEventType(rawValue: value) {
            return eventType
        }
        return defaultEventType
    }

}