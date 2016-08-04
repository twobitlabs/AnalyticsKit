import Foundation

class AnalyticsKitEvent: NSObject {

    var name: String
    var properties = [String: AnyObject]()
    var startTime: NSDate?

    init(event: String) {
        self.name = event
    }

    init(event: String, withProperties properties: [String : AnyObject]) {
        self.name = event
        self.properties = properties
    }

    init(event: String, withKey key: String, andValue value: AnyObject) {
        self.name = event
        self.properties = [key: value]
    }

    func setProperty(value: AnyObject, forKey key: String) {
        properties[key] = value
    }

}