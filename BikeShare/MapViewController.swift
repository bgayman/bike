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
import MobileCoreServices
#endif
import MapKit

enum FilterState: Int
{
    case all
    case favorites
}

//MARK: - MapViewControllerDelegate
protocol MapViewControllerDelegate: class
{
    func didRequestCallout(forMapBikeNetwork: MapBikeNetwork)
    func didRequestCallout(forMapBikeStation: MapBikeStation)
    func didSelect(mapBikeNetwork: MapBikeNetwork)
    func didSelect(mapBikeStation: MapBikeStation)
    func didSet(filterState: FilterState)
    func didChange(searchText: String)
    func didRequestUpdate()
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
    @objc lazy var mapView: MKMapView =
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
        mapView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.mapBottomLayoutConstraint = mapView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor)
        self.mapBottomLayoutConstraint?.isActive = true
            
        self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
        self.mapBottomLayoutConstraint?.constant = 0.0
        
        self.view.bringSubview(toFront: self.toolbar)
        mapView.mapType = .mutedStandard

        #endif
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        return mapView
    }()
    
    @objc var shouldAnimateAnnotationUpdates = true
    #if os(macOS)
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var mapKeyView: MapKeyView!
    #elseif !os(macOS)
    var filterState = FilterState.all
    
    @objc lazy var activityImageView: UIImageView =
    {
        let activityImageView = UIImageView(image: #imageLiteral(resourceName: "icBikeWheel"))
        activityImageView.tintColor = UIColor.lightGray
        activityImageView.contentMode = .scaleAspectFit
        activityImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityImageView)
        activityImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        activityImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        return activityImageView
    }()

    @objc lazy var mapKeyView: MapKeyView =
    {
        let mapKeyView = MapKeyView(frame: CGRect(x: 0, y: 0, width: 255
            , height: 70))
        mapKeyView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mapKeyView)
    
        #if os(tvOS)
            mapKeyView.widthAnchor.constraint(equalToConstant: 600).isActive = true
            mapKeyView.heightAnchor.constraint(equalToConstant: 150).isActive = true
            mapKeyView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        #else
            mapKeyView.widthAnchor.constraint(equalToConstant: 300).isActive = true
            mapKeyView.heightAnchor.constraint(equalToConstant: 70).isActive = true
            mapKeyView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
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
    
    @objc lazy var segmentedControl: UISegmentedControl =
    {
        let segmentedControl = UISegmentedControl(items: ["All", " ★ "])
        segmentedControl.addTarget(self, action: #selector(self.segmentedControlDidChange(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = self.filterState.rawValue
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
        return segmentedControl
    }()
    
    #if !os(tvOS)
    @objc lazy var searchBar: UISearchBar =
    {
        let searchBar = UISearchBar(frame: CGRect(x: 0.0, y: 0.0, width: 210.0, height: 14.0))
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        return searchBar
    }()
    #endif
    
    @objc var toolbarBottomLayoutConstraint: NSLayoutConstraint?
    @objc var mapBottomLayoutConstraint: NSLayoutConstraint?
    
    @objc lazy var scrollView: DrawerScrollView =
    {
        let scrollView = DrawerScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)
        scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        scrollView.clipsToBounds = false
        #if !os(tvOS)
        scrollView.isPagingEnabled = true
        #else
        scrollView.isHidden = true
        #endif
        return scrollView
    }()
    
    @objc lazy var dragHandle: UIView =
    {
        let dragHandle = UIView()
        dragHandle.backgroundColor = .clear
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
        dragHandle.clipsToBounds = false
        
        let handle = UIView()
        handle.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        handle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.addSubview(handle)
        handle.layer.cornerRadius = 2.0
        handle.layer.masksToBounds = true
        handle.heightAnchor.constraint(equalToConstant: 4.0).isActive = true
        handle.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        handle.centerXAnchor.constraint(equalTo: dragHandle.centerXAnchor).isActive = true
        handle.topAnchor.constraint(equalTo: dragHandle.topAnchor, constant: 8.0).isActive = true
        return dragHandle
    }()
    
    #if !os(tvOS)
    @objc lazy var scrollViewToolbar: UIToolbar =
    {
        let toolbar = UIToolbar()
        let items = self.scrollViewStationToolbarItems()
        toolbar.setItems(items, animated: false)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        return toolbar
    }()
    
    @objc lazy var verticalStackView: UIStackView =
    {
        let verticalStackView = UIStackView(arrangedSubviews: [self.dragHandle, self.scrollViewToolbar, self.toolbarStackView])
        verticalStackView.axis = .vertical
        
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        return verticalStackView
    }()
    #endif
    
    @objc lazy var toolbarStackView: UIStackView =
    {
        let toolbarStackView = UIStackView()
        toolbarStackView.axis = .horizontal
        toolbarStackView.spacing = 8.0
        toolbarStackView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        return toolbarStackView
    }()
    
    @objc lazy var refreshButton: UIButton =
    {
        let refreshButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: 22.0))
        refreshButton.setImage(#imageLiteral(resourceName: "refresh"), for: .normal)
        refreshButton.addTarget(self, action: #selector(self.didPressRefresh), for: .touchUpInside)
        refreshButton.tintColor = UIColor.app_blue
        return refreshButton
    }()
    
    @objc lazy var toolbar: UIView =
    {
        let toolbar = UIView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.app_beige.withAlphaComponent(0.2)
        self.scrollView.addSubview(toolbar)
        self.view.bringSubview(toFront: self.scrollView)
        toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        toolbar.heightAnchor.constraint(equalToConstant: 400.0).isActive = true
        toolbar.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: -20.0).isActive = true
        toolbar.layer.cornerRadius = 20.0
        toolbar.layer.masksToBounds = true
        
        self.toolbarBottomLayoutConstraint = self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 50.0)
        self.toolbarBottomLayoutConstraint?.isActive = true
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        toolbar.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.topAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor).isActive = true
        
        #if !os(tvOS)
        toolbar.addSubview(self.verticalStackView)
        
        self.verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        self.verticalStackView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 0.0).isActive = true
        self.verticalStackView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8.0).isActive = true
        self.verticalStackView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8.0).isActive = true
        self.verticalStackView.heightAnchor.constraint(equalToConstant: 108).isActive = true
        #endif
        return toolbar
    }()
    
    @objc lazy var settingsBarButton: UIBarButtonItem =
    {
        let settingsBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "icMapKey"), style: .plain, target: self, action: #selector(self.didPressSettings(_:)))
        return settingsBarButton
    }()
    
    @objc lazy var locationBarButton: UIBarButtonItem =
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
    
    @objc var initialDrop = true
    var networkFeeds: [GBFSFeed]?
    var deeplink: Deeplink? = nil
    
    var state = State.networks
    
    weak var delegate: MapViewControllerDelegate?
    
    #if !os(macOS)
    @objc lazy var infoBarButton: UIBarButtonItem =
    {
        let btn = UIButton(type: .infoLight)
        btn.addTarget(self, action: #selector(self.didPressInfo), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: btn)
        return infoBarButton
    }()
    
    @objc lazy var refreshBarButton: UIBarButtonItem =
    {
        let refreshBarButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.didPressRefresh))
        return refreshBarButton
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
            guard oldValue != self.stations else { return }
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
    
    @objc var userManager: UserManager
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
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.addInteraction(UIDropInteraction(delegate: self))
        self.navigationItem.hidesBackButton = false
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if self.splitViewController?.traitCollection.isSmallerDevice ?? true
        {
            self.setupNotifications()
        }
        self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
        self.mapBottomLayoutConstraint?.constant = 0.0
        #else
        self.navigationItem.leftBarButtonItems = nil
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        #endif
        self.setupForNetworks()
        self.prepActivityAnimation()
        if mapView.annotations.isEmpty || mapView.annotations is [MKUserLocation]
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                self.animateActivityView()
            }
            
        }
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
    
    #if !os(macOS)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(alongsideTransition: { (_) in })
        { (_) in
            #if !os(tvOS)
            self.setupScrollView()
            self.toolbarBottomLayoutConstraint?.constant = (self.splitViewController?.traitCollection.isSmallerDevice ?? true) ? 0.0 : 44.0
            self.mapBottomLayoutConstraint?.constant = 0.0
            #endif
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        #if !os(tvOS)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: 100.0)
        #endif
    }
    
    @objc func setupNotifications()
    {
        #if !os(tvOS)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillAppear(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
            NotificationCenter.default.when(.BikeStationDidAddToFavorites)
            { [weak self] (_) in
                if self?.state == .stations
                {
                    let items = self?.scrollViewStationToolbarItems()
                    self?.scrollViewToolbar.setItems(items, animated: true)
                }
            }
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        #if !os(tvOS)
        self.view.bringSubview(toFront: self.toolbar)
        #endif
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
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        #if !os(tvOS)
        self.view.bringSubview(toFront: scrollView)
        #endif
    }
    
    @objc private func didPressRefresh()
    {
        self.delegate?.didRequestUpdate()
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
        mapView.delegate = nil
    }
    #endif
    
    //MARK: - UI Helpers
    @objc func setupForStations()
    {
        self.title = self.network?.name ?? ""
        self.state = .stations
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.configureForUpdatedStations(oldValue: [])
        self.initialDrop = false
        #if os(iOS)
        setupScrollView()
        self.toolbarStackView.arrangedSubviews.forEach { self.toolbarStackView.removeArrangedSubview($0) }
        self.toolbarStackView.addArrangedSubview(self.searchBar)
        #endif
    }
    
    @objc func setupForNetworks()
    {
        self.state = .networks
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.configureForUpdatedNetworks(oldValue: [])
        self.initialDrop = false
        #if os(iOS)
        self.title = self.splitViewController?.traitCollection.isSmallerDevice ?? true ? "Networks" : ""
        setupScrollView()
        self.toolbarStackView.arrangedSubviews.forEach { self.toolbarStackView.removeArrangedSubview($0) }
        self.toolbarStackView.addArrangedSubview(self.searchBar)
        #endif
    }
    
    #if !os(tvOS)
    fileprivate func setupScrollView()
    {
        switch state
        {
        case .networks:
            if self.splitViewController?.traitCollection.isSmallerDevice == true || self.splitViewController == nil
            {
                self.navigationItem.rightBarButtonItems = []
                self.scrollView.isHidden = false
                let items = [self.settingsBarButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), self.locationBarButton]
                scrollViewToolbar.setItems(items, animated: true)
            }
            else
            {
                self.navigationItem.rightBarButtonItems = [self.locationBarButton, self.settingsBarButton]
                self.scrollView.isHidden = true
            }
        case .stations:
            if self.splitViewController?.traitCollection.isSmallerDevice == true || self.splitViewController == nil
            {
                self.navigationItem.rightBarButtonItems = [refreshBarButton]
                self.scrollView.isHidden = false
                let items = scrollViewStationToolbarItems()
                scrollViewToolbar.setItems(items, animated: true)
            }
            else
            {
                self.navigationItem.rightBarButtonItems = (self.network?.gbfsHref == nil) ? [self.locationBarButton, self.settingsBarButton] : [self.infoBarButton, self.locationBarButton, self.settingsBarButton]
                self.scrollView.isHidden = true
            }
        }
    }
    
    func scrollViewStationToolbarItems() -> [UIBarButtonItem]
    {
        guard let network = network else { return [] }
        var items = self.network?.gbfsHref != nil ?
            [self.settingsBarButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), self.infoBarButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), self.locationBarButton] :
            [self.settingsBarButton, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), self.locationBarButton]
        if UserDefaults.bikeShareGroup.favoriteStations(for: network).isEmpty == false
        {
            items = items + [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(customView: segmentedControl)]
        }
        return items
    }
    #endif
    
    func configureForUpdatedNetworks(oldValue: [BikeNetwork], animated: Bool = true)
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
        if self.shouldAnimateAnnotationUpdates
        {
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    func configureForUpdatedStations(oldValue: [BikeStation], animated: Bool = true)
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
        if self.shouldAnimateAnnotationUpdates
        {
            self.mapView.showAnnotations(self.mapView.annotations.filter({ $0 is MapBikeStation }), animated: true)
        }
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
    
    func focus(on networks: [BikeNetwork])
    {
        guard self.state == .networks else { return }
        let annotations = self.mapView.annotations.filter
        { annotation in
            guard let annotation = annotation as? MapBikeNetwork else { return false }
            return networks.contains(annotation.bikeNetwork)
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
    
    @objc func segmentedControlDidChange(_ segmentedControl: UISegmentedControl)
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
    
    @objc func didPressLocationButton()
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
            var closeAnnotations = self.mapView.annotations.filter
            {
                guard let network = $0 as? MapBikeNetwork else { return false}
                return closeNetworks.contains(network.bikeNetwork)
            }
            closeAnnotations.append(self.mapView.userLocation)
            self.mapView.showAnnotations(closeAnnotations, animated: true)
        case .stations:
            let closeStations = self.stations.prefix(2)
            var closeAnnotations = self.mapView.annotations.filter
            {
                guard let station = $0 as? MapBikeStation else { return false}
                return closeStations.contains(station.bikeStation)
            }
            closeAnnotations.append(self.mapView.userLocation)
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
    
    private func prepActivityAnimation()
    {
        let scale = CGAffineTransform(scaleX: 0.1, y: 0.1)
        activityImageView.transform = scale.concatenating(CGAffineTransform(translationX: 0.0, y: UIScreen.main.bounds.height))
        
    }
    
    private func animateActivityView()
    {
        self.view.bringSubview(toFront: self.activityImageView)
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.activityImageView.transform = .identity
        },
        completion:
        { [unowned self] (_) in
            UIView.animate(withDuration: 1.0, delay: 0.0, options: [.beginFromCurrentState, .repeat, .curveLinear], animations:
            { [unowned self] in
                var transform = self.activityImageView.transform
                transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat.pi))
                self.activityImageView.transform = transform
            },
           completion:
            { [unowned self] _ in
                UIView.animate(withDuration: 1.0, delay: 0.0, options: [.beginFromCurrentState, .curveLinear], animations:
                { [unowned self] in
                    var transform = self.activityImageView.transform
                    transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat.pi / 2.0))
                    self.activityImageView.transform = transform
                })
            })
        })
    }
    
    private func animateActivityOff()
    {
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.activityImageView.transform = CGAffineTransform(translationX: 0.0, y: -UIScreen.main.bounds.height * 0.75)
        },
        completion:
        { [unowned self] (_) in
            self.activityImageView.isHidden = true
        })
    }
    
    #if !os(tvOS)
    @objc func keyboardWillAppear(notification: Notification)
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
    
    @objc func keyboardWillHide(notification: Notification)
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
    #endif
    
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
        if annotation is MKClusterAnnotation
        {
            switch state
            {
            case .networks:
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "networkCluster") as? NetworkClusterView
                if annotationView == nil
                {
                    annotationView = NetworkClusterView(annotation: annotation, reuseIdentifier: "networkCluster")
                }
                return annotationView
            case .stations:
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? StationClusterView
                if annotationView == nil
                {
                    annotationView = StationClusterView(annotation: annotation, reuseIdentifier: "cluster")
                }
                return annotationView
            }
        }
        var annotationView: MKMarkerAnnotationView?
        switch self.state
        {
        case .networks:
            guard annotation is MapBikeNetwork else { return nil }
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "network") as? MKMarkerAnnotationView
            if annotationView == nil
            {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "network")
            }
            annotationView?.annotation = annotation
            annotationView?.markerTintColor = UIColor.app_blue
            let network = annotation as! MapBikeNetwork
            let bikeNetworkDetailView = BikeDetailCalloutAccessoryView(annotation: BikeDetailCalloutAnnotation.mapBikeNetwork(network: network))
            bikeNetworkDetailView.delegate = self
            annotationView?.detailCalloutAccessoryView = bikeNetworkDetailView
            annotationView?.clusteringIdentifier = "network"
            annotationView?.displayPriority = MKFeatureDisplayPriority(rawValue: MKFeatureDisplayPriority.RawValue(UserDefaults.standard.isNetworkHomeNetwork(network: network.bikeNetwork) ? 1000 : 500))
            
        case .stations:
            guard annotation is MapBikeStation,
                  let network = self.network
            else { return nil }
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "station") as? MKMarkerAnnotationView
            if annotationView == nil
            {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "station")
            }
            annotationView?.annotation = annotation
            let station = annotation as! MapBikeStation
            annotationView?.markerTintColor = station.bikeStation.pinTintColor
            let bikeStationDetailView = BikeDetailCalloutAccessoryView(annotation: .mapBikeStation(network: MapBikeNetwork(bikeNetwork: network),station: station))
            bikeStationDetailView.delegate = self
            annotationView?.detailCalloutAccessoryView = bikeStationDetailView
            annotationView?.clusteringIdentifier = "station"
            let capacity = (station.bikeStation.emptySlots ?? 0) + (station.bikeStation.freeBikes ?? 0)
            annotationView?.displayPriority = MKFeatureDisplayPriority(rawValue: MKFeatureDisplayPriority.RawValue(UserDefaults.standard.isStationFavorited(station: station.bikeStation, network: network) ? 1000 : capacity))
        }
        
        annotationView?.canShowCallout = true
        
        #if !os(tvOS)
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: annotationView!.detailCalloutAccessoryView!)
        }
        #endif
        
        return annotationView
    }
    
    #if !os(tvOS)
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool)
    {
        if self.searchBar.text?.isEmpty == true
        {
            self.scrollView.setContentOffset(.zero, animated: true)
        }
    }
    #endif
    
    #endif
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView])
    {
        if views.contains(where: { $0 is MKMarkerAnnotationView || $0 is StationClusterView || $0 is NetworkClusterView })
        {
            animateActivityOff()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        #if !(os(macOS) || os(tvOS))
            self.searchBar.showsCancelButton = false
            self.searchBar.resignFirstResponder()
            self.scrollView.setContentOffset(.zero, animated: true)
            if self.traitCollection.forceTouchCapability == .available, let annotationView = view as? MKMarkerAnnotationView,
               let detailCalloutAccessoryView = annotationView.detailCalloutAccessoryView
            {
                self.registerForPreviewing(with: self, sourceView: detailCalloutAccessoryView)
            }
        #endif
        if let cluster = view.annotation as? MKClusterAnnotation
        {
            mapView.showAnnotations(cluster.memberAnnotations, animated: true)
        }
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
    #if !os(tvOS)
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

// MARK: - UIDropInteractionDelegate
extension MapViewController: UIDropInteractionDelegate
{
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool
    {
        return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeURL as String]) && session.items.count == 1
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal
    {
        if session.hasItemsConforming(toTypeIdentifiers: [kUTTypeURL as String])
        {
            return UIDropProposal(operation: .copy)
        }
        return UIDropProposal(operation: .forbidden)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession)
    {
        session.loadObjects(ofClass: NSURL.self)
        { (itemProviders) in
            guard let itemProvider = itemProviders.first as? NSURL,
                  let deeplink = Deeplink(url: itemProvider as URL) else { return }
            DispatchQueue.main.async
            {
                switch deeplink
                {
                case .network(let id):
                    guard let network = self.networks.first(where: { $0.id == id }) else { break }
                    self.focus(on: [network])
                case let .station(_, stationID):
                    guard let station = self.stations.first(where: { $0.id == stationID}) else { break }
                    self.focus(on: [station])
                case .systemInfo:
                    self.didPressInfo(nil)
                }
            }
        }
    }
}
#endif
#if !os(tvOS)
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
            let stationDetailViewController = BikeStationDetailViewController(with: network, station: mapBikeStation.bikeStation, stations: self.stations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(network.id))
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
        if let stationDetailViewController = viewControllerToCommit as? BikeStationDetailViewController
        {
            self.didSelectStationCallout(with: MapBikeStation(bikeStation: stationDetailViewController.bikeStation))
        }
        else if let stationsTableViewController = viewControllerToCommit as? StationsTableViewController
        {
            self.didSelectNetworkCallout(with: MapBikeNetwork(bikeNetwork: stationsTableViewController.network))
        }
    }
}
#endif

extension MapViewController
{
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
    @objc func didSelectNetworkCallout(with mapBikeNetwork: MapBikeNetwork)
    {
        self.delegate?.didSelect(mapBikeNetwork: mapBikeNetwork)
    }
    
    @objc func didSelectStationCallout(with mapBikeStation: MapBikeStation)
    {
        self.delegate?.didSelect(mapBikeStation: mapBikeStation)
    }
}

