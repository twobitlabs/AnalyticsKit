import Foundation
import Intercom

public class AnalyticsKitIntercomProvider: NSObject, AnalyticsKitProvider {

    // MARK: - Log Screens

    public func logScreen(_ screenName: String) {

    }

    public func logScreen(_ screenName: String, withProperties properties: [String: Any]) {

    }

    // MARK: - Log Events

    public func logEvent(_ event: String) {

    }

    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {

    }

    public func logEvent(_ event: String, withProperties properties: [String: Any]) {

    }

    public func logEvent(_ event: String, timed: Bool) {

    }

    public func logEvent(_ event: String, withProperties properties: [String: Any], timed: Bool) {

    }

    public func endTimedEvent(_ event: String, withProperties properties: [String: Any]) {

    }

    // MARK: - Log Errors

    public func logError(_ name: String, message: String?, exception: NSException?) {

    }

    public func logError(_ name: String, message: String?, error: Error?) {

    }

    public func uncaughtException(_ exception: NSException) {

    }
}
