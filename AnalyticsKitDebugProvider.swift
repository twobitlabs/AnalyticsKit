import Foundation
import UIKit

class AnalyticsKitDebugProvider: NSObject, AnalyticsKitProvider {

    fileprivate weak var alertController: UIAlertController?

    // Lifecycle
    func applicationWillEnterForeground() { }
    func applicationDidEnterBackground() { }
    func applicationWillTerminate() { }
    func uncaughtException(_ exception: NSException) { }

    // Logging
    func logScreen(_ screenName: String) { }
    func logScreen(_ screenName: String, withProperties properties: [String: Any]) { }
    func logEvent(_ event: String) { }
    func logEvent(_ event: String, withProperty key: String, andValue value: String) { }
    func logEvent(_ event: String, withProperties properties: [String: Any]) { }
    func logEvent(_ event: String, timed: Bool) { }
    func logEvent(_ event: String, withProperties dict: [String: Any], timed: Bool) { }
    func endTimedEvent(_ event: String, withProperties dict: [String: Any]) { }

    func logError(_ name: String, message: String?, exception: NSException?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(exception?.description ?? "nil")"
        showAlert(message)
    }

    func logError(_ name: String, message: String?, error: NSError?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(error?.description ?? "nil")"
        showAlert(message)
    }

    fileprivate func showAlert(_ message: String) {
        if Thread.isMainThread {
            showAlertController(message)
        } else {
            DispatchQueue.main.async {
                self.showAlertController(message)
            }
        }
    }

    fileprivate func showAlertController(_ message: String) {
        // dismiss any already visible alert
        if let alertController = self.alertController {
            alertController.dismiss(animated: false, completion: nil)
        }

        let alertController = UIAlertController(title: "AnalyticsKit Received Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController)
        self.alertController = alertController
    }

    fileprivate func present(_ alertController: UIAlertController) {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            presentFromController(alertController, controller: rootVC)
        }
    }

    fileprivate func presentFromController(_ alertController: UIAlertController, controller: UIViewController) {
        if  let navVC = controller as? UINavigationController, let visibleVC = navVC.visibleViewController {
            presentFromController(alertController, controller: visibleVC)
        } else if let tabVC = controller as? UITabBarController, let selectedVC = tabVC.selectedViewController {
            presentFromController(alertController, controller: selectedVC)
        } else {
            controller.present(alertController, animated: true, completion: nil)
        }
    }
}
