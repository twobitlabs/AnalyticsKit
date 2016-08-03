import Foundation

@objc protocol AnalyticsKitProvider {
    func applicationWillEnterForeground()
    func applicationDidEnterBackground()
    func applicationWillTerminate()
    func uncaughtException(exception: NSException)
    func logScreen(screenName: String)
    func logEvent(event: String)
    func logEvent(event: String, withProperty key: String, andValue value: String)
    func logEvent(event: String, withProperties dict: [String: AnyObject])
    func logEvent(event: String, timed: Bool)
    func logEvent(event: String, withProperties dict: [String: AnyObject], timed: Bool)
    func endTimedEvent(event: String, withProperties dict: [String: AnyObject])
    func logError(name: String, message: String?, exception: NSException?)
    func logError(name: String, message: String?, error: NSError?)
}

class AnalyticsKit: NSObject {
    private static let DefaultChannel = "defaultChannel"
    private let simulator = TARGET_IPHONE_SIMULATOR == 1

    private static var channels = [String: AnalyticsKitChannel]()

    class func initializeLoggers(loggers: [AnalyticsKitProvider]) {
        channel(DefaultChannel).initializeLoggers(loggers)
    }
    
    class func loggers() -> [AnalyticsKitProvider] {
        return channel(DefaultChannel).loggers
    }

    class func channel(channelName: String) -> AnalyticsKitChannel {
        guard let channel = channels[channelName] else {
            AKLog("Created \(channelName) channel")
            let newChannel = AnalyticsKitChannel(channelName: channelName, loggers: [AnalyticsKitProvider]())
            channels[channelName] = newChannel
            return newChannel
        }
        return channel
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

    class func uncaughtException(exception: NSException) {
        for (_, channel) in channels {
            channel.uncaughtException(exception)
        }
    }

    class func logScreen(screenName: String) {
        channel(DefaultChannel).logScreen(screenName)
    }
    
    class func logEvent(event: String) {
        channel(DefaultChannel).logEvent(event)
    }
    
    class func logEvent(event: String, withProperty property: String, andValue value: String) {
        channel(DefaultChannel).logEvent(event, withProperty: property, andValue: value)
    }
    
    class func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        channel(DefaultChannel).logEvent(event, withProperties: properties)
    }
    
    class func logEvent(event: String, timed: Bool) {
        channel(DefaultChannel).logEvent(event, timed: timed)
    }
    
    class func logEvent(event: String, withProperties properties: [String: AnyObject], timed: Bool) {
        channel(DefaultChannel).logEvent(event, withProperties: properties, timed: timed)
    }
    
    class func endTimedEvent(event: String, withProperties properties: [String: AnyObject]) {
        channel(DefaultChannel).endTimedEvent(event, withProperties: properties)
    }
    
    class func logError(name: String, message: String?, exception: NSException?) {
        channel(DefaultChannel).logError(name, message: message, exception: exception)
    }
    
    class func logError(name: String, message: String?, error: NSError?) {
        channel(DefaultChannel).logError(name, message: message, error: error)
    }
    
}

class AnalyticsKitChannel: NSObject, AnalyticsKitProvider {
    let channelName: String
    var loggers: [AnalyticsKitProvider]

    init(channelName: String, loggers: [AnalyticsKitProvider]) {
        self.channelName = channelName
        self.loggers = loggers
    }

    func initializeLoggers(loggers: [AnalyticsKitProvider]) {
        self.loggers = loggers
    }

    func applicationWillEnterForeground() {
        AKLog("")
        for provider in loggers {
            provider.applicationWillEnterForeground()
        }
    }

    func applicationDidEnterBackground() {
        AKLog("")
        for provider in loggers {
            provider.applicationDidEnterBackground()
        }
    }

    func applicationWillTerminate() {
        AKLog("")
        for provider in loggers {
            provider.applicationWillTerminate()
        }
    }

    func uncaughtException(exception: NSException) {
        AKLog("\(exception.description)")
        for provider in loggers {
            provider.uncaughtException(exception)
        }
    }

    func logScreen(screenName: String) {
        AKLog("\(screenName)")
        for provider in loggers {
            provider.logScreen(screenName)
        }
    }

    func logEvent(event: String) {
        AKLog("\(event)")
        for provider in loggers {
            provider.logEvent(event)
        }
    }

    func logEvent(event: String, withProperty property: String, andValue value: String) {
        AKLog("\(event) withProperty: \(property) andValue: \(value)")
        for provider in loggers {
            provider.logEvent(event)
        }
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        AKLog("\(event) withProperties: \(properties.description)")
        for provider in loggers {
            provider.logEvent(event, withProperties: properties)
        }
    }

    func logEvent(event: String, timed: Bool) {
        AKLog("\(event) timed: \(timed)")
        for provider in loggers {
            provider.logEvent(event, timed: timed)
        }
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject], timed: Bool) {
        AKLog("\(event) withProperties: \(properties) timed: \(timed)")
        for provider in loggers {
            provider.logEvent(event, withProperties: properties, timed: timed)
        }
    }

    func endTimedEvent(event: String, withProperties properties: [String: AnyObject]) {
        AKLog("\(event) withProperties: \(properties)")
        for provider in loggers {
            provider.endTimedEvent(event, withProperties: properties)
        }
    }

    func logError(name: String, message: String?, exception: NSException?) {
        AKLog("\(name) message: \(message ?? "nil") exception: \(exception ?? "nil")")
        for provider in loggers {
            provider.logError(name, message: message, exception: exception)
        }
    }

    func logError(name: String, message: String?, error: NSError?) {
        AKLog("\(name) message: \(message ?? "nil") error: \(error ?? "nil")")
        for provider in loggers {
            provider.logError(name, message: message, error: error)
        }
    }
}

func AKLog<T>(@autoclosure object: () -> T, _ file: String = #file, _ function: String = #function, _ line: Int = #line)
{
    #if DEBUG
        let value = object()
        let message: String
        if let value = value as? CustomDebugStringConvertible {
            message = value.debugDescription
        } else if let value = value as? CustomStringConvertible {
            message = value.description
        } else {
            message = ""
        }
        let fileURL = NSURL(string: file)?.lastPathComponent ?? "Unknown"
        NSLog("\(fileURL) | \(function)[\(line)]: " + message)
    #endif
}
