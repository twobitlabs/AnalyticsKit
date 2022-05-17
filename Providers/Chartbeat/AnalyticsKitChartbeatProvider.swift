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
        
        print("CB123 -> event: \(event)")
        
        switch event {
        case AnalyticsEvent.Content.contentSelected:
            let section = getValue(for: "streamName", in: properties)
            let viewID = getValue(for: "contentID", in: properties)
            let title = getValue(for: "title", in: properties)

            trackView(withTitle: title, withViewID: viewID, forSection: section, inEvent: event)

        case AnalyticsEvent.Gamecast.gamecastSelected:
            let streamName = getValue(for: "streamName", in: properties)
            let streamID = getValue(for: "streamID", in: properties)
            let title = getValue(for: "title", in: properties)

            trackView(withTitle: title + " (Gamecast)", withViewID: streamName, forSection: streamID, inEvent: event)

        case "Screen Viewed":
            let screenValue = getValue(for: "screenValue", in: properties)
            let screen = getValue(for: "screen", in: properties)
            let tag = getValue(for: "tag", in: properties)

            print("CB123 -> event Screen Viewed: \(event), screen: \(screen), screenValue: \(screenValue), tag: \(tag)")
            
            for allowed in ScreenViewedScreensAllowed.allCases {
                if screen == allowed.rawValue  {
                    trackView(withTitle: "\(screenValue) \(tag) (\(screen))", withViewID: screen, forSection: screen, inEvent: event)
                }
            }

        default:
            print("some")
        }
    }
    
    enum ScreenViewedScreensAllowed: String, CaseIterable {
        case streamNews = "Stream - News"
        case streamCommunity = "Stream - Community"
        case streamStandings = "Stream - Standings" //this one is dinamyc - let's see.
        case streamSchedule = "Stream - Team - Schedule"
        case tabHome = "Home"
        case tabScores = "Scores"
        case tabMyBR = "My B/R"
        case tabFire = "Fire"
        case tabAlerts = "Alerts"
    }

    private func trackView(withTitle title: String, withViewID viewID: String, forSection section: String, inEvent event: String) {
        checkSections()
        
        let joinedTitle = title.replacingLastOccurrenceOfString("\n", with: " ")
        let trimToCharacter = 90
        let shortString = String(joinedTitle.prefix(trimToCharacter))
        
        print("CB1234 -- Pushing to CB -> SECTION: \(section), VIEWID: \(String(describing: viewID)), TITLE: \(shortString), for EVENT: \(event)")
        
        CBTracker.shared().sections.append(section)
        CBTracker.shared().trackView(nil, viewId: viewID, title: shortString)
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
