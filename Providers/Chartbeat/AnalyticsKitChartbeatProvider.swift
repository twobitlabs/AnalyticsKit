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
            
        //Not yet tested since dk where to fire it
        case AnalyticsEvent.Content.roomSelected:
            let roomName = getValue(for: "roomName", in: properties)

            trackView(withTitle: roomName + " (Room)", withViewID: roomName, forSection: roomName, inEvent: event)
            
        case AnalyticsEvent.Betting.packSelected:
            let packTitle = getValue(for: "packTitle", in: properties)

            trackView(withTitle: packTitle + " (Perfect Picks)", withViewID: packTitle, forSection: packTitle, inEvent: event)

        case "Screen Viewed":
            let screenValue = getValue(for: "screenValue", in: properties)
            let screen = getValue(for: "screen", in: properties)
            let tag = getValue(for: "tag", in: properties)

            for allowed in ScreenViewedScreensAllowed.allCases {
                if screen == allowed.rawValue  {
                    trackView(withTitle: "\(screenValue) \(tag) (\(screen))", withViewID: screen, forSection: screen, inEvent: event)
                }
            }

        default:
            print("some")
        }
    }
    
    private enum ScreenViewedScreensAllowed: String, CaseIterable {
        case streamNews = "Stream - News"
        case streamCommunity = "Stream - Community"
        case streamSchedule = "Stream - Team - Schedule"
        case tabHome = "Home"
        case tabScores = "Scores"
        case tabMyBR = "My B/R"
        case tabFire = "Fire"
        case tabAlerts = "Alerts"
        case happeningNow = "Happening Now"
        
        case streamStandings1 = "Standings - World_Football - Africa Cup of Nations"
        case streamStandings2 = "Standings - College_Football - Mountain West"
        case streamStandings3 = "Standings - World_Football - Copa America"
        case streamStandings4 = "Standings - - Champions League"
        case streamStandings5 = "Standings - World_Football - Gold Cup"
        case streamStandings6 = "Standings - Soccer - Africa Cup of Nations"
        case streamStandings7 = "Standings - World_Football - Primeira Liga"
        case streamStandings8 = "Standings - World_Football - World Cup"
        case streamStandings9 = "Standings - College_Basketball - ACC"
        case streamStandings10 = "Standings - World_Football - Liga MX"
        case streamStandings11 = "Standings - College_Football - Big 12"
        case streamStandings12 = "Standings - College_Basketball - Big 12"
        case streamStandings13 = "Standings - College_Football - ACC"
        case streamStandings14 = "Standings - College_Football - SEC"
        case streamStandings15 = "Standings - WORLD-FOOTBALL - STANDINGS"
        case streamStandings16 = "Standings - World_Football - National Women's Soccer League"
        case streamStandings17 = "Standings - COLLEGE-FOOTBALL - STANDINGS"
        case streamStandings18 = "Standings - World_Football - Brasileiro Serie A"
        case streamStandings19 = "Standings - - Primeira Liga"
        case streamStandings20 = "Standings - - Eredivisie"
        case streamStandings21 = "Standings - Motorsports - Drivers"
        case streamStandings22 = "Standings - - Ligue 1"
        case streamStandings23 = "Standings - - Championship"
        case streamStandings24 = "Standings - Soccer - Bundesliga"
        case streamStandings25 = "Standings - Soccer - MLS"
        case streamStandings26 = "Standings - Formula1 - Constructors"
        case streamStandings27 = "Standings - Womens_College_Basketball - SEC"
        case streamStandings28 = "Standings - World_Football - Liga MX (Clausura)"
        case streamStandings29 = "Standings - World_Football - UEFA Nations League"
        case streamStandings30 = "Standings - World_Football - Europa Conference League"
        case streamStandings31 = "Standings - World_Football - Bundesliga"
        case streamStandings32 = "Standings - - Serie A"
        case streamStandings33 = "Standings - World_Football - Ligue 1"
        case streamStandings34 = "Standings - - Bundesliga"
        case streamStandings35 = "Standings - - MLS"
        case streamStandings36 = "Standings - - First Division A"
        case streamStandings37 = "Standings - Soccer - Champions League"
        case streamStandings38 = "Standings - Soccer - Europa League"
        case streamStandings39 = "Standings - World_Football - Championship"
        case streamStandings40 = "Standings - World_Football - Champions League"
        case streamStandings41 = "Standings - World_Football - MLS"
        case streamStandings42 = "Standings - WNBA - Conference"
        case streamStandings43 = "Standings - Soccer - Serie A"
        case streamStandings44 = "Standings - Soccer - La Liga"
        case streamStandings45 = "Standings - - Liga MX (Clausura)"
        case streamStandings46 = "Standings - Soccer - Int. Champions Cup"
        case streamStandings47 = "Standings - NHL - Wild Card"
        case streamStandings48 = "Standings - NFL - Conference"
        case streamStandings49 = "Standings - Formula1 - Drivers"
        case streamStandings50 = "Standings - NHL - Conference"
        case streamStandings51 = "Standings - CFB - CFP Rankings"
        case streamStandings52 = "Standings - NBA - League"
        case streamStandings53 = "Standings - NBA - Tank"
        case streamStandings54 = "Standings - World_Football - Serie A"
        case streamStandings55 = "Standings - World_Football - La Liga"
        case streamStandings56 = "Standings - College_Basketball - AP 25"
        case streamStandings57 = "Standings - World_Football - Europa League"
        case streamStandings58 = "Standings - World_Football - Int. Champions Cup"
        case streamStandings59 = "Standings - College_Football - CFP Rankings"
        case streamStandings60 = "Standings - - La Liga"
        case streamStandings61 = "Standings - Soccer - Premier League"
        case streamStandings62 = "Standings - NHL - Division"
        case streamStandings63 = "Standings - MLB - Division"
        case streamStandings64 = "Standings - NFL - Division"
        case streamStandings65 = "Standings - NBA - Conference"
        case streamStandings66 = "Standings - World_Football - Premier League"
        case streamStandings67 = "Standings - - Premier League"
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
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
