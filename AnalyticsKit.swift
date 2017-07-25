import Foundation

@objc public protocol AnalyticsKitProvider {
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
    func logError(_ name: String, message: String?, error: Error?)
}

public class AnalyticsKit: NSObject {
    fileprivate static let DefaultChannel = "default"

    static var channels = [String: AnalyticsKitChannel]()

    public class func initializeProviders(_ providers: [AnalyticsKitProvider]) {
        channel(DefaultChannel).initializeProviders(providers)
    }
    
    public class func providers() -> [AnalyticsKitProvider] {
        return channel(DefaultChannel).providers
    }

    public class func channel(_ channelName: String) -> AnalyticsKitChannel {
        guard let channel = channels[channelName] else {
            AKLog("Created \(channelName) channel")
            let newChannel = AnalyticsKitChannel(channelName: channelName, providers: [AnalyticsKitProvider]())
            channels[channelName] = newChannel
            return newChannel
        }
        return channel
    }

    public class func defaultChannel() -> AnalyticsKitChannel {
        return channel(DefaultChannel)
    }
    
    public class func applicationWillEnterForeground() {
        for (_, channel) in channels {
            channel.applicationWillEnterForeground()
        }
    }
    
    public class func applicationDidEnterBackground() {
        for (_, channel) in channels {
            channel.applicationDidEnterBackground()
        }
    }

    public class func applicationWillTerminate() {
        for (_, channel) in channels {
            channel.applicationWillTerminate()
        }
    }

    public class func uncaughtException(_ exception: NSException) {
        for (_, channel) in channels {
            channel.uncaughtException(exception)
        }
    }

    public class func logScreen(_ screenName: String) {
        channel(DefaultChannel).logScreen(screenName)
    }

    public class func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).logScreen(screenName, withProperties: properties)
    }

    public class func logEvent(_ event: String) {
        channel(DefaultChannel).logEvent(event)
    }
    
    public class func logEvent(_ event: String, withProperty property: String, andValue value: String) {
        channel(DefaultChannel).logEvent(event, withProperty: property, andValue: value)
    }
    
    public class func logEvent(_ event: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).logEvent(event, withProperties: properties)
    }
    
    public class func logEvent(_ event: String, timed: Bool) {
        channel(DefaultChannel).logEvent(event, timed: timed)
    }
    
    public class func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        channel(DefaultChannel).logEvent(event, withProperties: properties, timed: timed)
    }
    
    public class func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        channel(DefaultChannel).endTimedEvent(event, withProperties: properties)
    }
    
    public class func logError(_ name: String, message: String?, exception: NSException?) {
        channel(DefaultChannel).logError(name, message: message, exception: exception)
    }
    
    public class func logError(_ name: String, message: String?, error: Error?) {
        channel(DefaultChannel).logError(name, message: message, error: error)
    }
}

public class AnalyticsKitChannel: NSObject, AnalyticsKitProvider {
    let channelName: String
    var providers: [AnalyticsKitProvider]

    public init(channelName: String, providers: [AnalyticsKitProvider]) {
        self.channelName = channelName
        self.providers = providers
    }

    public func initializeProviders(_ providers: [AnalyticsKitProvider]) {
        self.providers = providers
    }

    public func applicationWillEnterForeground() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationWillEnterForeground()
        }
    }

    public func applicationDidEnterBackground() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationDidEnterBackground()
        }
    }

    public func applicationWillTerminate() {
        AKLog("\(channelName)")
        for provider in providers {
            provider.applicationWillTerminate()
        }
    }

    public func uncaughtException(_ exception: NSException) {
        AKLog("\(channelName) \(exception.description)")
        for provider in providers {
            provider.uncaughtException(exception)
        }
    }

    public func logScreen(_ screenName: String) {
        AKLog("\(channelName) \(screenName)")
        for provider in providers {
            provider.logScreen(screenName)
        }
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(screenName) withProperties: \(properties.description)")
        for provider in providers {
            provider.logScreen(screenName, withProperties: properties)
        }
    }

    public func logEvent(_ event: String) {
        AKLog("\(channelName) \(event)")
        for provider in providers {
            provider.logEvent(event)
        }
    }

    public func logEvent(_ event: String, withProperty property: String, andValue value: String) {
        AKLog("\(channelName) \(event) withProperty: \(property) andValue: \(value)")
        for provider in providers {
            provider.logEvent(event, withProperty: property, andValue: value)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(event) withProperties: \(properties.description)")
        for provider in providers {
            provider.logEvent(event, withProperties: properties)
        }
    }

    public func logEvent(_ event: String, timed: Bool) {
        AKLog("\(channelName) \(event) timed: \(timed)")
        for provider in providers {
            provider.logEvent(event, timed: timed)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        AKLog("\(channelName) \(event) withProperties: \(properties) timed: \(timed)")
        for provider in providers {
            provider.logEvent(event, withProperties: properties, timed: timed)
        }
    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        AKLog("\(channelName) \(event) withProperties: \(properties)")
        for provider in providers {
            provider.endTimedEvent(event, withProperties: properties)
        }
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        AKLog("\(channelName) \(name) message: \(message ?? "nil") exception: \(exception?.description ?? "nil")")
        for provider in providers {
            provider.logError(name, message: message, exception: exception)
        }
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        AKLog("\(channelName) \(name) message: \(message ?? "nil") error: \(error?.localizedDescription ?? "nil")")
        for provider in providers {
            provider.logError(name, message: message, error: error)
        }
    }
}

private func AKLog(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    #if DEBUG
        print("\(URL(string: file)?.lastPathComponent ?? "") \(function)[\(line)]: \(message)")
    #else
        if message == "" {
            // Workaround for swift compiler optimizer crash
        }
    #endif
}
