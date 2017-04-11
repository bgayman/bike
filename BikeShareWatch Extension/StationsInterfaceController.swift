//
//  StationsInterfaceController.swift
//  BikeShare
//
//  Created by Brad G. on 1/28/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit
import Foundation

class StationsInterfaceController: WKInterfaceController
{
    var network: BikeNetwork?
    var stations = [BikeStation]()
    {
        didSet
        {
            self.table.setNumberOfRows(self.stations.count, withRowType: self.rowType)
            self.stations.enumerated().forEach
            {
                guard let controller = self.table.rowController(at: $0.0) as? StationRowObject else { return }
                controller.bikeStation = $0.1
            }
        }
    }
    @IBOutlet var table: WKInterfaceTable!
    let rowType = "StationRow"
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        ExtensionConstants.userManager.getUserLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchStations), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        self.fetchStations()
    }
    
    override func didAppear()
    {
        super.didAppear()
        self.table.removeRows(at: IndexSet(Set(0..<self.stations.count)))
        ExtensionConstants.userManager.getUserLocation()
        self.fetchStations()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any?
    {
        let station = self.stations[rowIndex]
        return station
    }
    
    override func didDeactivate()
    {
        NotificationCenter.default.removeObserver(self)
        super.didDeactivate()
    }
    
    @objc private func fetchStations()
    {
        var closebyStationsClient = ClosebyStationsClient()
        guard let location = ExtensionConstants.userManager.currentLocation else { return }
        closebyStationsClient.fetchStations(lat: location.latitude, long: location.longitude, networkID: UserDefaults.standard.homeNetwork?.id)
        { [weak self] (response) in
            DispatchQueue.main.async
            {
                guard case .success(let result) = response
                    else
                {
                    return
                }
                let network = result.0
                let stations = result.1
                self?.network = network
                self?.stations = stations
                closebyStationsClient.invalidate()
            }
        }
    }
}

extension BikeStation
{
    var userManager: UserManager
    {
        return ExtensionConstants.userManager
    }
    
    var distance: CLLocationDistance
    {
        guard let currentCoor = self.userManager.currentLocation else { return -1 }
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let currentLocation = CLLocation(latitude: currentCoor.latitude, longitude: currentCoor.longitude)
        return stationLocation.distance(from: currentLocation)
    }
    
    var distanceDescription: String
    {
        guard self.distance > 0 else { return "" }
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
