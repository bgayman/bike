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
    @objc let userManager = ExtensionConstants.userManager
    fileprivate let height: CGFloat = 105.0
    var stations: [BikeStation]?
    {
        didSet
        {
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
    
    @objc var completion: ((NCUpdateResult) -> Void)?
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    @objc lazy var annotations: [MapBikeStation] =
    {
        return self.closebyStations.map(MapBikeStation.init)
    }()
    
    @objc lazy var tableView: UITableView =
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
        let nib = UINib(nibName: "\(BikeStationTableViewCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 65.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    var closebyStations: [BikeStation]
    {
        if ExtensionConstants.userManager.currentLocation == nil,
           let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork
        {
            let favoriteStations = UserDefaults.bikeShareGroup.favoriteStations(for: homeNetwork)
            let favoriteIDs = favoriteStations.map { $0.id }
            return Array(self.stations?.filter { favoriteIDs.contains($0.id) }.prefix(5) ?? self.stations?.prefix(5) ?? [])
        }
        let sortedStations = self.stations?.sorted{ $0.distance < $1.distance } ?? []
        let closebyStations = Array(sortedStations.prefix(5))
        return closebyStations
    }
    
    @objc var mapHeight: CGFloat
    {
        return self.view.bounds.height * 0.4
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        WatchSessionManager.sharedManager.startSession()
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
                guard let strongSelf = self else { completion?(.noData); return }
                switch response
                {
                case .error(let errorMessage):
                    strongSelf.emptyStateLabel.text = errorMessage
                case .success(let stations):
                    guard !stations.isEmpty,
                        strongSelf.stations ?? [] != stations
                        else
                    {
                        completion?(.noData)
                        return
                    }
                    
                    strongSelf.stations = stations
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: ["network": network.jsonDict as AnyObject, "stations": strongSelf.closebyStations.map { $0.jsonDict } as AnyObject])
                    if stations.count > 1
                    {
                        strongSelf.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
                    }
                    completion?(.newData)
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
                let sortedNetworks = networks.sorted { $0.location.distance < $1.location.distance }
                self?.network = sortedNetworks.first
                DispatchQueue.main.async
                {
                    self?.fetchStations()
                }
            }
        }
    }
    
    //MARK: - Location Update
    @objc func didUpdateCurrentLocation()
    {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeStationTableViewCell
        
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

