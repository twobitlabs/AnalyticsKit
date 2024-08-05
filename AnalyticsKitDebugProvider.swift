import Foundation
import UIKit

public class AnalyticsKitDebugProvider: NSObject, AnalyticsKitProvider {
    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}
    public func logScreen(_ screenName: String) {}
    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {}
    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {}

    fileprivate weak var alertController: UIAlertController?

    // Logging
    public func logEvent(_ event: String) { }
    public func logEvent(_ event: String, withProperty key: String, andValue value: String) { }
    public func logEvent(_ event: String, withProperties properties: [String: Any]) { }

    public func logEvent(_ event: String, timed: Bool) {
        logEvent(event)
    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {
        logEvent(event, withProperties: properties)
    }
    
    public func logError(_ name: String, message: String?, properties: [String: Any]?, exception: NSException?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(propertiesString(for: properties) ?? "nil")\n\n\(exception?.description ?? "nil")"
        showAlert(message)
    }

    public func logError(_ name: String, message: String?, properties: [String: Any]?, error: Error?) {
        let message = "\(name)\n\n\(message ?? "nil")\n\n\(propertiesString(for: properties) ?? "nil")\n\n\(error?.localizedDescription ?? "nil")"
        showAlert(message)
    }

    private func propertiesString(for properties: [String: Any]?) -> String? {
        guard let properties = properties else { return nil }
        var stringArray = [String]()
        for (key, value) in properties {
            stringArray.append("\(key): \(value)")
        }
        return stringArray.joined(separator: "\n")
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
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController)
        self.alertController = alertController
    }

    fileprivate func present(_ alertController: UIAlertController) {
        let keyWindow: UIWindow? = {
            if #available(iOS 15, *) {
                // Use connectedScenes to find the key window for iOS 15 and later
                return UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
            } else {
                // Use windows for iOS 13 and 14, and keyWindow for iOS 12 and earlier
                return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.keyWindow
            }
        }()
        if let rootVC = keyWindow?.rootViewController {
            presentFromController(alertController, controller: rootVC)
        }
    }

    fileprivate func presentFromController(_ alertController: UIAlertController, controller: UIViewController) {
        if let presentedController = controller.presentedViewController {
            presentFromController(alertController, controller: presentedController)
        } else if let navVC = controller as? UINavigationController, let visibleVC = navVC.visibleViewController {
            presentFromController(alertController, controller: visibleVC)
        } else if let tabVC = controller as? UITabBarController, let selectedVC = tabVC.selectedViewController {
            presentFromController(alertController, controller: selectedVC)
        } else {
            controller.present(alertController, animated: true, completion: nil)
        }
    }
}
