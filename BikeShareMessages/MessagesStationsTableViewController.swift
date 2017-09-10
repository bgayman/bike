//
//  MessagesStationsTableViewController.swift
//  BikeShare
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class MessagesStationsTableViewController: UITableViewController
{
    //MARK: - Properties
    let network: BikeNetwork
    var stationsClient = StationsClient()
    var stations = [BikeStation]()
    {
        didSet
        {
            self.animateUpdate(with: oldValue, newDataSource: self.stations)
        }
    }
    
    @objc lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        return refresh
    }()
    
    @objc let userManager = ExtensionConstants.userManager
    @objc var didFetchStationsCallback: (() -> ())?
    
    //MARK: - Lifecycle
    init(with bikeNetwork: BikeNetwork)
    {
        self.network = bikeNetwork
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.app_beige
        let nib = UINib(nibName: "\(BikeStationTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")
        self.title = self.network.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.configureTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateCurrentLocation), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        self.fetchStations()
    }

    override func viewDidDisappear(_ animated: Bool)
    {
        self.stationsClient.invalidate()
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    @objc func configureTableView()
    {
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.refreshControl = refresh
        self.refresh.beginRefreshing()
    }
    
    @objc func didUpdateCurrentLocation()
    {
        guard !self.stations.isEmpty else { return }
        self.updateStationsData(stations: self.stations)
    }
    
    func handleDeeplink(_ deeplink: Deeplink)
    {
        switch deeplink
        {
        case .network(let id):
            if self.network.id != id
            {
                let _ = self.navigationController?.popToRootViewController(animated: false)
                guard let networkVC = self.navigationController?.topViewController as? MessagesNetworkTableViewController else { return }
                networkVC.handleDeeplink(deeplink)
            }
        case .station(let networkID, let stationID):
            if self.network.id != networkID
            {
                let _ = self.navigationController?.popToRootViewController(animated: false)
                guard let networkVC = self.navigationController?.topViewController as? MessagesNetworkTableViewController else { return }
                networkVC.handleDeeplink(deeplink)
            }
            guard !self.stations.isEmpty else
            {
                self.didFetchStationsCallback =
                { [weak self] in
                    self?.handleDeeplink(deeplink)
                }
                return
            }
            guard let station = self.stations.filter({ $0.id == stationID }).first
                else { return }
            self.didSelect(station: station)
        case .systemInfo:
            break
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.stations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeStationTableViewCell
        cell.bikeStation = self.stations[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let station = self.stations[indexPath.row]
        self.didSelect(station: station)
    }
    
    //MARK: - Networking
    @objc private func fetchStations()
    {
        self.stationsClient.fetchStations(with: self.network, fetchGBFSProperties: true)
        { [weak self] response in
            DispatchQueue.main.async
            {
                self?.navigationItem.prompt = ""
                self?.navigationItem.titleView = nil
                switch response
                {
                case .error(let errorMessage):
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self?.present(alert, animated: true)
                    self?.didFetchStationsCallback = nil
                case .success(let stations):
                    guard !stations.isEmpty else
                    {
                        let alert = UIAlertController(errorMessage: "Uh oh, looks like there are no stations for this network.\n\nThis might be for seasonal reasons or this network might no longer exist 😢.")
                        alert.modalPresentationStyle = .overFullScreen
                        self?.present(alert, animated: true)
                        self?.didFetchStationsCallback = nil
                        return
                    }
                    
                    self?.updateStationsData(stations: stations)
                }
            }
        }
    }
    
    func updateStationsData(stations: [ BikeStation])
    {
        guard self.userManager.currentLocation != nil else
        {
            self.stations = stations
            if !stations.isEmpty
            {
                self.didFetchStationsCallback?()
                self.didFetchStationsCallback = nil
            }
            return
        }
        DispatchQueue.global(qos: .userInteractive).async
        { 
            #if !os(tvOS)
                let bikes = stations.reduce(0){ $0 + ($1.freeBikes ?? 0) }
                let docks = stations.reduce(0){ $0 + ($1.emptySlots ?? 0) }
                let stationsString = Constants.numberFormatter.string(from: NSNumber(value: stations.count)) ?? ""
                let bikesString = Constants.numberFormatter.string(from: NSNumber(value: bikes)) ?? ""
                let docksString = Constants.numberFormatter.string(from: NSNumber(value: docks)) ?? ""
                
                let prompt = "\(stationsString) stations - \(bikesString) available bikes - \(docksString) empty slots"
            #endif
            let sortedStations = stations.sorted{ $0.distance < $1.distance }
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    self.navigationItem.prompt = prompt
                #endif
                self.refreshControl?.endRefreshing()
                self.stations = sortedStations
                if !sortedStations.isEmpty
                {
                    self.didFetchStationsCallback?()
                    self.didFetchStationsCallback = nil
                }
            }
        }
    }
    
    func didSelect(station: BikeStation)
    {
        #if os(tvOS)
            self.dismiss(animated: false)
        #endif
        
        var stations = self.stations
        let index = stations.index(of: station)!
        stations.remove(at: index)
        let stationDetailViewController = StationDetailViewController(with: self.network, station: station, stations: stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        self.navigationController?.pushViewController(stationDetailViewController, animated: true)
    }

}
