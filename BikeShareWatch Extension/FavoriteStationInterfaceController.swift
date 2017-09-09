//
//  FavoriteStationInterfaceController.swift
//  BikeShare
//
//  Created by B Gay on 5/18/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit

class FavoriteStationInterfaceController: WKInterfaceController
{
    var stations = [BikeStation]()
    {
        didSet
        {
            self.tableView.removeRows(at: IndexSet(Set(0..<self.stations.count)))
            self.tableView.setNumberOfRows(self.stations.count, withRowType: self.rowType)
            self.stations.enumerated().forEach
            {
                guard let controller = self.tableView.rowController(at: $0.0) as? StationRowObject else { return }
                controller.bikeStation = $0.1
            }
        }
    }
    
    @IBOutlet var tableView: WKInterfaceTable!
    
    @objc let rowType = "StationRow"
    @objc var isUpdating = false
    @objc var didJustPressUpdate = false
    @objc var lastLocationUpdate: CLLocation?
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didGetLocation(notification:)), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
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
        if !self.stations.isEmpty
        {
            let stations = self.stations
            self.stations = stations
        }
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func update()
    {
        self.fetchStations()
    }
    
    @IBAction private func didPressUpdate()
    {
        self.didJustPressUpdate = true
        self.tableView.removeRows(at: IndexSet(Set(0..<self.stations.count)))
        self.tableView.setNumberOfRows(1, withRowType: self.rowType)
        guard let controller = self.tableView.rowController(at: 0) as? StationRowObject else { return }
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
        guard let network = UserDefaults.standard.homeNetwork,
              !UserDefaults.standard.favoriteStations(for: network).isEmpty else
        {
            self.tableView.setNumberOfRows(1, withRowType: self.rowType)
            guard let controller = self.tableView.rowController(at: 0) as? StationRowObject else { return }
            controller.message = ("No favorite stations", "Add a home network and favorite stations on you phone to see their status here.")
            return
        }
        self.isUpdating = true
        var closebyStationsClient = ClosebyStationsClient()
        let stations = Array(UserDefaults.standard.favoriteStations(for: network).prefix(10))
        closebyStationsClient.fetchStations(networkID: network.id, stationIDs: stations.map { $0.id })
        { [weak self] (response) in
            DispatchQueue.main.async
            {
                guard let strongSelf = self else { return }
                strongSelf.isUpdating = false
                switch response
                {
                case .success(let result):
                    let stations = result.1
                    strongSelf.stations = stations
                    UserDefaults.standard.setClosebyStations(with: stations.map { $0.jsonDict })
                case .error(let errorMessage):
                    strongSelf.tableView.removeRows(at: IndexSet(Set(0 ..< strongSelf.stations.count)))
                    strongSelf.tableView.setNumberOfRows(1, withRowType: strongSelf.rowType)
                    guard let controller = strongSelf.tableView.rowController(at: 0) as? StationRowObject else { return }
                    controller.errorMessage = errorMessage
                }
                
                closebyStationsClient.invalidate()
            }
        }
    }
}
