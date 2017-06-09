import UIKit

@UIApplicationMain
class AnalyticsKitAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsKit.initializeProviders([AnalyticsKitDebugProvider()])
        AnalyticsKit.logEvent("App started")
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AnalyticsKit.applicationWillEnterForeground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsKit.applicationDidEnterBackground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AnalyticsKit.applicationWillTerminate()
    }
}
