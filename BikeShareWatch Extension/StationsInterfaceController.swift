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
            self.table.removeRows(at: IndexSet(Set(0..<self.stations.count)))
            self.table.setNumberOfRows(self.stations.count, withRowType: self.rowType)
            self.stations.enumerated().forEach
            {
                guard let controller = self.table.rowController(at: $0.0) as? StationRowObject else { return }
                controller.bikeStation = $0.1
            }
        }
    }
    @IBOutlet var table: WKInterfaceTable!
    @objc let rowType = "StationRow"
    @objc var isUpdating = false
    @objc var didJustPressUpdate = false
    @objc var lastLocationUpdate: CLLocation?
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didGetLocation(notification:)), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        self.network = UserDefaults.standard.homeNetwork
        self.stations = UserDefaults.standard.closebyStations
        self.update()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any?
    {
        let station = self.stations[rowIndex]
        return station
    }
    
    override func didAppear()
    {
        super.didAppear()
        guard !self.didJustPressUpdate else
        {
            self.didJustPressUpdate = false
            return
        }
        let stations = self.stations
        self.stations = stations
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func update()
    {
        self.lastLocationUpdate = nil
        ExtensionConstants.userManager.getUserLocation()
    }
    
    @IBAction private func didPressUpdate()
    {
        self.didJustPressUpdate = true
        self.table.removeRows(at: IndexSet(Set(0..<self.stations.count)))
        self.table.setNumberOfRows(1, withRowType: self.rowType)
        guard let controller = self.table.rowController(at: 0) as? StationRowObject else { return }
        controller.isEmptyRow = true
        self.update()
    }
    
    @objc func didGetLocation(notification: Notification)
    {
        guard let location = notification.object as? CLLocation else { return }
        if let lastLocation = self.lastLocationUpdate
        {
            let distance = location.distance(from: lastLocation)
            if distance >= 100
            {
                self.lastLocationUpdate = location
                self.fetchStations()
            }
        }
        else
        {
            self.lastLocationUpdate = location
            self.fetchStations()
        }
    }
    
    @objc private func fetchStations()
    {
        guard !self.isUpdating else { return }
        guard let location = ExtensionConstants.userManager.currentLocation else { return }
        self.isUpdating = true
        var closebyStationsClient = ClosebyStationsClient()
        closebyStationsClient.fetchStations(lat: location.latitude, long: location.longitude, networkID: UserDefaults.standard.homeNetwork?.id)
        { [weak self] (response) in
            DispatchQueue.main.async
            {
                guard let strongSelf = self else { return }
                strongSelf.isUpdating = false
                switch response
                {
                case .success(let result):
                    let network = result.0
                    let stations = result.1
                    strongSelf.network = network
                    if stations.isEmpty
                    {
                        strongSelf.showError(errorMessage: "No closeby stations")
                    }
                    else
                    {
                        strongSelf.stations = stations
                    }
                    
                    UserDefaults.standard.setClosebyStations(with: stations.map { $0.jsonDict })
                case .error(let errorMessage):
                    strongSelf.showError(errorMessage: errorMessage)
                }
                
                closebyStationsClient.invalidate()
            }
        }
    }
    
    private func showError(errorMessage: String)
    {
        table.removeRows(at: IndexSet(Set(0 ..< stations.count)))
        table.setNumberOfRows(1, withRowType: rowType)
        guard let controller = table.rowController(at: 0) as? StationRowObject else { return }
        controller.errorMessage = errorMessage
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
