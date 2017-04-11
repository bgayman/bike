//
//  TodayViewController.swift
//  BikeShareMacWidget
//
//  Created by Brad G. on 1/21/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa
import NotificationCenter
import CoreLocation

class TodayViewController: NSViewController, NCWidgetProviding
{
    var stationWidgetClient = WidgetStationClient()
    var networksClient = NetworksClient()
    var network = UserDefaults.bikeShareGroup.homeNetwork
    let userManager = ExtensionConstants.userManager
    fileprivate let height: CGFloat = 105.0
    var stations: [BikeStation]?
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var emptyStateLabel: NSTextField!
    
    lazy var closebyStations: [BikeStation]! =
    {
        var currentCoordinates = self.userManager.currentLocation
        let location = UserDefaults.bikeShareGroup.location
        currentCoordinates = (currentCoordinates == nil) ? location : currentCoordinates
        
        guard currentCoordinates != nil else
        {
            return Array(self.stations?.prefix(5) ?? [])
        }
        let sortedStations = self.stations?.sorted{ $0.0.distance < $0.1.distance } ?? []
        let closebyStations = Array(sortedStations.prefix(5))
        return closebyStations
    }()
    
    override var nibName: String?
    {
        return "TodayViewController"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateCurrentLocation), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        self.userManager.getUserLocation()
        self.tableView.backgroundColor = .clear
        self.tableView.rowHeight = self.height
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: self.height * 3)
        self.tableView.selectionHighlightStyle = .none
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
    {
        self.fetchStations(completion: completionHandler)
    }

    @objc private func fetchStations(completion: ((NCUpdateResult) -> ())? = nil)
    {
        guard let network = self.network
            else
        {
            switch CLLocationManager.authorizationStatus()
            {
            case .authorizedWhenInUse, .authorizedAlways:
                self.fetchNetworks()
                return
            case .denied, .restricted, .notDetermined:
                break
            }
            self.emptyStateLabel.stringValue = "Star a network or enable location sharing to use Today Extension"
            return
        }
        
        self.stationWidgetClient.fetchStations(with: network)
        { [weak self] response in
            DispatchQueue.main.async
            {
                switch response
                {
                case .error(let error):
                    self?.emptyStateLabel.stringValue = error
                    break
                case .success(let stations):
                    guard !stations.isEmpty,
                        self?.stations ?? [] != stations
                        else
                    {
                        completion?(.noData)
                        return
                    }
                    self?.stations = stations
                    self?.closebyStations = nil
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func fetchNetworks()
    {
        self.networksClient.fetchNetworks
        { [weak self] response in
            switch response
            {
            case .error:
                break
            case .success(let networks):
                let sortedNetworks = networks.sorted { $0.0.location.distance < $0.1.location.distance }
                self?.network = sortedNetworks.first
                DispatchQueue.main.async
                {
                    self?.fetchStations()
                }
            }
        }
    }
    
    func didUpdateCurrentLocation()
    {
        self.closebyStations = nil
        self.tableView.reloadData()
    }
}

extension TodayViewController: NSTableViewDelegate, NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return self.closebyStations.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        guard let cell = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as? NetworkTableCell else { return  nil }
        let attributes = cell.backgroundStyle == .dark ? [NSForegroundColorAttributeName: NSColor.white] : [NSForegroundColorAttributeName: NSColor.darkGray]
        let bikeStation = self.closebyStations[row]
        cell.titleTextField?.attributedStringValue = NSAttributedString(string: bikeStation.statusDisplayText, attributes: attributes)
        cell.subtitleTextField?.attributedStringValue = NSAttributedString(string: "\(bikeStation.name) — \(bikeStation.dateComponentText)" + (bikeStation.distance > 0 ? "— \(bikeStation.distanceDescription)" : ""), attributes: attributes)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return self.height
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        let station = self.closebyStations[self.tableView.selectedRow]
        guard let url = URL(string: "bikeshare://network/\(self.network?.id ?? "")/station/\(station.id)") else { return }
        NSWorkspace.shared().open(url)
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
        var currentCoordinates = self.userManager.currentLocation
        let location = UserDefaults.bikeShareGroup.location
        currentCoordinates = (currentCoordinates == nil) ? location : currentCoordinates
        
        guard let currentCoor = currentCoordinates else { return -1 }
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

extension BikeNetworkLocation
{
    var userManager: UserManager
    {
        return ExtensionConstants.userManager
    }
    
    var distance: CLLocationDistance
    {
        var currentCoordinates = self.userManager.currentLocation
        let location = UserDefaults.bikeShareGroup.location
        currentCoordinates = (currentCoordinates == nil) ? location : currentCoordinates
        
        guard let currentCoor = currentCoordinates
        else { return -1 }
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let currentLocation = CLLocation(latitude: currentCoor.latitude, longitude: currentCoor.longitude)
        let distance = stationLocation.distance(from: currentLocation)
        return distance
    }
    
    var distanceDescription: String
    {
        guard self.distance > 0  else { return "" }
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
