import Foundation

public class AnalyticsKitUnitTestProvider: NSObject, AnalyticsKitProvider {

    var events = [AnalyticsKitEvent]()

    public class func setUp() -> AnalyticsKitUnitTestProvider {
        let provider: AnalyticsKitUnitTestProvider = AnalyticsKitUnitTestProvider()
        provider.events = [AnalyticsKitEvent]()
        AnalyticsKit.initializeProviders([provider])
        return provider
    }

    public class func unitTestProvider() -> AnalyticsKitUnitTestProvider? {
        var unitProvider: AnalyticsKitUnitTestProvider?
        for provider: AnalyticsKitProvider in AnalyticsKit.providers() {
            if (provider is AnalyticsKitUnitTestProvider) {
                unitProvider = provider as? AnalyticsKitUnitTestProvider
            }
        }
        return unitProvider
    }

    public class func clearEvents() {
        // Remove the events stored in the unit test provider
        self.unitTestProvider()?.clearEvents()
    }

    public class func tearDown() {
        self.clearEvents()
        // Wipe out any loggers
        AnalyticsKit.initializeProviders([AnalyticsKitProvider]())
    }


    func clearEvents() {
        self.events = [AnalyticsKitEvent]()
    }

    public func hasEventLoggedWithName(_ eventName: String) -> Bool {
        return firstEventLoggedWithName(eventName) != nil
    }

    public func firstEventLoggedWithName(_ eventName: String) -> AnalyticsKitEvent? {
        var event: AnalyticsKitEvent?
        var matchingEvents: [AnalyticsKitEvent] = eventsLoggedWithName(eventName)
        if matchingEvents.count > 0 {
            event = matchingEvents[0]
        }
        return event
    }

    public func eventsLoggedWithName(_ eventName: String) -> [AnalyticsKitEvent] {
        var matchingEvents: [AnalyticsKitEvent] = [AnalyticsKitEvent]()
        for event in events {
            if (eventName == event.name) {
                matchingEvents.append(event)
            }
        }
        return matchingEvents
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}
    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {}
    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {}

    public func logScreen(_ screenName: String) {
        logEvent("Screen - \(screenName)")
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        logEvent("Screen - \(screenName)", withProperties: properties)
    }

    public func logEvent(_ event: String) {
        self.events.append(AnalyticsKitEvent(event: event))
    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        self.logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        self.events.append(AnalyticsKitEvent(event: event, withProperties: properties))
    }

    public func logEvent(_ event: String, timed: Bool) {
        self.events.append(AnalyticsKitEvent(event: event))
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        self.logEvent(event, withProperties: properties)
    }
}
