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
    
    private func trackViewFor(_ title: String, _ viewID: String, forSection section: String, inEvent event: String) {
        checkSections()
        
        let joinedTitle = title.replacingLastOccurrenceOfString("\n", with: " ")
        let trimToCharacter = 5
        let shortString = String(joinedTitle.prefix(trimToCharacter))
        
        print("CB1234 -- Pushing to CB -> SECTION: \(section), VIEWID: \(viewID), TITLE: \(shortString), for EVENT: \(event)")
        
        CBTracker.shared().sections.append(section)
        CBTracker.shared().trackView(nil, viewId: viewID, title: shortString)
    }
    
    public func logEvent(_ event: String, withProperties properties: [String : Any]) {
        
        print("CB123 -> event: \(event)")
        
        if event == AnalyticsEvent.Content.contentSelected {
            let section = getValue(for: "streamName", in: properties)
            let viewID = getValue(for: "contentID", in: properties)
            let title = getValue(for: "title", in: properties)
            
            trackViewFor(title, viewID, forSection: section, inEvent: event)
        } else if event == AnalyticsEvent.Content.contentViewed {
            stopTrackerFor(event)
            
        } else if event == AnalyticsEvent.Gamecast.gamecastSelected {
            let streamName = getValue(for: "streamName", in: properties)
            let streamID = getValue(for: "streamID", in: properties)
            let title = getValue(for: "title", in: properties)
            
            trackViewFor(title, streamID, forSection: streamName, inEvent: event)
        } else if event == "Gamecast Summary" {
            stopTrackerFor(event)
            
        }
    }
    
    private func checkSections() {
        if CBTracker.shared().sections.isEmpty {
            CBTracker.shared().sections = []
        }
    }
    
    private func stopTrackerFor(_ event: String) {
        print("CB1234 -- Stopping Tracker for EVENT: \(event)")
        CBTracker.shared().stop()
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
