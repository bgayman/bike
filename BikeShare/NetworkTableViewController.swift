import UIKit
import MapKit
#if !os(tvOS)
import SafariServices
#endif

//MARK: - NetworkTableViewController
class NetworkTableViewController: UITableViewController
{
    //MARK: - Types
    enum Segue: String
    {
        case showMapViewController = "showMapViewController"
    }
    
    //MARK: - Properties
    var networks = [BikeNetwork]()
    {
        didSet
        {
            self.mapBarButton.isEnabled = !self.networks.isEmpty
            self.animateUpdate(with: oldValue, newDataSource: self.networks)
        }
    }
    
    var networkMapViewController: MapViewController? = nil
    var isTransitioning = false
    
    lazy var searchController: UISearchController =
    {
        
        let searchResultsController = NetworkSearchController()
        searchResultsController.delegate = self
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.delegate = self
        return searchController
    }()
    
    #if !os(tvOS)
    lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchNetworks), for: .valueChanged)
        return refresh
    }()
    #endif
    
    lazy var mapBarButton: UIBarButtonItem =
    {
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "World Map"), style: .plain, target: self, action: #selector(self.showMapViewController))
        return barButtonItem
    }()
    
    lazy var searchBarButton: UIBarButtonItem =
    {
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.presentSearch))
        return searchBarButton
    }()
    
    var didFetchNetworkCallback: (() -> ())?
    
    var userManager: UserManager
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]?
    {
        let search = UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(self.search), discoverabilityTitle: "Search")
        return [search]
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let split = self.splitViewController
        {
            let controllers = split.viewControllers
            self.networkMapViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? MapViewController
            self.networkMapViewController?.delegate = self
        }
        self.title = "Networks"
        #if !os(tvOS)
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.navigationItem.titleView = activityIndicator
        activityIndicator.startAnimating()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        #else
        self.navigationItem.leftBarButtonItem = self.searchBarButton
        #endif
        
        
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
        self.configureTableView()
        self.mapBarButton.isEnabled = !self.networks.isEmpty
        self.fetchNetworks()
        self.showHomeNetwork()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        #if !os(tvOS)
        self.networkMapViewController?.navigationItem.prompt = nil
        #endif
        
        self.networkMapViewController?.delegate = self
        self.networkMapViewController?.networks = self.networks
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateCurrentLocation), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        if self.splitViewController?.traitCollection.isSmallerDevice ?? false
        {
            self.navigationItem.setRightBarButton(self.mapBarButton, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    //MARK: - UI Helpers
    private func configureTableView()
    {
        self.tableView.estimatedRowHeight = 55.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        let height: CGFloat = max(BikeTableFooterView(reuseIdentifier: "thing").poweredByButton.intrinsicContentSize.height, 44.0)
        let footerView = BikeTableFooterView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height))
        self.tableView.tableFooterView = footerView
        
    
        #if !os(tvOS)
        footerView.poweredByButton.addTarget(self, action: #selector(self.poweredByPressed), for: .touchUpInside)
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        self.refreshControl = refresh
        #endif
    }
    
    private func showHomeNetwork()
    {
        guard let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork,
              self.didFetchNetworkCallback == nil
        else { return }
        let stationsTableViewController = StationsTableViewController(with: homeNetwork)
        stationsTableViewController.mapViewController = self.networkMapViewController
        stationsTableViewController.mapViewController?.network = homeNetwork
        self.networkMapViewController?.delegate = stationsTableViewController
        self.navigationController?.pushViewController(stationsTableViewController, animated: false)
    }
    
    #if !os(tvOS)
    func poweredByPressed()
    {
        let safariVC = SFSafariViewController(url: URL(string: "https://citybik.es/#about")!)
        self.present(safariVC, animated: true)
    }
    #endif
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool
    {
        if context.nextFocusedView is UIButton
        {
            return false
        }
        return super.shouldUpdateFocus(in: context)
    }
    
    func search()
    {
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return networks.count
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
    
    #if !os(tvOS)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let favorite: UITableViewRowAction
        if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork,
               homeNetwork.id == self.networks[indexPath.row].id
        {
            favorite = UITableViewRowAction(style: .default, title: "★")
            { (_, _) in
                UserDefaults.bikeShareGroup.setHomeNetwork(nil)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: NSNull() as AnyObject])
                #endif
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        else
        {
            favorite = UITableViewRowAction(style: .default, title: "☆")
            { (_, indexPath) in
                let network = self.networks[indexPath.row]
                UserDefaults.bikeShareGroup.setHomeNetwork(network)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: network.jsonDict as AnyObject])
                #endif
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        favorite.backgroundColor = UIColor.app_blue
        
        let share = UITableViewRowAction(style: .default, title: "Share")
        { [unowned self] (_, indexPath) in
            let cell = tableView.cellForRow(at: indexPath)
            let rect = tableView.rectForRow(at: indexPath)
            let network = self.networks[indexPath.row]
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)") else { return }
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController
            {
                presenter.sourceRect = rect
                presenter.sourceView = cell
            }
            self.present(activityViewController, animated: true)
        }
        share.backgroundColor = UIColor.app_green
        return [favorite, share]
    }
    #endif
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    //MARK: - Networking
    @objc func fetchNetworks()
    {
        #if !os(tvOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        var networksClient = NetworksClient()
        networksClient.fetchNetworks
        { [weak self] response in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.refreshControl?.endRefreshing()
                #endif
                networksClient.invalidate()
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
        guard let searchVC = self.searchController.searchResultsController as? NetworkSearchController else { return }
        searchVC.all = networks
        guard self.userManager.currentLocation != nil else
        {
            self.networks = networks
            UserDefaults.bikeShareGroup.setNetworks(networks: networks)
            if self.navigationController?.topViewController === self
            {
                self.networkMapViewController?.networks = networks
                if !networks.isEmpty
                {
                    self.didFetchNetworkCallback?()
                    self.didFetchNetworkCallback = nil
                }
            }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async
        {
            let sortedNetworks = networks.sorted { $0.0.location.distance < $0.1.location.distance }
            DispatchQueue.main.async
            {
                self.networks = sortedNetworks
                UserDefaults.bikeShareGroup.setNetworks(networks: sortedNetworks)
                if self.navigationController?.topViewController === self
                {
                    self.networkMapViewController?.networks = sortedNetworks
                    if !sortedNetworks.isEmpty
                    {
                        self.didFetchNetworkCallback?()
                        self.didFetchNetworkCallback = nil
                    }
                }
            }
        }
    }
    
    func didUpdateCurrentLocation()
    {
        self.updateNetworksData(networks: self.networks)
    }
    
    //MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let ident = Segue(rawValue: segue.identifier ?? "") else { return }
        switch ident
        {
        case .showMapViewController:
            guard let navVC = segue.destination as? UINavigationController else { return }
            guard let mapViewController = navVC.topViewController as? MapViewController else { return }
            mapViewController.delegate = self
            mapViewController.networks = self.networks
        }
    }
    
    func showMapViewController()
    {
        self.performSegue(withIdentifier: Segue.showMapViewController.rawValue, sender: nil)
    }
    
    func presentSearch()
    {
        let searchContainer = UISearchContainerViewController(searchController: self.searchController)
        searchController.searchBar.placeholder = "Search Networks"
        searchContainer.modalPresentationStyle = .overFullScreen
        let searchNavVC = UINavigationController(rootViewController: searchContainer)
        self.present(searchNavVC, animated: true)
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
            guard let stationVC = self.navigationController?.topViewController as? StationsTableViewController else { return }
            stationVC.handleDeeplink(deeplink)
        case .systemInfo(let networkID):
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
            guard let stationVC = self.navigationController?.topViewController as? StationsTableViewController else { return }
            stationVC.handleDeeplink(deeplink)
        }
    }
}

//MARK: - NetworkSearchControllerDelegate
extension NetworkTableViewController: NetworkSearchControllerDelegate
{
    func didSelect(network: BikeNetwork)
    {
        #if os(tvOS)
            self.dismiss(animated: false)
        #endif
        
        guard !self.searchController.isActive else
        {
            self.searchController.isActive = false
            DispatchQueue.main.delay(0.4)
            {
                self.didSelect(network: network)
            }
            return
        }
        let stationsTableViewController = StationsTableViewController(with: network)
        stationsTableViewController.mapViewController = self.networkMapViewController
        stationsTableViewController.mapViewController?.network = network
        self.networkMapViewController?.delegate = stationsTableViewController
        guard let navVC = self.navigationController else { return }
        if navVC.topViewController is MapViewController || navVC.topViewController is UINavigationController
        {
            navVC.popToViewController(self, animated: true)
        }
        navVC.pushViewController(stationsTableViewController, animated: true)
    }
}

//MARK: - MapViewControllerDelegate
extension NetworkTableViewController: MapViewControllerDelegate
{
    func didRequestCallout(forMapBikeNetwork: MapBikeNetwork)
    {
        guard let index = self.networks.index(of: forMapBikeNetwork.bikeNetwork) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }
    
    func didSelect(mapBikeNetwork: MapBikeNetwork)
    {
        self.didSelect(network: mapBikeNetwork.bikeNetwork)
    }
}

//MARK: - UISearchResultsUpdating
extension NetworkTableViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        guard let controller = searchController.searchResultsController as? NetworkSearchController else { return }
        guard let text = searchController.searchBar.text else { return }
        controller.searchString = text
        guard !searchController.searchBar.text!.isEmpty else { return }
        self.networkMapViewController?.networks = controller.searchResults
    }
}

//MARK: - UISearchControllerDelegate/UISearchBarDelegate
extension NetworkTableViewController: UISearchControllerDelegate, UISearchBarDelegate
{
    func didDismissSearchController(_ searchController: UISearchController)
    {
        guard !self.isTransitioning else { return }
        self.networkMapViewController?.networks = self.networks
    }
    
    #if !os(tvOS)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard !self.isTransitioning else { return }
        self.networkMapViewController?.networks = self.networks
    }
    #endif
}

//MARK: - UIViewControllerPreviewingDelegate
extension NetworkTableViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        let network = self.networks[indexPath.row]
        let stationTableViewController = StationsTableViewController(with: network)
        return stationTableViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

extension BikeNetworkLocation
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
