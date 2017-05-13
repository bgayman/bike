//
//  MapViewController.swift
//  BikeShare
//
//  Created by B Gay on 12/23/16.
//  Copyright © 2016 B Gay. All rights reserved.
//
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import MapKit

//MARK: - MapViewControllerDelegate
protocol MapViewControllerDelegate: class
{
    func didRequestCallout(forMapBikeNetwork: MapBikeNetwork)
    func didRequestCallout(forMapBikeStation: MapBikeStation)
    func didSelect(mapBikeNetwork: MapBikeNetwork)
    func didSelect(mapBikeStation: MapBikeStation)
    func didSet(filterState: FilterState)
    func didChange(searchText: String)
}

//MARK: - MapViewControllerDelegate Defaults
extension MapViewControllerDelegate
{
    func didRequestCallout(forMapBikeNetwork mapBikeNetwork: MapBikeNetwork){}
    func didRequestCallout(forMapBikeStation mapBikeStation: MapBikeStation){}
    func didSelect(mapBikeNetwork: MapBikeNetwork){}
    func didSelect(mapBikeStation: MapBikeStation){}
    func didSet(filterState: FilterState){}
    func didChange(searchText: String){}
}

//MARK: - MapViewController
class MapViewController: BaseMapViewController
{
    //MARK: - State
    enum State
    {
        case networks
        case stations
    }
    
    //MARK: - Properties
    lazy var mapView: MKMapView =
    {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        #if os(macOS)
        self.view.addSubview(mapView, positioned: .below, relativeTo: self.activityIndicator)
        mapView.showsZoomControls = true
        mapView.showsCompass = true
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        #else
        self.view.subviews.forEach { if $0 is MKMapView { $0.removeFromSuperview() } }
        self.view.addSubview(mapView)
        mapView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.mapBottomLayoutConstraint = mapView.bottomAnchor.constraint(equalTo: self.toolbar.bottomAnchor)
        self.mapBottomLayoutConstraint?.isActive = true
            
        self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
        self.mapBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : -44.0
        self.view.bringSubview(toFront: self.toolbar)
        #endif
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        return mapView
    }()
    
    #if os(macOS)
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var mapKeyView: MapKeyView!
    #elseif !os(macOS)
    var filterState = FilterState.all

    lazy var mapKeyView: MapKeyView =
    {
        let mapKeyView = MapKeyView(frame: CGRect(x: 0, y: 0, width: 255
            , height: 70))
        mapKeyView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mapKeyView)
        
        #if os(tvOS)
            mapKeyView.widthAnchor.constraint(equalToConstant: 600).isActive = true
            mapKeyView.heightAnchor.constraint(equalToConstant: 150).isActive = true
            mapKeyView.topAnchor.constraint(equalTo: self.topLayoutGuide.topAnchor, constant: 20).isActive = true
        #else
            mapKeyView.widthAnchor.constraint(equalToConstant: 300).isActive = true
            mapKeyView.heightAnchor.constraint(equalToConstant: 70).isActive = true
            mapKeyView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor, constant: -20).isActive = true
        #endif
        
        
        if self.view.bounds.width < 500.0
        {
            mapKeyView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        }
        else
        {
            mapKeyView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0).isActive = true
        }
        
        return mapKeyView
    }()
    
    lazy var segmentedControl: UISegmentedControl =
    {
        let segmentedControl = UISegmentedControl(items: ["All", " ★ "])
        segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = self.filterState.rawValue
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.heightAnchor.constraint(equalToConstant: 40.0)
        return segmentedControl
    }()
    
    lazy var searchBar: UISearchBar =
    {
        let searchBar = UISearchBar(frame: CGRect(x: 0.0, y: 0.0, width: 210.0, height: 14.0))
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        return searchBar
    }()
    
    var toolbarBottomLayoutConstraint: NSLayoutConstraint?
    var mapBottomLayoutConstraint: NSLayoutConstraint?
    
    lazy var toolbarStackView: UIStackView =
    {
        let toolbarStackView = UIStackView()
        toolbarStackView.axis = .horizontal
        toolbarStackView.spacing = 8.0
        return toolbarStackView
    }()
    
    lazy var toolbar: UIView =
    {
        let toolbar = UIView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.app_beige.withAlphaComponent(0.5)
        self.view.addSubview(toolbar)
        self.view.bringSubview(toFront: toolbar)
        toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        toolbar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        self.toolbarBottomLayoutConstraint = toolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 44.0)
        self.toolbarBottomLayoutConstraint?.isActive = true
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        toolbar.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.topAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor).isActive = true
        
        toolbar.addSubview(self.toolbarStackView)
        
        self.toolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        self.toolbarStackView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 8.0).isActive = true
        self.toolbarStackView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8.0).isActive = true
        self.toolbarStackView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8.0).isActive = true
        self.toolbarStackView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -8.0).isActive = true

        return toolbar
    }()
    
    lazy var settingsBarButton: UIBarButtonItem =
    {
        let settingsBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(self.didPressSettings(_:)))
        return settingsBarButton
    }()
    
    lazy var locationBarButton: UIBarButtonItem =
    {
        let locationControl = LocationControl(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: 22.0))
        locationControl.addTarget(self, action: #selector(self.didPressLocationButton), for: .touchUpInside)
        let locationBarButton = UIBarButtonItem(customView: locationControl)
        return locationBarButton
    }()
    
    #endif
    
    var network: BikeNetwork?
    {
        didSet
        {
            guard let network = self.network else { return }
            self.title = network.name
            #if os(macOS)
                
            guard let windowController = self.view.window?.windowController as? WindowController else { return }
            windowController.bikeNetwork = self.network
                
            #elseif os(iOS)
                
            guard let url = self.network?.gbfsHref else { return }
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            var feedClient = GBFSFeedClient()
            feedClient.fetchGBFFeeds(with: url)
            { (response) in
                DispatchQueue.main.async
                {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if case .success(let feeds) = response
                    {
                        self.networkFeeds = feeds
                        if self.deeplink != nil && self.view.window != nil
                        {
                            self.deeplink = nil
                            self.didPressInfo(nil)
                        }
                    }
                }
            }
            #endif
        }
    }
    
    var initialDrop = true
    var networkFeeds: [GBFSFeed]?
    var deeplink: Deeplink? = nil
    
    var state = State.networks
    
    weak var delegate: MapViewControllerDelegate?
    
    #if !os(macOS)
    lazy var infoBarButton: UIBarButtonItem =
    {
        let btn = UIButton(type: .infoLight)
        btn.addTarget(self, action: #selector(self.didPressInfo), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: btn)
        return infoBarButton
    }()
    #endif
    var stations = [BikeStation]()
    {
        didSet
        {
            guard self.state == .stations else
            {
                self.setupForStations()
                return
            }
            //guard oldValue != self.stations else { return }
            self.configureForUpdatedStations(oldValue: oldValue)
        }
    }
    
    var networks = [BikeNetwork]()
    {
        didSet
        {
            guard self.state == .networks else
            {
                self.setupForNetworks()
                return
            }
            guard oldValue != self.networks else
            {
                return
            }
            self.configureForUpdatedNetworks(oldValue: oldValue)
        }
    }
    
    var userManager: UserManager
    {
        #if os(macOS)
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else { return UserManager() }
        #else
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        #endif
        return appDelegate.userManager
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.userManager.getUserLocation()
        self.mapView.isHidden = false
        #if !os(macOS)
        #if !os(tvOS)
        self.view.setNeedsLayout()
        self.navigationItem.hidesBackButton = false
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if self.splitViewController?.traitCollection.isSmallerDevice ?? true
        {
            self.setupNotifications()
        }
        self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
        self.mapBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : -44.0
        #else
        self.navigationItem.leftBarButtonItems = nil
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        #endif
        self.setupForNetworks()
        #else
        self.network = UserDefaults.bikeShareGroup.homeNetwork
        if self.network == nil
        {
            self.fetchNetworks()
        }
        else
        {
            self.fetchStations()
        }
        #endif
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(alongsideTransition: { (_) in })
        { (_) in
            self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
            self.mapBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : -44.0
            self.view.layoutIfNeeded()
        }
    }
    
    #if !os(macOS)
    func setupNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillAppear(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.view.bringSubview(toFront: self.toolbar)
        if case State.stations = self.state
        {
            self.title = self.network?.name ?? ""
            if self.deeplink != nil && self.networkFeeds != nil
            {
                self.deeplink = nil
                self.didPressInfo(nil)
            }
        }
        self.segmentedControl.selectedSegmentIndex = self.filterState.rawValue
        self.view.layoutIfNeeded()
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    #endif
    //MARK: - UI Helpers
    func setupForStations()
    {
        self.title = self.network?.name ?? ""
        self.state = .stations
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.configureForUpdatedStations(oldValue: [])
        self.initialDrop = false
        #if os(iOS)
        self.navigationItem.rightBarButtonItems = (self.network?.gbfsHref == nil) ? [self.locationBarButton, self.settingsBarButton] : [self.infoBarButton, self.locationBarButton, self.settingsBarButton]
        self.toolbarStackView.arrangedSubviews.forEach { self.toolbarStackView.removeArrangedSubview($0) }
        self.toolbarStackView.addArrangedSubview(self.searchBar)
        self.toolbarStackView.addArrangedSubview(self.segmentedControl)
        #endif
    }
    
    func setupForNetworks()
    {
        self.title = "Networks"
        self.state = .networks
        self.navigationItem.rightBarButtonItems = [self.locationBarButton]
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.configureForUpdatedNetworks(oldValue: [])
        self.initialDrop = false
        #if os(iOS)
        self.toolbarStackView.arrangedSubviews.forEach { self.toolbarStackView.removeArrangedSubview($0) }
        self.toolbarStackView.addArrangedSubview(self.searchBar)
        #endif
    }
    
    func configureForUpdatedNetworks(oldValue: [BikeNetwork])
    {
        let oldArray = oldValue
        let oldSet = Set(oldArray)
        let newArray = self.networks
        let newSet = Set(newArray)
        
        let removed = oldSet.subtracting(newSet)
        let inserted = newSet.subtracting(oldSet)
        let annotationsToRemove = self.mapView.annotations.filter
        {
            guard let annotation = $0 as? MapBikeNetwork else { return false }
            return removed.contains(annotation.bikeNetwork)
        }
        self.mapView.removeAnnotations(annotationsToRemove)
        self.mapView.addAnnotations(inserted.map(MapBikeNetwork.init))
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
    
    func configureForUpdatedStations(oldValue: [BikeStation])
    {
        let oldArray = oldValue
        let oldSet = Set(oldArray)
        let newArray = self.stations
        let newSet = Set(newArray)
        
        let removed = oldSet.subtracting(newSet)
        let inserted = newSet.subtracting(oldSet)
        let annotationsToRemove = self.mapView.annotations.filter
        {
            guard let annotation = $0 as? MapBikeStation else { return false }
            return removed.contains(annotation.bikeStation)
        }
        self.mapView.removeAnnotations(annotationsToRemove)
        self.mapView.addAnnotations(inserted.map(MapBikeStation.init))
        self.mapView.showAnnotations(self.mapView.annotations.filter({ $0 is MapBikeStation }), animated: true)
    }
    
    func focus(on stations: [BikeStation])
    {
        guard self.state == .stations else { return }
        let annotations = self.mapView.annotations.filter
        { annotation in
            guard let annotation = annotation as? MapBikeStation else { return false }
            return stations.contains(annotation.bikeStation)
        }
        self.mapView.showAnnotations(annotations, animated: true)
        annotations.forEach
        {
            self.mapView.selectAnnotation($0, animated: true)
        }
    }
    
    #if !os(macOS)
    @objc func didPressInfo(_ sender: UIButton?)
    {
        guard let network = self.network,
            let systemInfoVC = NetworkSystemInformationTableViewController(network: network, feeds: self.networkFeeds)
        else { return }
        let navVC = UINavigationController(rootViewController: systemInfoVC)
        #if !os(tvOS)
        navVC.modalPresentationStyle = .formSheet
        #endif
        navVC.modalTransitionStyle = .coverVertical
        self.present(navVC, animated: true)
    }
    
    func segmentedControlDidChange(_ segmentedControl: UISegmentedControl)
    {
        guard let filterState = FilterState(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        self.delegate?.didSet(filterState: filterState)
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
        switch self.state
        {
        case .networks:
            let closeNetworks = self.networks.prefix(3)
            let closeAnnotations = self.mapView.annotations.filter
            {
                guard let network = $0 as? MapBikeNetwork else { return false}
                return closeNetworks.contains(network.bikeNetwork)
            }
            self.mapView.showAnnotations(closeAnnotations, animated: true)
        case .stations:
            let closeStations = self.stations.prefix(2)
            let closeAnnotations = self.mapView.annotations.filter
            {
                guard let station = $0 as? MapBikeStation else { return false}
                return closeStations.contains(station.bikeStation)
            }
            self.mapView.showAnnotations(closeAnnotations, animated: true)
        }
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
    
    func keyboardWillAppear(notification: Notification)
    {
        let userInfo = notification.userInfo
        guard let frame = userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval else
        {
            return
        }
        UIView.animate(withDuration: duration, animations:
            { [unowned self] in
                self.toolbarBottomLayoutConstraint?.constant = -frame.height
        }) { (_) in
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
        self.view.layoutIfNeeded()
    }
    
    func keyboardWillHide(notification: Notification)
    {
        let userInfo = notification.userInfo
        guard let duration = userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval else
        {
            return
        }
        UIView.animate(withDuration: duration, animations:
            { [unowned self] in
                self.toolbarBottomLayoutConstraint?.constant = 0.0
        }) { (_) in
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
        self.view.layoutIfNeeded()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let press = presses.first,
            let menuSplitVC = self.splitViewController as? MenuSplitViewController,
            press.type == .menu
            else
        {
            super.pressesBegan(presses, with: event)
            return
        }
        menuSplitVC.updateFocusToMasterViewController()
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let press = presses.first,
            let menuSplitVC = self.splitViewController as? MenuSplitViewController,
            press.type == .menu
            else
        {
            super.pressesEnded(presses, with: event)
            return
        }
        menuSplitVC.updateFocusToMasterViewController()
    }
    #endif
    
    func handleDeeplink(deeplink: Deeplink)
    {
        switch deeplink
        {
        case .network, .station:
            break
        case .systemInfo:
            if !self.stations.isEmpty
            {
                #if !os(macOS)
                self.didPressInfo(nil)
                #endif
            }
            else
            {
                self.deeplink = deeplink
            }
        }
    }
}

//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate
{
    #if !os(macOS)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let identifier = "Bike"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil
        {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        switch self.state
        {
        case .networks:
            guard annotation is MapBikeNetwork else { return nil }
            annotationView?.annotation = annotation
            annotationView?.pinTintColor = UIColor.app_blue
            let network = annotation as! MapBikeNetwork
            let bikeNetworkDetailView = BikeDetailCalloutAccessoryView(annotation: BikeDetailCalloutAnnotation.mapBikeNetwork(network: network))
            bikeNetworkDetailView.delegate = self
            annotationView?.detailCalloutAccessoryView = bikeNetworkDetailView
            
        case .stations:
            guard annotation is MapBikeStation,
                  let network = self.network
            else { return nil }
            annotationView?.annotation = annotation
            let station = annotation as! MapBikeStation
            annotationView?.pinTintColor = station.bikeStation.pinTintColor
            let bikeStationDetailView = BikeDetailCalloutAccessoryView(annotation: .mapBikeStation(network: MapBikeNetwork(bikeNetwork: network),station: station))
            bikeStationDetailView.delegate = self
            annotationView?.detailCalloutAccessoryView = bikeStationDetailView
        }
        
        annotationView?.canShowCallout = true
        annotationView?.animatesDrop = self.initialDrop
        
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: annotationView!.detailCalloutAccessoryView!)
        }
        
        return annotationView
    }
    #endif
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        #if !os(macOS)
            self.searchBar.showsCancelButton = false
            self.searchBar.resignFirstResponder()
        #endif
        switch self.state
        {
        case .networks:
            guard let mapBikeNetwork = view.annotation as? MapBikeNetwork else { return }
            self.delegate?.didRequestCallout(forMapBikeNetwork: mapBikeNetwork)
        case .stations:
            guard let mapBikeStation = view.annotation as? MapBikeStation else { return }
            self.delegate?.didRequestCallout(forMapBikeStation:  mapBikeStation)
        }
    }
}

#if !os(macOS)
extension MapViewController: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        self.delegate?.didChange(searchText: searchBar.text ?? "")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
}
    
// MARK: - UIViewControllerPreviewingDelegate
extension MapViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let annotation = self.mapView.selectedAnnotations.first else { return nil }
        if annotation is MapBikeStation
        {
            let mapBikeStation = annotation as! MapBikeStation
            guard let network = self.network else { return nil }
            let stationDetailViewController = StationDetailViewController(with: network, station: mapBikeStation.bikeStation, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(network.id))
            return stationDetailViewController
        }
        else if annotation is MapBikeNetwork
        {
            let mapBikeNetwork = annotation as! MapBikeNetwork
            let stationsTableViewController = StationsTableViewController(with: mapBikeNetwork.bikeNetwork)
            return stationsTableViewController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        if let stationDetailViewController = viewControllerToCommit as? StationDetailViewController
        {
            self.didSelectStationCallout(with: MapBikeStation(bikeStation: stationDetailViewController.station))
        }
        else if let stationsTableViewController = viewControllerToCommit as? StationsTableViewController
        {
            self.didSelectNetworkCallout(with: MapBikeNetwork(bikeNetwork: stationsTableViewController.network))
        }
    }
    
    func bouncePin(for station: BikeStation)
    {
        let annotations = self.mapView.annotations.filter
        { annotation in
            guard let annot = annotation as? MapBikeStation,
                annot.bikeStation.id == station.id
                else { return false }
            return true
        }
        guard let annotation = annotations.last else { return }
        guard let view = self.mapView.view(for: annotation) else { return }
        let center = view.center
        UIView.animate(withDuration: 0.2, animations: {
            view.center = CGPoint(x: view.center.x, y: view.center.y - 100.0)
        }) { (_) in
            UIView.animate(withDuration: 0.2)
            {
                view.center = center
            }
        }
    }
    
    func bouncePin(for network: BikeNetwork)
    {
        let annotations = self.mapView.annotations.filter
        { annotation in
            guard let annot = annotation as? MapBikeNetwork,
                annot.bikeNetwork.id == network.id
                else { return false }
            return true
        }
        guard let annotation = annotations.last else { return }
        guard let view = self.mapView.view(for: annotation) else { return }
        let center = view.center
        UIView.animate(withDuration: 0.2, animations: {
            view.center = CGPoint(x: view.center.x, y: view.center.y - 100.0)
        }) { (_) in
            UIView.animate(withDuration: 0.2)
            {
                view.center = center
            }
        }
    }
}
#endif

//MARK: - BikeDetailCalloutAccessoryViewDelegate
extension MapViewController: BikeDetailCalloutAccessoryViewDelegate
{
    func didSelectNetworkCallout(with mapBikeNetwork: MapBikeNetwork)
    {
        self.delegate?.didSelect(mapBikeNetwork: mapBikeNetwork)
    }
    
    func didSelectStationCallout(with mapBikeStation: MapBikeStation)
    {
        self.delegate?.didSelect(mapBikeStation: mapBikeStation)
    }
}

