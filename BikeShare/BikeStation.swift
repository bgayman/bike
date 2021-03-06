//
//  BikeStation.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif
import CoreLocation
import CoreText

struct BikeStation
{
    let name: String
    let timestamp: Date
    let coordinates: CLLocationCoordinate2D
    let freeBikes: Int?
    let emptySlots: Int?
    let id: String
    let address: String?
    var gbfsStationInformation: GBFSStationInformation? = nil
    var searchString = ""
    
    var statusDisplayText: String
    {
        guard let freeBikes = self.freeBikes,
              let emptySlots = self.emptySlots
        else { return "🤷‍♀️" }
        var status = "\(freeBikes) 🚲, \(emptySlots) 🆓"
        if self.gbfsStationInformation?.stationStatus?.isRenting == false ||
           self.gbfsStationInformation?.stationStatus?.isInstalled == false
        {
            return "🚳 Station Closed"
        }
        else if self.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0 > 0
            
        {
            status += ", \(self.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0) 🚳"
        }
        else if self.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0 > 0
        {
            status += ", \(self.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0) ⛔️"
        }
        return status
    }
    
    var dateComponentText: String
    {
        let timeInterval = self.timestamp.timeIntervalSince(Date())
        let dateComponentString = Constants.dateComponentsFormatter.string(from: -timeInterval)
        guard let dcString = dateComponentString else { return "" }
        return "\(dcString) ago"
    }
    
    #if os(macOS)
    var pinTintColor: NSColor
    {
        guard let freeBikes = self.freeBikes,
              let emptySlots = self.emptySlots
        else
        {
            return .orange
        }
        let totalDocks = freeBikes + emptySlots
        if freeBikes == 0 || emptySlots == 0 || self.gbfsStationInformation?.stationStatus?.isRenting == false
        {
            return NSColor.app_red
        }
        else if Double(freeBikes) / Double(totalDocks) < 0.10
        {
            return NSColor.app_orange
        }
        else if Double(emptySlots) / Double(totalDocks) < 0.10
        {
            return NSColor.app_orange
        }
        return NSColor.app_green
    }
    #else
    var pinTintColor: UIColor
    {
        guard let freeBikes = self.freeBikes,
              let emptySlots = self.emptySlots
        else { return .app_orange }
        let totalDocks = freeBikes + emptySlots
        if freeBikes == 0 || emptySlots == 0 || self.gbfsStationInformation?.stationStatus?.isRenting == false
        {
            return UIColor.app_red
        }
        else if Double(freeBikes) / Double(totalDocks) < 0.10
        {
            return UIColor.app_orange
        }
        else if Double(emptySlots) / Double(totalDocks) < 0.10
        {
            return UIColor.app_orange
        }
        return UIColor.app_green
    }
    #endif
}

extension BikeStation
{
    init?(json: JSONDictionary)
    {
        guard let name = json["name"] as? String,
            let timeString = json["timestamp"] as? String,
            let timestamp = Constants.dateFormatter.date(from: timeString),
            let longitude = json["longitude"] as? Double,
            let latitude = json["latitude"] as? Double,
            let id = json["id"] as? String
            else
        {
            return nil
        }
        let freeBikes = json["free_bikes"] as? Int
        let emptySlots = json["empty_slots"] as? Int
        
        self.name = name
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.freeBikes = freeBikes
        self.emptySlots = emptySlots
        self.id = id
        if let extras = json["extra"] as? JSONDictionary
        {
            if let address = extras["address"] as? String
            {
                self.address = address
            }
            else
            {
                self.address = nil
            }
            if let lastUpdated = extras["last_updated"] as? Double
            {
                self.timestamp = Date(timeIntervalSince1970: lastUpdated)
            }
            else
            {
                self.timestamp = timestamp
            }
        }
        else
        {
            self.address = nil
            self.timestamp = timestamp
        }
    }
    
    var jsonDict: JSONDictionary
    {
        return ["name": self.name,
                "timestamp": Constants.dateFormatter.string(from: self.timestamp),
                "longitude": self.coordinates.longitude,
                "free_bikes": self.freeBikes as Any,
                "latitude": self.coordinates.latitude,
                "empty_slots": self.emptySlots as Any,
                "id": self.id,
                "address": self.address ?? ""
               ]
    }
}

extension BikeStation: Equatable
{
    static func == (lhs: BikeStation, rhs: BikeStation) -> Bool
    {
        return lhs.id == rhs.id && lhs.statusDisplayText == rhs.statusDisplayText && lhs.timestamp == rhs.timestamp && lhs.searchString == rhs.searchString
    }
}

extension BikeStation: Hashable
{
    var hashValue: Int
    {
        return self.id.hashValue
    }
}
