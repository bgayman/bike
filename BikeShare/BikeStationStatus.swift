//
//  BikeStationStatus.swift
//  BikeShare
//
//  Created by B Gay on 4/19/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation


struct BikeStationStatus
{
    let numberOfBikesAvailable: Int
    let stationID: String
    let id: Int
    let networkID: String
    let timestamp: Date
    let numberOfDocksDisabled: Int?
    let numberOfDocksAvailable: Int?
    let numberOfBikesDisabled: Int?
    let isRenting: Bool?
    let isReturning: Bool?
    let isInstalled: Bool?
}

extension BikeStationStatus
{
    init?(json: [String: Any])
    {
        guard let numberOfBikesAvailable = json["numberOfBikesAvailable"] as? Int,
              let stationID = json["stationID"] as? String,
              let id = json["statusID"] as? Int,
              let networkID = json["networkID"] as? String,
              let timestampDouble = json["timestamp"] as? Double else { return nil }
        self.numberOfBikesAvailable = numberOfBikesAvailable
        self.stationID = stationID
        self.id = id
        self.networkID = networkID
        self.timestamp = Date(timeIntervalSinceReferenceDate: timestampDouble)
        self.numberOfDocksDisabled = json["numberOfDocksDisabled"] as? Int
        self.numberOfBikesDisabled = json["numberOfBikesDisabled"] as? Int
        self.numberOfDocksAvailable = json["numberOfDocksAvailable"] as? Int
        self.isRenting = json["isRenting"] as? Bool
        self.isReturning = json["isReturning"] as? Bool
        self.isInstalled = json["isInstalled"] as? Bool
    }
}
