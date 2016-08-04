import Foundation

class AnalyticsKitTimedEventHelper: NSObject {

    static var events = [String: [String: AnalyticsKitEvent]]()

    class func startTimedEventWithName(name: String, forProvider provider: AnalyticsKitProvider) {
        self.startTimedEventWithName(name, properties: nil, forProvider: provider)
    }

    class func startTimedEventWithName(name: String, properties: [String: AnyObject]?, forProvider provider: protocol<AnalyticsKitProvider>) {
        let providerClass: String = NSStringFromClass(provider.dynamicType)
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
        event!.startTime = NSDate()
    }

    class func endTimedEventNamed(name: String, forProvider provider: protocol<AnalyticsKitProvider>) -> AnalyticsKitEvent? {
        var event: AnalyticsKitEvent? = nil
        let providerClass: String = NSStringFromClass(provider.dynamicType)
        if var providerDict = events[providerClass] {
            event = providerDict[name]
            providerDict.removeValueForKey(name)
        }
        if let event = event, startTime = event.startTime {
            let elapsedTime: NSTimeInterval = NSDate().timeIntervalSinceDate(startTime)
            event.setProperty(elapsedTime, forKey: "AnalyticsKitEventTimeSeconds")
        }
        return event
    }

}
