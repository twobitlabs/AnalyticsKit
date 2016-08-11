import Foundation
import UIKit

class AnalyticsKitDebugProvider: NSObject, AnalyticsKitProvider {

    private weak var alertController: UIAlertController?

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(exception: NSException) { }

    // Logging
    func logScreen(screenName: String) { }
    func logScreen(screenName: String, withProperties properties: [String : AnyObject]) { }
    func logEvent(event: String) { }
    func logEvent(event: String, withProperty key: String, andValue value: String) { }
    func logEvent(event: String, withProperties properties: [String: AnyObject]) { }
    func logEvent(event: String, timed: Bool) { }
    func logEvent(event: String, withProperties dict: [String: AnyObject], timed: Bool) { }
    func endTimedEvent(event: String, withProperties dict: [String: AnyObject]) { }

    func logError(name: String, message: String?, exception: NSException?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(exception ?? "nil")"
        showAlert(message)
    }

    func logError(name: String, message: String?, error: NSError?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(error ?? "nil")"
        showAlert(message)
    }

    private func showAlert(message: String) {
        if NSThread.isMainThread() {
            showAlertController(message)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.showAlertController(message)
            }
        }
    }

    private func showAlertController(message: String) {
        // dismiss any already visible alert
        if let alertController = self.alertController {
            alertController.dismissViewControllerAnimated(false, completion: nil)
        }

        let alertController = UIAlertController(title: "AnalyticsKit Received Error", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.present(alertController)
        self.alertController = alertController
    }

    private func present(alertController: UIAlertController) {
        if let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController {
            presentFromController(alertController, controller: rootVC)
        }
    }

    private func presentFromController(alertController: UIAlertController, controller: UIViewController) {
        if  let navVC = controller as? UINavigationController, let visibleVC = navVC.visibleViewController {
            presentFromController(alertController, controller: visibleVC)
        } else if let tabVC = controller as? UITabBarController, let selectedVC = tabVC.selectedViewController {
            presentFromController(alertController, controller: selectedVC)
        } else {
            controller.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
