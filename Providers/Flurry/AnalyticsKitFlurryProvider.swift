import Foundation

class AnalyticsKitFlurryProvider: NSObject, AnalyticsKitProvider {

    init(withAPIKey apiKey: String) {
        Flurry.startSession(apiKey)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(_ exception: NSException) {
        let message = "Crash on iOS \(UIDevice.current.systemVersion)"
        Flurry.logError("Uncaught", message: message, exception: exception)
    }

    // Logging
    func logScreen(_ screenName: String) {
        runOnMainThread {
            Flurry.logEvent("Screen - \(screenName)")
        }
    }

    func logScreen(_ screenName: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            Flurry.logEvent("Screen - \(screenName)", withParameters: properties)
        }
    }

    func logEvent(_ event: String) {
        runOnMainThread { 
            Flurry.logEvent(event)
        }
    }

    func logEvent(_ event: String, withProperty key: String, andValue value: String) {
        runOnMainThread { 
            Flurry.logEvent(event, withParameters: [key: value])
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties)
        }
    }

    func logEvent(_ event: String, timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, timed: timed)
        }
    }

    func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties, timed: timed)
        }
    }

    func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {
        runOnMainThread {
            // non-nil parameters will update the parameters
            Flurry.endTimedEvent(event, withParameters: properties)
        }
    }

    func logError(_ name: String, message: String?, exception: NSException?) {
        runOnMainThread { 
            Flurry.logError(name, message: message, exception: exception)
        }
    }

    func logError(_ name: String, message: String?, error: NSError?) {
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
