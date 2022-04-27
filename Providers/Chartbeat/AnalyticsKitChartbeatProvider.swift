//
//  AnalyticsKitChartbeatProvider.swift
//  Team Stream
//
//  Created by Fernando Putallaz on 14/03/2022.
//  Copyright © 2022 Bleacher Report. All rights reserved.
//

import Foundation
import Chartbeat

public class AnalyticsKitChartbeatProvider: NSObject, AnalyticsKitProvider {
    public func applicationWillEnterForeground() {}
    public func applicationDidEnterBackground() {}
    public func applicationWillTerminate() {}
    public func uncaughtException(_ exception: NSException) {}
    public func logScreen(_ screenName: String) {}
    public func logScreen(_ screenName: String, withProperties properties: [String : Any]) {}
    public func logEvent(_ event: String) {}
    public func logEvent(_ event: String, withProperty key: String, andValue value: String) {}
    public func logEvent(_ event: String, timed: Bool) {}
    public func logEvent(_ event: String, withProperties properties: [String : Any], timed: Bool) {}
    public func endTimedEvent(_ event: String, withProperties properties: [String : Any]) {}
    public func logError(_ name: String, message: String?, properties: [String : Any]?, exception: NSException?) {}
    public func logError(_ name: String, message: String?, properties: [String : Any]?, error: Error?) {}
    
    public func logEvent(_ event: String, withProperties properties: [String : Any]) {
        
        if event == AnalyticsEvent.Content.contentSelected {
            let streamName = getValue(for: "streamName", in: properties)
            let contentID = getValue(for: "contentID", in: properties)
            let title = getValue(for: "title", in: properties)
            let author = getValue(for: "author", in: properties)
            
            if CBTracker.shared().sections.isEmpty {
                CBTracker.shared().sections = []
            }
            
            print("Chartbeat12345 values to send are SECTION: \(streamName), VIEWiD: \(contentID), TITLE: \(title), for EVENT: \(event) - Author \(author) ")
        
            CBTracker.shared().sections.append(streamName)
            CBTracker.shared().trackView(nil, viewId: contentID, title: title)
        }
    }
    
    private func getValue(for key: String, in properties: [String: Any]) -> String {
        var value = ""
        for i in properties {
            if i.key == key {
                value = "\(i.value)"
            }
        }
        return value
    }
}
