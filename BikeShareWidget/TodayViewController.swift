//
//  TodayViewController.swift
//  BikeShareWidget
//
//  Created by B Gay on 12/30/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreLocation

class TodayViewController: UIViewController, NCWidgetProviding
{
    var stationsWidgetClient = StationsClient()
    var networksClient = NetworksClient()
    var network = UserDefaults.bikeShareGroup.homeNetwork
    let userManager = ExtensionConstants.userManager
    fileprivate let height: CGFloat = 105.0
    var stations: [BikeStation]?
    {
        didSet
        {
            self.closebyStations = nil
            self.tableView.reloadData()
            if oldValue ?? [] != self.stations ?? []
            {
                completion?(.newData)
            }
            else
            {
                completion?(.noData)
            }
        }
    }
    
    var completion: ((NCUpdateResult) -> Void)?
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    lazy var annotations: [MapBikeStation] =
    {
        return self.closebyStations.map(MapBikeStation.init)
    }()
    
    lazy var tableView: UITableView =
    {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        tableView.backgroundColor = UIColor.clear
        tableView.allowsSelection = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StationDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 65.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    lazy var closebyStations: [BikeStation]! =
    {
        guard ExtensionConstants.userManager.currentLocation != nil else
        {
            return Array(self.stations?.prefix(5) ?? [])
        }
        let sortedStations = self.stations?.sorted{ $0.0.distance < $0.1.distance } ?? []
        let closebyStations = Array(sortedStations.prefix(5))
        return closebyStations
    }()
    
    var mapHeight: CGFloat
    {
        return self.view.bounds.height * 0.4
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateCurrentLocation), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        self.userManager.getUserLocation()
        self.view.backgroundColor = .clear
        self.tableView.rowHeight = self.height
        self.fetchStations()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.mapHeight)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        self.stationsWidgetClient.invalidate()
        self.networksClient.invalidate()
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
    {
        fetchStations(completion: completionHandler)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize)
    {
        if activeDisplayMode == .compact
        {
            self.preferredContentSize = CGSize(width: 0, height: height)
        }
        else
        {
            self.preferredContentSize = CGSize(width: 0, height: height * CGFloat(self.closebyStations.count))
        }
        self.tableView.reloadData()
    }
    
    //MARK: - Networking
    @objc private func fetchStations(completion: ((NCUpdateResult) -> ())? = nil)
    {
        self.completion = completion
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
            self.emptyStateLabel.text = "Star a network or enable location sharing to use Today Extension"
            self.tableView.tableFooterView = UIView()
            return
        }
        
        self.stationsWidgetClient.fetchStations(with: network)
        { [weak self] response in
            DispatchQueue.main.async
            {
                switch response
                {
                case .error(let errorMessage):
                    self?.emptyStateLabel.text = errorMessage
                case .success(let stations):
                    guard !stations.isEmpty,
                        self?.stations ?? [] != stations
                        else
                    {
                        completion?(.noData)
                        return
                    }
                    
                    self?.stations = stations
                    if stations.count > 1
                    {
                        self?.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
                    }
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
    
    //MARK: - Location Update
    func didUpdateCurrentLocation()
    {
        self.closebyStations = nil
        self.tableView.reloadData()
    }

}

//MARK: - UITableViewDelegate
extension TodayViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.closebyStations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDetailTableViewCell
        
        cell.bikeStation = self.closebyStations[indexPath.row]
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.separatorInset = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let station = self.closebyStations[indexPath.row]
        guard let url = URL(string: "bikeshare://network/\(self.network!.id)/station/\(station.id)") else { return }
        self.extensionContext?.open(url, completionHandler: nil)
    }
}

//MARK: - BikeStation Extension
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

extension BikeNetworkLocation
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

