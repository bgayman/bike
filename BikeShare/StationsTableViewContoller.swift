import UIKit
import CoreLocation
#if !os(tvOS)
import DZNEmptyDataSet
#endif

// MARK: - StationsTableViewController
class StationsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    // MARK: - Properties
    let network: BikeNetwork
    var bikeStationDiffs = [BikeStationDiff]()
    @objc var mapViewController: MapViewController? = nil
    @objc var isHomeNetworkTransition = false
    fileprivate var filterState = FilterState.all
    {
        didSet
        {
            self.mapViewController?.filterState = self.filterState
            switch self.filterState
            {
            case .all:
                self.tableView.tableFooterView = nil
                self.dataSource = self.stations
                
            case .favorites:
                let favoriteStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.network)
                let favoriteStationIDs = favoriteStations.map { $0.id }
                self.dataSource = self.stations.filter { favoriteStationIDs.contains($0.id) }
            }
        }
    }
    var stations = [BikeStation]()
    {
        didSet
        {
            #if !os(tvOS)
            self.mapBarButton.isEnabled = !self.stations.isEmpty
            #endif
            switch self.filterState
            {
            case .all:
                self.dataSource = self.stations
            case .favorites:
                let favoriteStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.network)
                let favoriteStationIDs = favoriteStations.map { $0.id }
                self.dataSource = self.stations.filter { favoriteStationIDs.contains($0.id) }
            }
        }
    }
    
    var dataSource = [BikeStation]()
    {
        didSet
        {
            self.tableView.animateUpdate(with: oldValue, newDataSource: self.dataSource)
            guard let stationsSearchController = self.searchController.searchResultsController as? StationsSearchController else { return }
            stationsSearchController.all = self.dataSource
        }
    }
    
    @objc var didFetchStationsCallback: (() -> ())?
    
    // MARK: - Lazy Vars
    @objc lazy var searchController: UISearchController =
    {
        
        let searchResultsController = StationsSearchController()
        searchResultsController.delegate = self
        searchResultsController.network = self.network
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    @objc lazy var searchBarButton: UIBarButtonItem =
    {
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.presentSearch))
        return searchBarButton
    }()
    
    @objc lazy var segmentedControl: UISegmentedControl =
    {
        let segmentedControl = UISegmentedControl(items: ["All", "★"])
        segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
    #if !os(tvOS)
    @objc lazy var toolbar: UIToolbar =
    {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barTintColor = UIColor.app_beige
        self.view.addSubview(toolbar)
        toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil), UIBarButtonItem(customView: self.segmentedControl), UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)]
        return toolbar
    }()
    #endif
    
    @objc lazy var tableView: UITableView =
    {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        #if !os(tvOS)
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.toolbar.topAnchor).isActive = true
        tableView.dragDelegate = self
        #else
        tableView.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        #endif
        return tableView
    }()
    
    #if !os(tvOS)
    @objc lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        refresh.backgroundColor = .clear
        return refresh
    }()
    
    
    @objc lazy var mapBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "World Map"), style: .plain, target: self, action: #selector(self.didPressMapButton))
        return barButtonItem
    }()
    
    @objc lazy var diffBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Point Objects"), style: .plain, target: self, action: #selector(self.showStationsDiffViewController))
        return barButtonItem
    }()
    #endif
    
    @objc lazy var settingsBarButton: UIBarButtonItem =
    {
        let settingsBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(self.didPressSettings(_:)))
        return settingsBarButton
    }()
    
    @objc lazy var locationBarButton: UIBarButtonItem =
    {
        let locationControl = TVLocationButton(frame: CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0))
        locationControl.addTarget(self, action: #selector(self.didPressLocationButton), for: .primaryActionTriggered)
        let locationBarButton = UIBarButtonItem(customView: locationControl)
        return locationBarButton
    }()
    
    @objc lazy var networkBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(title: "Networks", style: .plain, target: self, action: #selector(self.showNetworksViewController))
        return barButtonItem
    }()
    
    // MARK: - Computed Properties
    @objc var userManager: UserManager
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
            
            let activity = ActivityViewCustomActivity.networkFavoriteActivity(with: viewController.network)
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: [activity])
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
        let refresh = UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(self.fetchStations), discoverabilityTitle: "Refresh")
        return [search, back, refresh]
    }
    
    // MARK: - Lifecycle
    init(with bikeNetwork: BikeNetwork)
    {
        self.network = bikeNetwork
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let nib = UINib(nibName: "\(BikeStationTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")

        #if !os(tvOS)
            self.navigationItem.searchController = self.searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.largeTitleDisplayMode = .never
            self.tableView.emptyDataSetDelegate = self
            self.tableView.emptyDataSetSource = self
            if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork, homeNetwork.id == self.network.id
            {
                self.navigationItem.hidesBackButton = true
                self.navigationItem.leftBarButtonItem = self.networkBarButton
            }
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            self.navigationItem.titleView = activityIndicator
            activityIndicator.startAnimating()
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.tableView.backgroundColor = .app_beige
            self.mapBarButton.isEnabled = false
            self.view.backgroundColor = UIColor.app_beige
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
        if self.splitViewController?.traitCollection.userInterfaceIdiom == .phone && self.isHomeNetworkTransition
        {
            self.isHomeNetworkTransition = false
            self.showMapViewController(animated: false)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews()
    {
        #if !os(tvOS)
        segmentedControl.frame.size.width = self.view.frame.width * 0.9
        if self.splitViewController?.traitCollection.isSmallerDevice ?? false
        {
            self.navigationItem.setRightBarButtonItems([self.mapBarButton, self.diffBarButton], animated: true)
        }
        else
        {
            self.navigationItem.setRightBarButtonItems([self.diffBarButton], animated: true)
        }
        #else
            self.navigationItem.setRightBarButtonItems([self.locationBarButton], animated: true)
        #endif
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        let isSmallerDevice = self.splitViewController?.traitCollection.isSmallerDevice == true
        coordinator.animate(alongsideTransition: { (_) in
            
        }) { (_) in
            if self.splitViewController?.traitCollection.isSmallerDevice == false && isSmallerDevice
            {
                guard var viewControllers = self.splitViewController?.viewControllers,
                      let mapVC = self.mapViewController else { return }
                viewControllers.remove(at: viewControllers.count - 1)
                viewControllers.append(UINavigationController(rootViewController:mapVC))
                self.segmentedControl.frame.size.width = size.width * 0.9
                self.splitViewController?.viewControllers = viewControllers
            }
        }
    }
    
    //MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeStationTableViewCell
        cell.bikeStation = self.dataSource[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        guard let nextIndexPath = context.nextFocusedIndexPath else { return }
        let station = self.dataSource[nextIndexPath.row]
        self.mapViewController?.bouncePin(for: station)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let station = self.dataSource[indexPath.row]
        self.didSelect(station: station)
    }
    
    #if !os(tvOS)
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let s = self.dataSource[indexPath.row]
        let share = UITableViewRowAction(style: .default, title: "Share")
        { [unowned self] (_, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            let rect = tableView.rectForRow(at: indexPath)
            let network = self.network
            let station = self.dataSource[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)/station/\(station.id)") else { return }
            let activity = ActivityViewCustomActivity.stationFavoriteActivity(station: station, network: network)
            let activityViewController = UIActivityViewController(activityItems: [url, station.coordinates], applicationActivities: [activity])
            if let presenter = activityViewController.popoverPresentationController
            {
                presenter.sourceRect = rect
                presenter.sourceView = cell
            }
            self.present(activityViewController, animated: true)
        }
        share.backgroundColor = UIColor.app_green
        let favorite = UITableViewRowAction(style: .default, title: " ☆ ")
        { [unowned self] _, indexPath in
            let station = self.dataSource[indexPath.row]
            UserDefaults.bikeShareGroup.addStationToFavorites(station: station, network: self.network)
            let jsonDicts = UserDefaults.bikeShareGroup.favoriteStations(for: self.network).map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.network.id: jsonDicts as AnyObject])
            tableView.setEditing(false, animated: true)
        }
        favorite.backgroundColor = UIColor.app_blue
        
        let unfavorite = UITableViewRowAction(style: .default, title: " ★ ")
        { [unowned self] _, indexPath in
            let station = self.dataSource[indexPath.row]
            UserDefaults.bikeShareGroup.removeStationFromFavorites(station: station, network: self.network)
            let jsonDicts = UserDefaults.bikeShareGroup.favoriteStations(for: self.network).map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.network.id: jsonDicts as AnyObject])
            tableView.setEditing(false, animated: true)
        }
        unfavorite.backgroundColor = UIColor.app_blue
        
        return UserDefaults.bikeShareGroup.isStationFavorited(station: s, network: self.network) ? [unfavorite, share] : [favorite, share]
    }
    #endif
    
    //MARK: - Networking
    @objc fileprivate func fetchStations()
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
                self?.refresh.endRefreshing()
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
        stationsSearchController.all = self.dataSource
        guard self.userManager.currentLocation != nil else
        {
            self.stations = stations
            self.mapViewController?.stations = self.dataSource
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
            
            DispatchQueue.main.async
            {
                let sortedStations = stations.sorted{ $0.distance < $1.distance }
                self.bikeStationDiffs += BikeStationDiff.performDiff(with: self.stations, newDataSource: sortedStations) ?? [BikeStationDiff]()
                #if !os(tvOS)
                self.mapViewController?.navigationItem.prompt = prompt
                #endif
                self.stations = sortedStations
                if !fromUserLocationUpdate
                {
                    
                    self.mapViewController?.stations = self.dataSource
                }
                else
                {
                    self.mapViewController?.shouldAnimateAnnotationUpdates = false
                    self.mapViewController?.stations = self.dataSource
                    self.mapViewController?.shouldAnimateAnnotationUpdates = true
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
    @objc func didPressMapButton()
    {
        self.showMapViewController(animated: true)
    }
    
    @objc func showMapViewController(animated: Bool = true)
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
        mapVC.delegate = self
        mapVC.filterState = filterState
        mapVC.stations = self.dataSource
        self.navigationController?.pushViewController(mapVC, animated: animated)
    }
    
    @objc func showNetworksViewController()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func showStationsDiffViewController()
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
    
    @objc func presentSearch()
    {
        let searchContainer = UISearchContainerViewController(searchController: self.searchController)
        searchController.searchBar.placeholder = "Search Stations"
        searchContainer.modalPresentationStyle = .overFullScreen
        let searchNavVC = UINavigationController(rootViewController: searchContainer)
        self.present(searchNavVC, animated: true)
    }
    
    @objc func didPressSettings(_ sender: UIBarButtonItem)
    {
        let settingsViewController = MapSettingsViewController()
        let navVC = UINavigationController(rootViewController: settingsViewController)
        #if !os(tvOS)
            navVC.modalPresentationStyle = .formSheet
        #endif
        navVC.modalTransitionStyle = .coverVertical
        self.present(navVC, animated: true)
    }
    
    @objc fileprivate func didPressLocationButton()
    {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways else
        {
            self.showLocationSettingsAlert()
            return
        }
        self.mapViewController?.didPressLocationButton()
    }
    
    private func showLocationSettingsAlert()
    {
        let alertController = UIAlertController (title: "Location Settings", message: "Allow Bear Bike Share to access you current location to use this feature.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default)
        { (_) in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl)
            {
                UIApplication.shared.open(settingsUrl)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    //MARK: - UI Helper
    @objc func configureTableView()
    {
        self.tableView.backgroundColor = .clear
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.automaticallyAdjustsScrollViewInsets = false
        self.definesPresentationContext = true
        #if !os(tvOS)
        self.tableView.addSubview(refresh)
        #endif
    }
    
    @objc func search()
    {
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    @objc func back()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func segmentedControlDidChange(_ sender: UISegmentedControl)
    {
        guard let filterState = FilterState(rawValue: sender.selectedSegmentIndex) else { return }
        switch filterState
        {
        case .all:
            self.tableView.tableFooterView = nil
            
        case .favorites:
            self.tableView.tableFooterView = UIView()
            
        }
        
        self.filterState = filterState
    }
}

//MARK: - Current Location Update
extension StationsTableViewController
{
    @objc func didUpdateCurrentLocation()
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
    @objc func didRequestCallout(forMapBikeStation: MapBikeStation)
    {
        guard let index = self.dataSource.index(of: forMapBikeStation.bikeStation) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }
    
    @objc func didSelect(mapBikeStation: MapBikeStation)
    {
        #if !os(tvOS)
            let stationDetailViewController = StationDetailViewController(with: self.network, station: mapBikeStation.bikeStation, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
            if self.splitViewController?.traitCollection.isSmallerDevice ?? false
            {
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
    
    func didSet(filterState: FilterState)
    {
        if let controller = searchController.searchResultsController as? StationsSearchController,
            controller.searchString.isEmpty == false
        {
            let searchString = controller.searchString
            self.segmentedControl.selectedSegmentIndex = filterState.rawValue
            self.filterState = filterState
            controller.searchString = searchString
            self.mapViewController?.stations = controller.searchResults
        }
        else
        {
            self.segmentedControl.selectedSegmentIndex = filterState.rawValue
            self.filterState = filterState
            self.mapViewController?.stations = self.dataSource
        }
    }
    
    @objc func didChange(searchText: String)
    {
        guard let controller = searchController.searchResultsController as? StationsSearchController else { return }
        controller.searchString = searchText
        self.mapViewController?.stations = controller.searchResults
    }
    
    @objc func didRequestUpdate()
    {
        self.fetchStations()
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

#if !os(tvOS)
extension StationsTableViewController: UITableViewDragDelegate
{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
    {
        let station = self.stations[indexPath.row]
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.network.id)/station/\(station.id)") else { return [] }
        let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
        let dragStringItem = UIDragItem(itemProvider: NSItemProvider(object: "\(station.name) \(station.statusDisplayText)" as NSString))
        return [dragURLItem, dragStringItem]
    }
}
#endif

//MARK: - UIViewControllerPreviewingDelegate
extension StationsTableViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        let station = self.dataSource[indexPath.row]
        let stationDetailViewController = StationDetailViewController(with: self.network, station: station, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        previewingContext.sourceRect = self.tableView.rectForRow(at: indexPath)
        return stationDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}


#if !os(tvOS)
    
extension StationsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let title = NSAttributedString(string: "★\nStations to Access Them More Quickly.", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title2), NSAttributedStringKey.foregroundColor: UIColor.gray])
        return title
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let description = NSAttributedString(string: "Swipe left on bike stations to see options.", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .subheadline), NSAttributedStringKey.foregroundColor: UIColor.lightGray])
        return description
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!
    {
        return #imageLiteral(resourceName: "seatedBear")
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool
    {
        return self.filterState == .favorites
    }
}
    // MARK: - StationDiffViewControllerDelegate
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
        return string
    }
}

