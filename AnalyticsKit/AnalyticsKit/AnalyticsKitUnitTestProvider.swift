import Foundation

class AnalyticsKitUnitTestProvider: NSObject, AnalyticsKitProvider {

    var events = [AnalyticsKitEvent]()

    override init() {

    }

    class func setUp() -> AnalyticsKitUnitTestProvider {
        let provider: AnalyticsKitUnitTestProvider = AnalyticsKitUnitTestProvider()
        provider.events = [AnalyticsKitEvent]()
        AnalyticsKit.initializeProviders([provider])
        return provider
    }

    class func unitTestProvider() -> AnalyticsKitUnitTestProvider? {
        var unitProvider: AnalyticsKitUnitTestProvider?
        for provider: AnalyticsKitProvider in AnalyticsKit.providers() {
            if (provider is AnalyticsKitUnitTestProvider) {
                unitProvider = provider as? AnalyticsKitUnitTestProvider
            }
        }
        return unitProvider
    }

    class func clearEvents() {
        // Remove the events stored in the unit test provider
        self.unitTestProvider()?.clearEvents()
    }

    class func tearDown() {
        self.clearEvents()
        // Wipe out any loggers
        AnalyticsKit.initializeProviders([AnalyticsKitProvider]())
    }


    func clearEvents() {
        self.events = [AnalyticsKitEvent]()
    }

    func hasEventLoggedWithName(eventName: String) -> Bool {
        return firstEventLoggedWithName(eventName) != nil
    }

    func firstEventLoggedWithName(eventName: String) -> AnalyticsKitEvent? {
        var event: AnalyticsKitEvent?
        var matchingEvents: [AnalyticsKitEvent] = eventsLoggedWithName(eventName)
        if matchingEvents.count > 0 {
            event = matchingEvents[0]
        }
        return event
    }

    func eventsLoggedWithName(eventName: String) -> [AnalyticsKitEvent] {
        var matchingEvents: [AnalyticsKitEvent] = [AnalyticsKitEvent]()
        for event in events {
            if (eventName == event.name) {
                matchingEvents.append(event)
            }
        }
        return matchingEvents
    }


    func applicationWillEnterForeground() {
    }

    func applicationDidEnterBackground() {
    }

    func applicationWillTerminate() {
    }

    func uncaughtException(exception: NSException) {
    }


    func logScreen(screenName: String) {
        let event: String = "Screen - ".stringByAppendingString(screenName)
        self.events.append(AnalyticsKitEvent(event: event, withProperties: nil))
    }

    func logEvent(event: String) {
        self.events.append(AnalyticsKitEvent(event: event, withProperties: nil))
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        self.logEvent(event, withProperties: [key: value])
    }

    func logEvent(event: String, withProperties properties: [String : AnyObject]) {
        self.events.append(AnalyticsKitEvent(event: event, withProperties: properties))
    }

    func logEvent(event: String, timed: Bool) {
        self.events.append(AnalyticsKitEvent(event: event, withProperties: nil))
    }

    func logEvent(event: String, withProperties properties: [String : AnyObject], timed: Bool) {
        self.logEvent(event, withProperties: properties)
    }


    func endTimedEvent(event: String, withProperties properties: [String : AnyObject]) {
    }

    func logError(name: String, message: String?, exception: NSException?) {
    }

    func logError(name: String, message: String?, error: NSError?) {
    }

}