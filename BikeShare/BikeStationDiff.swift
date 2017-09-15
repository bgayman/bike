//
//  BikeStationDiff.swift
//  BikeShare
//
//  Created by Brad G. on 3/18/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
import MapKit

final class RedMKCircle: MKCircle {}
final class GreenMKCircle: MKCircle {}

struct BikeStationDiff
{
    let bikesAdded: Int
    let emptySlotsAdded: Int
    let disabledBikesAdded: Int
    let disabledSlotsAdded: Int
    let closedChanged: Bool
    let bikeStation: BikeStation
    
    var statusText: String
    {
        var status = [String]()
        if self.bikesAdded > 0
        {
            status.append(self.bikesAdded > 1 ? "\(self.bikesAdded) bikes returned" : "\(self.bikesAdded) bike returned")
        }
        if self.bikesAdded < 0
        {
            status.append(self.bikesAdded < -1 ? "\(abs(self.bikesAdded)) bikes rented" : "\(abs(self.bikesAdded)) bike rented")
        }
        if self.emptySlotsAdded > 0
        {
            status.append(self.emptySlotsAdded > 1 ? "\(self.emptySlotsAdded) empty slots opened" : "\(self.emptySlotsAdded) empty slot opened")
        }
        if self.emptySlotsAdded < 0
        {
            status.append(self.emptySlotsAdded < -1 ? "\(abs(self.emptySlotsAdded)) empty slots closed" : "\(abs(self.emptySlotsAdded)) empty slot closed")
        }
        if self.disabledBikesAdded > 0
        {
            status.append(self.disabledBikesAdded > 1 ? "\(self.disabledBikesAdded) bikes disabled" : "\(self.disabledBikesAdded) bike disabled")
        }
        if self.disabledBikesAdded < 0
        {
            status.append(self.disabledBikesAdded < -1 ? "\(abs(self.disabledBikesAdded)) bikes enabled" : "\(abs(self.disabledBikesAdded)) bike enabled")
        }
        if self.disabledSlotsAdded > 0
        {
            status.append(self.disabledSlotsAdded > 1 ? "\(self.disabledSlotsAdded) slots disabled" : "\(self.disabledSlotsAdded) slot disabled")
        }
        if self.disabledSlotsAdded < 0
        {
            status.append(self.disabledSlotsAdded < -1 ? "\(abs(self.disabledSlotsAdded)) slots enabled" : "\(abs(self.disabledSlotsAdded)) slot enabled")
        }
        if self.closedChanged
        {
            status.append(self.bikeStation.statusDisplayText.contains("closed") ? "Station closed" : "Station opened")
        }
        if status.isEmpty
        {
            print("Empty: \(self)")
        }
        return status.joined(separator: ", ")
    }
    
    var overlay: MKCircle
    {
        if bikesAdded > 0
        {
            return RedMKCircle(center: bikeStation.coordinates, radius: abs(Double(bikesAdded)) * 100.0)
        }
        else
        {
            return GreenMKCircle(center: bikeStation.coordinates, radius: abs(Double(bikesAdded)) * 100.0)
        }
    }
    
    var dateComponentText: String?
    {
        guard let date = self.bikeStation.gbfsStationInformation?.stationStatus?.lastReported else { return nil }
        let timeInterval = date.timeIntervalSince(Date())
        let dateComponentString = Constants.dateComponentsFormatter.string(from: -timeInterval)
        guard let dcString = dateComponentString else { return nil }
        return "\(dcString) ago"
    }
}

extension BikeStationDiff
{
    init?(oldStation: BikeStation, newStation: BikeStation)
    {
        guard oldStation.id == newStation.id,
            oldStation != newStation else { return nil }
        let bikesAdded = (newStation.freeBikes ?? 0) - (oldStation.freeBikes ?? 0)
        let emptySlotsAdded = (newStation.emptySlots ?? 0) - (oldStation.emptySlots ?? 0)
        let disabledBikesAdded = (newStation.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0) - (oldStation.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0)
        let disabledSlotsAdded = (newStation.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0) - (oldStation.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0)
        let closedChanged = (newStation.gbfsStationInformation?.stationStatus?.isRenting ?? true, newStation.gbfsStationInformation?.stationStatus?.isReturning ?? true, newStation.gbfsStationInformation?.stationStatus?.isInstalled ?? true) != (oldStation.gbfsStationInformation?.stationStatus?.isRenting ?? true, oldStation.gbfsStationInformation?.stationStatus?.isReturning ?? true, oldStation.gbfsStationInformation?.stationStatus?.isInstalled ?? true)
        self.init(bikesAdded: bikesAdded, emptySlotsAdded: emptySlotsAdded, disabledBikesAdded: disabledBikesAdded, disabledSlotsAdded: disabledSlotsAdded, closedChanged: closedChanged, bikeStation: newStation)
    }
    
    static func performDiff(with oldDataSource: [BikeStation], newDataSource: [BikeStation]) -> [BikeStationDiff]?
    {
        let oldArray = oldDataSource
        let oldSet = Set(oldArray)
        let newArray = newDataSource
        let newSet = Set(newArray)
        
        let removed = oldSet.subtracting(newSet)
        let inserted = newSet.subtracting(oldSet)
        
        let idsRemoved = Set(removed.map { $0.id })
        let idsInserted = Set(inserted.map { $0.id })
        let intersection = idsRemoved.intersection(idsInserted)
        let oldDiffArray = removed.filter { intersection.contains($0.id) }
        let newDiffArray = inserted.filter { intersection.contains($0.id) }
        
        let bikeStationDiffs: [BikeStationDiff] = newDiffArray.flatMap
        { bikeStation in
            let oldStation = oldDiffArray.filter { $0.id == bikeStation.id }.first
            guard let oldValue = oldStation else { return nil }
            return BikeStationDiff(oldStation: oldValue, newStation: bikeStation)
        }
        return bikeStationDiffs
    }
}

extension BikeStationDiff: Equatable
{
    static func ==(lhs: BikeStationDiff, rhs: BikeStationDiff) -> Bool
    {
        return lhs.bikeStation.id == rhs.bikeStation.id && lhs.bikeStation.gbfsStationInformation?.stationStatus?.lastReported == rhs.bikeStation.gbfsStationInformation?.stationStatus?.lastReported && lhs.statusText == rhs.statusText
    }
}

extension BikeStationDiff: Hashable
{
    var hashValue: Int
    {
        return "\(self.bikeStation.id)\(self.bikeStation.timestamp)".hash
    }
}

extension BikeStationDiff: Comparable
{
    static func <(lhs: BikeStationDiff, rhs: BikeStationDiff) -> Bool
    {
        if lhs.bikeStation.timestamp == rhs.bikeStation.timestamp
        {
            return lhs.bikeStation.distance < rhs.bikeStation.distance
        }
        let date = Date()
        return lhs.bikeStation.timestamp.timeIntervalSince(date) > rhs.bikeStation.timestamp.timeIntervalSince(date)
    }
}
