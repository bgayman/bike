import UIKit
import CoreLocation
#if !os(tvOS)
import Hero
#endif

//MARK: - StationsTableViewController
class StationsTableViewController: UITableViewController
{
    //MARK: - Properties
    let network: BikeNetwork
    var bikeStationDiffs = [BikeStationDiff]()
    var mapViewController: MapViewController? = nil
    var isHomeNetworkTransition = false
    var stations = [BikeStation]()
    {
        didSet
        {
            #if !os(tvOS)
            self.mapBarButton.isEnabled = !self.stations.isEmpty
            #endif
            self.animateUpdate(with: oldValue, newDataSource: self.stations)
        }
    }
    
    var didFetchStationsCallback: (() -> ())?
    
    lazy var searchController: UISearchController =
    {
        
        let searchResultsController = StationsSearchController()
        searchResultsController.delegate = self
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    lazy var searchBarButton: UIBarButtonItem =
    {
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.presentSearch))
        return searchBarButton
    }()
    
    #if !os(tvOS)
    lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        return refresh
    }()
    
    
    lazy var mapBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "World Map"), style: .plain, target: self, action: #selector(self.showMapViewController))
        return barButtonItem
    }()
    
    lazy var diffBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Point Objects"), style: .plain, target: self, action: #selector(self.showStationsDiffViewController))
        return barButtonItem
    }()
    #endif
    
    lazy var networkBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(title: "Networks", style: .plain, target: self, action: #selector(self.showNetworksViewController))
        return barButtonItem
    }()
    
    //MARK: - Computed Properties
    var userManager: UserManager
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    #if !os(tvOS)
    override var previewActionItems: [UIPreviewActionItem]
    {
        let shareActionItem = UIPreviewAction(title: "Share", style: .default)
        { _, viewController in
            guard let viewController = viewController as? StationsTableViewController,
                  let url = URL(string: "\(Constants.WebSiteDomain)/stations/\(viewController.network.id)")
            else { return }
            
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
        }
        let favorite = UIPreviewAction(title: "☆", style: .default)
        { _, viewController in
            guard let viewController = viewController as? StationsTableViewController
                else { return }
            UserDefaults.bikeShareGroup.setHomeNetwork(viewController.network)
            #if os(iOS) || os(watchOS)
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: viewController.network.jsonDict as AnyObject])
            #endif
        }
        let unfavorite = UIPreviewAction(title: "★", style: .default)
        { _, viewController in
            guard let _ = viewController as? StationsTableViewController
                else { return }
            UserDefaults.bikeShareGroup.setHomeNetwork(nil)
            #if os(iOS) || os(watchOS)
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: NSNull() as AnyObject])
            #endif
        }
        return UserDefaults.bikeShareGroup.homeNetwork == self.network ? [shareActionItem, unfavorite] : [shareActionItem, favorite]
    }
    #endif
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]?
    {
        let search = UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(self.search), discoverabilityTitle: "Search")
        let back = UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(self.back), discoverabilityTitle: "Back")
        return [search, back]
    }
    
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
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        
        #if !os(tvOS)
            if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork, homeNetwork.id == self.network.id
            {
                self.navigationItem.hidesBackButton = true
                self.navigationItem.leftBarButtonItem = self.networkBarButton
            }
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            self.navigationItem.titleView = activityIndicator
            activityIndicator.startAnimating()
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.view.backgroundColor = .app_beige
            self.mapBarButton.isEnabled = false
        #else
            self.title = "  Stations"
            self.navigationItem.leftBarButtonItem = self.searchBarButton
        #endif
        
        self.configureTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateCurrentLocation), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
        self.fetchStations()
        if self.splitViewController?.traitCollection.isSmallerDevice == true && self.isHomeNetworkTransition
        {
            self.isHomeNetworkTransition = false
            self.showMapViewController(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        #if !os(tvOS)
        if self.splitViewController?.traitCollection.isSmallerDevice ?? false
        {
            self.navigationItem.setRightBarButtonItems([self.mapBarButton, self.diffBarButton], animated: true)
        }
        else
        {
            self.navigationItem.setRightBarButtonItems([self.diffBarButton], animated: true)
        }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        #if !os(tvOS)
        self.navigationController?.isHeroEnabled = false
        #endif
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.stations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeTableViewCell
        cell.bikeStation = self.stations[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        guard let nextIndexPath = context.nextFocusedIndexPath else { return }
        let station = self.stations[nextIndexPath.row]
        self.mapViewController?.bouncePin(for: station)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let station = self.stations[indexPath.row]
        self.didSelect(station: station)
    }
    
    #if !os(tvOS)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let share = UITableViewRowAction(style: .default, title: "Share")
        { [unowned self] (_, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            let rect = tableView.rectForRow(at: indexPath)
            let network = self.network
            let station = self.stations[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)/station/\(station.id)") else { return }
            let activityViewController = UIActivityViewController(activityItems: [url, station.coordinates], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController
            {
                presenter.sourceRect = rect
                presenter.sourceView = cell
            }
            self.present(activityViewController, animated: true)
        }
        share.backgroundColor = UIColor.app_green
        return [share]
    }
    #endif
    
    //MARK: - Networking
    @objc private func fetchStations()
    {
        #if !os(tvOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        let stationsClient = StationsClient()
        stationsClient.fetchStations(with: self.network, fetchGBFSProperties: true)
        { [weak self] response in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.navigationItem.prompt = nil
                self?.refreshControl?.endRefreshing()
                self?.navigationItem.titleView = nil
                self?.title = self?.network.name
                #endif
                stationsClient.invalidate()
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
    
    func updateStationsData(stations: [ BikeStation], fromUserLocationUpdate: Bool = false)
    {
        guard let stationsSearchController = self.searchController.searchResultsController as? StationsSearchController else { return }
        stationsSearchController.all = stations
        guard self.userManager.currentLocation != nil else
        {
            self.stations = stations
            self.mapViewController?.stations = stations
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
            let prompt: String?
            if bikes > 0
            {
                prompt = "\(stationsString) stations - \(bikesString) available bikes - \(docksString) empty slots"
            }
            else
            {
                prompt = nil
            }
            #endif
            let sortedStations = stations.sorted{ $0.distance < $1.distance }
            self.bikeStationDiffs += BikeStationDiff.performDiff(with: self.stations, newDataSource: sortedStations) ?? [BikeStationDiff]()
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                self.mapViewController?.navigationItem.prompt = prompt
                #endif
                self.stations = sortedStations
                if !fromUserLocationUpdate
                {
                    self.mapViewController?.stations = sortedStations
                }
                if !sortedStations.isEmpty
                {
                    self.didFetchStationsCallback?()
                    self.didFetchStationsCallback = nil
                }
            }
        }
    }
    
    //MARK: - Navigation
    func showMapViewController(animated: Bool = true)
    {
        guard let mapVC = self.mapViewController else
        {
            let mapVC = MapViewController()
            mapVC.delegate = self
            self.mapViewController = mapVC
            self.updateStationsData(stations: self.stations)
            self.splitViewController?.showDetailViewController(mapVC, sender: nil)
            return
        }
        self.navigationController?.pushViewController(mapVC, animated: animated)
    }
    
    func showNetworksViewController()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func showStationsDiffViewController()
    {
        #if !os(tvOS)
        let stationDiffViewController = StationDiffViewController(bikeNetwork: self.network, bikeStations: self.stations, bikeStationDiffs: self.bikeStationDiffs)
        stationDiffViewController.delegate = self
        self.navigationController?.pushViewController(stationDiffViewController, animated: true)
        #endif
    }
    
    func handleDeeplink(_ deeplink: Deeplink)
    {
        switch deeplink
        {
        case .network(let id):
            if self.network.id != id
            {
                let _ = self.navigationController?.popToRootViewController(animated: false)
                guard let networkVC = self.navigationController?.topViewController as? NetworkTableViewController else { return }
                networkVC.handleDeeplink(deeplink)
            }
        case .station(let networkID, let stationID):
            if self.network.id != networkID
            {
                let _ = self.navigationController?.popToRootViewController(animated: false)
                guard let networkVC = self.navigationController?.topViewController as? NetworkTableViewController else { return }
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
            self.showMapViewController()
            self.mapViewController?.handleDeeplink(deeplink: deeplink)
        }
    }
    
    func presentSearch()
    {
        let searchContainer = UISearchContainerViewController(searchController: self.searchController)
        searchController.searchBar.placeholder = "Search Stations"
        searchContainer.modalPresentationStyle = .overFullScreen
        let searchNavVC = UINavigationController(rootViewController: searchContainer)
        self.present(searchNavVC, animated: true)
    }
    
    //MARK: - UI Helper
    func configureTableView()
    {
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.definesPresentationContext = true
        #if !os(tvOS)
        self.refreshControl = refresh
        self.refresh.beginRefreshing()
        self.tableView.tableHeaderView = self.searchController.searchBar
        #endif
    }
    
    func search()
    {
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    func back()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
}

//MARK: - Current Location Update
extension StationsTableViewController
{
    func didUpdateCurrentLocation()
    {
        self.updateStationsData(stations: self.stations, fromUserLocationUpdate: true)
    }
}

//MARK: - StationsSearchControllerDelegate
extension StationsTableViewController: StationsSearchControllerDelegate
{
    func didSelect(station: BikeStation)
    {
        #if os(tvOS)
            self.dismiss(animated: false)
        #endif
        guard !self.searchController.isActive else
        {
            self.searchController.isActive = false
            DispatchQueue.main.delay(0.4)
            {
                self.didSelect(station: station)
            }
            return
        }
        
        self.searchController.isActive = false
        let stationDetailViewController = StationDetailViewController(with: self.network, station: station, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        if self.splitViewController?.traitCollection.isSmallerDevice ?? false
        {
            self.navigationController?.pushViewController(stationDetailViewController, animated: true)
        }
        else
        {
            self.mapViewController?.focus(on: [station])
            let navVC = UINavigationController(rootViewController: stationDetailViewController)
            #if !os(tvOS)
            navVC.modalPresentationStyle = .pageSheet
            #endif
            
            self.present(navVC, animated: true)
        }
    }
}

//MARK: - MapViewControllerDelegate
extension StationsTableViewController: MapViewControllerDelegate
{
    func didRequestCallout(forMapBikeStation: MapBikeStation)
    {
        guard let index = self.stations.index(of: forMapBikeStation.bikeStation) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }
    
    func didSelect(mapBikeStation: MapBikeStation)
    {
        #if !os(tvOS)
            let stationDetailViewController = StationDetailViewController(with: self.network, station: mapBikeStation.bikeStation, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
            if self.splitViewController?.traitCollection.isSmallerDevice ?? false
            {
                self.navigationController?.isHeroEnabled = true
                self.navigationController?.pushViewController(stationDetailViewController, animated: true)
            }
            else
            {
                self.mapViewController?.focus(on: [mapBikeStation.bikeStation])
                let navVC = UINavigationController(rootViewController: stationDetailViewController)
                #if !os(tvOS)
                    navVC.modalPresentationStyle = .pageSheet
                #endif
                
                self.present(navVC, animated: true)
            }
            
        #else
            self.didSelect(station: mapBikeStation.bikeStation)
        #endif
        
    }
}

//MARK: - UISearchResultsUpdating
extension StationsTableViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        guard let controller = searchController.searchResultsController as? StationsSearchController else { return }
        guard let text = searchController.searchBar.text else { return }
        controller.searchString = text
        self.mapViewController?.stations = controller.searchResults
    }
}

//MARK: - UISearchControllerDelegate/UISearchBarDelegate
extension StationsTableViewController: UISearchControllerDelegate, UISearchBarDelegate
{
    func didDismissSearchController(_ searchController: UISearchController)
    {
        guard let stationsSearchController = searchController.searchResultsController as? StationsSearchController else { return }
        self.mapViewController?.stations = stationsSearchController.all
    }
    
    #if !os(tvOS)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard let stationsSearchController = self.searchController.searchResultsController as? StationsSearchController else { return }
        self.mapViewController?.stations = stationsSearchController.all
    }
    #endif
}

//MARK: - UIViewControllerPreviewingDelegate
extension StationsTableViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        let station = self.stations[indexPath.row]
        let stationDetailViewController = StationDetailViewController(with: self.network, station: station, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        return stationDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

//MARK: - Station
#if !os(tvOS)
extension StationsTableViewController: StationDiffViewControllerDelegate
{
    func didUpdateBikeStations(stations: [BikeStation])
    {
        self.updateStationsData(stations: stations)
    }
    
    func didUpdateBikeStationDiffs(bikeStationDiffs: [BikeStationDiff])
    {
        self.bikeStationDiffs = bikeStationDiffs
    }
    
    func didSelectBikeStation(station: BikeStation)
    {
        self.didSelect(station: station)
    }
}
#endif

extension BikeStation
{
    var userManager: UserManager
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
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

