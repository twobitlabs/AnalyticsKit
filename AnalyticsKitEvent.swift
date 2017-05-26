import Foundation

public class AnalyticsKitEvent: NSObject {

    public var name: String
    public var properties = [String: Any]()
    public var startTime: Date?

    public init(event: String) {
        self.name = event
    }

    public init(event: String, withProperties properties: [String: Any]) {
        self.name = event
        self.properties = properties
    }

    public init(event: String, withKey key: String, andValue value: Any) {
        self.name = event
        self.properties = [key: value]
    }

    public func setProperty(_ value: Any, forKey key: String) {
        properties[key] = value
    }

}
