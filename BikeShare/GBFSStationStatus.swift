//
//  GBFSStationStatus.swift
//  BikeShare
//
//  Created by Brad G. on 2/25/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

struct GBFSStationStatus
{
    let stationID: String
    let numberOfBikesAvailable: Int
    let numberOfBikesDisabled: Int?
    let numberOfDocksAvailable: Int
    let numberOfDocksDisabled: Int?
    let isInstalled: Bool
    let isRenting: Bool
    let isReturning: Bool
    let lastReported: Date
}

extension GBFSStationStatus
{
    init?(json: JSONDictionary)
    {
        guard let stationID = json["station_id"] as? String,
              let numberOfBikesAvailable = json["num_bikes_available"] as? Int,
              let numberOfDocksAvailable = json["num_docks_available"] as? Int,
              let isInstalled = json["is_installed"] as? Bool,
              let isRenting = json["is_renting"] as? Bool,
              let isReturning = json["is_returning"] as? Bool,
              let lastReportedInt = json["last_reported"] as? Int
        else { return nil }
        self.stationID = stationID
        self.numberOfBikesAvailable = numberOfBikesAvailable
        self.numberOfDocksAvailable = numberOfDocksAvailable
        self.numberOfBikesDisabled = json["num_bikes_disabled"] as? Int
        self.numberOfDocksDisabled = json["num_docks_disabled"] as? Int
        self.isInstalled = isInstalled
        self.isRenting = isRenting
        self.isReturning = isReturning
        self.lastReported = Date(timeIntervalSinceReferenceDate: Double(lastReportedInt))
    }
}

