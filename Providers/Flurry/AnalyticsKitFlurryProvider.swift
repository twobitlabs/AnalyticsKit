import Foundation

class AnalyticsKitFlurryProvider: NSObject, AnalyticsKitProvider {

    init(withAPIKey apiKey: String) {
        Flurry.startSession(apiKey)
    }

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }

    func uncaughtException(exception: NSException) {
        let message = "Crash on iOS \(UIDevice.currentDevice().systemVersion)"
        Flurry.logError("Uncaught", message: message, exception: exception)
    }

    // Logging
    func logScreen(screenName: String) {
        runOnMainThread {
            Flurry.logEvent("Screen - \(screenName)")
        }
    }

    func logEvent(event: String) {
        runOnMainThread { 
            Flurry.logEvent(event)
        }
    }

    func logEvent(event: String, withProperty key: String, andValue value: String) {
        runOnMainThread { 
            Flurry.logEvent(event, withParameters: [key: value])
        }
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject]) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties)
        }
    }

    func logEvent(event: String, timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, timed: timed)
        }
    }

    func logEvent(event: String, withProperties properties: [String: AnyObject], timed: Bool) {
        runOnMainThread {
            Flurry.logEvent(event, withParameters: properties, timed: timed)
        }
    }

    func endTimedEvent(event: String, withProperties properties: [String: AnyObject]) {
        runOnMainThread {
            // non-nil parameters will update the parameters
            Flurry.endTimedEvent(event, withParameters: properties)
        }
    }

    func logError(name: String, message: String?, exception: NSException?) {
        runOnMainThread { 
            Flurry.logError(name, message: message, exception: exception)
        }
    }

    func logError(name: String, message: String?, error: NSError?) {
        runOnMainThread {
            Flurry.logError(name, message: message, error: error)
        }
    }

    private func runOnMainThread(block: () -> Void) {
        //Flurry requires calls to be made from main thread
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                block()
            })
        }
    }

}
