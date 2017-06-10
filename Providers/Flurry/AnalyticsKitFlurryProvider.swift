import Foundation
import Flurry_iOS_SDK

public class AnalyticsKitFlurryProvider: NSObject, AnalyticsKitProvider {

    public init(withAPIKey apiKey: String) {
        Flurry.startSession(apiKey)
    }

    public func uncaughtException(_ exception: NSException) {
        let message = "Crash on iOS \(UIDevice.current.systemVersion)"
        Flurry.logError("Uncaught", message: message, exception: exception)
    }

    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}

    // Logging
    public func logScreen(_ screenName: String) {
        runOnMainThread {
            Flurry.logEvent("Screen - \(screenName)")
        }
    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            Flurry.logEvent("Screen - \(screenName)", withParameters: properties)
        }
    }

    public func logEvent(_ event: String) {
        runOnMainThread { 
            Flurry.logEvent(event)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties)
        }
    }
    
    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        logEvent(event, withProperties: [key: value])
    }

    public func logEvent(_ event: String, timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, timed: timed)
        }
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties, timed: timed)
        }
    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            // non-nil parameters will update the parameters
            Flurry.endTimedEvent(event, withParameters: properties)
        }
    }

    public func logError(_ name: String, message: String?, exception: NSException?) {
        runOnMainThread { 
            Flurry.logError(name, message: message, exception: exception)
        }
    }

    public func logError(_ name: String, message: String?, error: Error?) {
        runOnMainThread {
            Flurry.logError(name, message: message, error: error)
        }
    }

    fileprivate func runOnMainThread(_ block: @escaping () -> Void) {
        //Flurry requires calls to be made from main thread
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: {
                block()
            })
        }
    }
}
