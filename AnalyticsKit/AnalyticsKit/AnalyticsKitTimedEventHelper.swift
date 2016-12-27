import Foundation

class AnalyticsKitTimedEventHelper: NSObject {

    static var events = [String: [String: AnalyticsKitEvent]]()

    class func startTimedEventWithName(_ name: String, forProvider provider: AnalyticsKitProvider) {
        self.startTimedEventWithName(name, properties: nil, forProvider: provider)
    }

    class func startTimedEventWithName(_ name: String, properties: [String: Any]?, forProvider provider: AnalyticsKitProvider) {
        let providerClass: String = NSStringFromClass(type(of: provider))
        var providerDict = events[providerClass]
        if providerDict == nil {
            providerDict = [String : AnalyticsKitEvent]()
            events[providerClass] = providerDict
        }
        var event: AnalyticsKitEvent? = providerDict![name]
        if event == nil {
            event = AnalyticsKitEvent(event: name)
            providerDict![name] = event
        }
        if let properties = properties {
            event!.properties = properties
        }
        event!.startTime = Date()
    }

    class func endTimedEventNamed(_ name: String, forProvider provider: AnalyticsKitProvider) -> AnalyticsKitEvent? {
        var event: AnalyticsKitEvent? = nil
        let providerClass: String = NSStringFromClass(type(of: provider))
        if var providerDict = events[providerClass] {
            event = providerDict[name]
            providerDict.removeValue(forKey: name)
        }
        if let event = event, let startTime = event.startTime {
            let elapsedTime: TimeInterval = Date().timeIntervalSince(startTime as Date)
            event.setProperty(elapsedTime, forKey: "AnalyticsKitEventTimeSeconds")
        }
        return event
    }

}
