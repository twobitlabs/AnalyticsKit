import Foundation

@objc protocol AnalyticsKitProvider {
    func applicationWillEnterForeground()
    func applicationDidEnterBackground()
    func applicationWillTerminate()
    func uncaughtException(_ exception: NSException)
    func logScreen(_ screenName: String)
    func logScreen(_ screenName: String, withProperties properties: [String: Any])
    func logEvent(_ event: String)
    func logEvent(_ event: String, withProperty key: String, andValue value: String)
    func logEvent(_ event: String, withProperties properties: [String: Any])
    func logEvent(_ event: String, timed: Bool)
    func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool)
    func endTimedEvent(_ event: String, withProperties properties: [String: Any])
    func logError(_ name: String, message: String?, exception: NSException?)
    func logError(_ name: String, message: String?, error: NSError?)
}

class AnalyticsKit: NSObject {
    fileprivate static let DefaultChannel = "default"

    static var channels = [String: AnalyticsKitChannel]()

    class func initializeProviders(_ providers: [AnalyticsKitProvider]) {
        channel(DefaultChannel).initializeProviders(providers)
    }
    
    class func providers() -> [AnalyticsKitProvider] {
        return channel(DefaultChannel).providers
    }

    class func channel(_ channelName: String) -> AnalyticsKitChannel {
        guard let channel = channels[channelName] else {
            AKLog("Created \(channelName) channel")
            let newChannel = AnalyticsKitChannel(channelName: channelName, providers: [AnalyticsKitProvider]())
            channels[channelName] = newChannel
            return newChannel
        }
        return channel
    }

    class func defaultChannel() -> AnalyticsKitChannel {
        return channel(DefaultChannel)
    }
    
    class func applicationWillEnterForeground() {
        for (_, channel) in channels {
            channel.applicationWillEnterForeground()
        }
    }
    
    class func applicationDidEnterBackground() {
        for (_, channel) in channels {
            channel.applicationDidEnterBackground()
        }
    }

    class func applicationWillTerminate() {
        for (_, channel) in channels {
            channel.applicationWillTerminate()
        }
    }

    class func uncaughtException(_ exception: NSException) {
        for (_, channel) in channels {
            channel.uncaughtException(exception)
        }
    }

    class func logScreen(_ screenName: String) {
        channel(DefaultChannel).logScreen(screenName)
    }

    class func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).logScreen(screenName, withProperties: properties)
    }

    class func logEvent(_ event: String) {
        channel(DefaultChannel).logEvent(event)
    }
    
    class func logEvent(_ event: String, withProperty property: String, andValue value: String) {
        channel(DefaultChannel).logEvent(event, withProperty: property, andValue: value)
    }
    
    class func logEvent(_ event: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).logEvent(event, withProperties: properties)
    }
    
    class func logEvent(_ event: String, timed: Bool) {
        channel(DefaultChannel).logEvent(event, timed: timed)
    }
    
    class func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        channel(DefaultChannel).logEvent(event, withProperties: properties, timed: timed)
    }
    
    class func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).endTimedEvent(event, withProperties: properties)
    }
    
    class func logError(_ name: String, message: String?, exception: NSException?) {
        channel(DefaultChannel).logError(name, message: message, exception: exception)
    }
    
    class func logError(_ name: String, message: String?, error: NSError?) {
        channel(DefaultChannel).logError(name, message: message, error: error)
    }
    
}

class AnalyticsKitChannel: NSObject, AnalyticsKitProvider {
    let channelName: String
    var providers: [AnalyticsKitProvider]

    init(channelName: String, providers: [AnalyticsKitProvider]) {
        self.channelName = channelName
        self.providers = providers
    }

    func initializeProviders(_ providers: [AnalyticsKitProvider]) {
        self.providers = providers
    }

    func applicationWillEnterForeground() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationWillEnterForeground()
        }
    }

    func applicationDidEnterBackground() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationDidEnterBackground()
        }
    }

    func applicationWillTerminate() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationWillTerminate()
        }
    }

    func uncaughtException(_ exception: NSException) {
        AKLog("\(channelName) \(exception.description)")
        for provider in providers {
            provider.uncaughtException(exception)
        }
    }

    func logScreen(_ screenName: String) {
        AKLog("\(channelName) \(screenName)")
        for provider in providers {
            provider.logScreen(screenName)
        }
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(screenName) withProperties: \(properties.description)")
        for provider in providers {
            provider.logScreen(screenName, withProperties: properties)
        }
    }

    func logEvent(_ event: String) {
        AKLog("\(channelName) \(event)")
        for provider in providers {
            provider.logEvent(event)
        }
    }

    func logEvent(_ event: String, withProperty property: String, andValue value: String) {
        AKLog("\(channelName) \(event) withProperty: \(property) andValue: \(value)")
        for provider in providers {
            provider.logEvent(event)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(event) withProperties: \(properties.description)")
        for provider in providers {
            provider.logEvent(event, withProperties: properties)
        }
    }

    func logEvent(_ event: String, timed: Bool) {
        AKLog("\(channelName) \(event) timed: \(timed)")
        for provider in providers {
            provider.logEvent(event, timed: timed)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        AKLog("\(channelName) \(event) withProperties: \(properties) timed: \(timed)")
        for provider in providers {
            provider.logEvent(event, withProperties: properties, timed: timed)
        }
    }

    func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(event) withProperties: \(properties)")
        for provider in providers {
            provider.endTimedEvent(event, withProperties: properties)
        }
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        AKLog("\(channelName) \(name) message: \(message ?? "nil") exception: \(exception?.description ?? "nil")")
        for provider in providers {
            provider.logError(name, message: message, exception: exception)
        }
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        AKLog("\(channelName) \(name) message: \(message ?? "nil") error: \(error?.description ?? "nil")")
        for provider in providers {
            provider.logError(name, message: message, error: error)
        }
    }
}

private func AKLog(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    #if DEBUG
        print("\(NSURL(string: file)?.lastPathComponent ?? "") \(function)[\(line)]: \(message)")
    #else
        if message == "" {
            // Workaround for swift compiler optimizer crash
        }
    #endif
}
