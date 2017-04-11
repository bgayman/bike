//
//  MessagesNetworkTableViewController.swift
//  BikeShare
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import SafariServices
import CoreLocation

class MessagesNetworkTableViewController: UITableViewController {

    //MARK: - Properties
    var networks = [BikeNetwork]()
    {
        didSet
        {
            self.animateUpdate(with: oldValue, newDataSource: self.networks)
        }
    }
    
    lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchNetworks), for: .valueChanged)
        return refresh
    }()
    
    var networksClient = NetworksClient()
    let userManager = ExtensionConstants.userManager
    var didFetchNetworkCallback: (() -> ())?

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "Networks"
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.navigationItem.titleView = activityIndicator
        activityIndicator.startAnimating()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.configureTableView()
        self.fetchNetworks()
        self.showHomeNetwork()

    }
    
    private func configureTableView()
    {
        self.tableView.estimatedRowHeight = 55.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        let height: CGFloat = max(BikeTableFooterView(reuseIdentifier: "thing").poweredByButton.intrinsicContentSize.height, 44.0)
        let footerView = BikeTableFooterView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height))
        footerView.poweredByButton.addTarget(self, action: #selector(self.poweredByPressed), for: .touchUpInside)
        self.tableView.tableFooterView = footerView
        
        self.refreshControl = refresh

    }
    
    private func showHomeNetwork()
    {
        guard let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork else { return }
        self.didSelect(network: homeNetwork)
    }
    
    func poweredByPressed()
    {
        let safariVC = SFSafariViewController(url: URL(string: "https://citybik.es/#about")!)
        self.present(safariVC, animated: true)
    }
    
    @objc func fetchNetworks()
    {
        self.networksClient.fetchNetworks
        { [weak self] response in
            DispatchQueue.main.async
            {
                self?.refreshControl?.endRefreshing()
                self?.navigationItem.titleView = nil
                switch response
                {
                case .error(let errorMessage):
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self?.present(alert, animated: true)
                    self?.didFetchNetworkCallback = nil
                case .success(let networks):
                    self?.updateNetworksData(networks: networks)
                }
            }
        }
    }
    
    func updateNetworksData(networks: [BikeNetwork])
    {
        guard self.userManager.currentLocation != nil else
        {
            self.networks = networks
            if !networks.isEmpty
            {
                self.didFetchNetworkCallback?()
                self.didFetchNetworkCallback = nil
            }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async
        {
            let sortedNetworks = networks.sorted { $0.0.location.distance < $0.1.location.distance }
            DispatchQueue.main.async
            {
                self.networks = sortedNetworks
                if !sortedNetworks.isEmpty
                {
                    self.didFetchNetworkCallback?()
                    self.didFetchNetworkCallback = nil
                }
            }
        }
    }
    
    func handleDeeplink(_ deeplink: Deeplink)
    {
        switch deeplink
        {
        case .network(let networkID):
            guard !self.networks.isEmpty else
            {
                self.didFetchNetworkCallback =
                { [weak self] in
                    self?.handleDeeplink(deeplink)
                }
                return
            }
            guard let network = self.networks.filter({ $0.id == networkID }).first
                else { return }
            self.didSelect(network: network)
        case .station(let networkID, _):
            guard !self.networks.isEmpty else
            {
                self.didFetchNetworkCallback =
                { [weak self] in
                    self?.handleDeeplink(deeplink)
                }
                return
            }
            guard let network = self.networks.filter({ $0.id == networkID }).first
                else { return }
            self.didSelect(network: network)
            guard let stationVC = self.navigationController?.topViewController as? MessagesStationsTableViewController else { return }
            stationVC.handleDeeplink(deeplink)
        case .systemInfo:
            break
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.networks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeTableViewCell
        let network = self.networks[indexPath.row]
        cell.bikeNetwork = network
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let network = self.networks[indexPath.row]
        self.didSelect(network: network)
    }
    
    func didSelect(network: BikeNetwork)
    {
        let stationsTableViewController = MessagesStationsTableViewController(with: network)
        guard let navVC = self.navigationController else { return }
        navVC.pushViewController(stationsTableViewController, animated: true)
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
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
