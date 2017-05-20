import Foundation

public class AnalyticsKitEvent: NSObject {

    var name: String
    var properties = [String: Any]()
    var startTime: Date?

    init(event: String) {
        self.name = event
    }

    init(event: String, withProperties properties: [String: Any]) {
        self.name = event
        self.properties = properties
    }

    init(event: String, withKey key: String, andValue value: Any) {
        self.name = event
        self.properties = [key: value]
    }

    func setProperty(_ value: Any, forKey key: String) {
        properties[key] = value
    }

}
