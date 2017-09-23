//
//  StationDetailViewController.swift
//  BikeShare
//
//  Created by B Gay on 12/27/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit
import MapKit
import CoreSpotlight
import MobileCoreServices
#if !os(tvOS)
import Charts
#endif

class StationDetailViewController: UIViewController
{
    enum StationDetailSection
    {
        case graph
        case station
        case nearBy
    }
    
    let network: BikeNetwork
    @objc var hasGraph: Bool
    var station: BikeStation
    var stations: [BikeStation]
    var stationStatuses: [BikeStationStatus]?
    {
        didSet
        {
            guard self.stationStatuses != nil else
            {
                self.hasGraph = false
                self.tableView.deleteSections(IndexSet([0]), with: .automatic)
                return
            }
            let bikeStationStatus = BikeStationStatus(numberOfBikesAvailable: self.station.freeBikes ?? 0,
                                                      stationID: self.station.id,
                                                      id: 0,
                                                      networkID: self.network.id,
                                                      timestamp: Date(),
                                                      numberOfDocksDisabled: self.station.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled,
                                                      numberOfDocksAvailable: self.station.emptySlots,
                                                      numberOfBikesDisabled: self.station.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled,
                                                      isRenting: self.station.gbfsStationInformation?.stationStatus?.isRenting,
                                                      isReturning: self.station.gbfsStationInformation?.stationStatus?.isReturning,
                                                      isInstalled: self.station.gbfsStationInformation?.stationStatus?.isInstalled)
            self.stationStatuses?.append(bikeStationStatus)
            let indexPath = IndexPath(row: 0, section: self.sectionIndex(for: .graph) ?? 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc lazy var annotation: MapBikeStation =
    {
        return MapBikeStation(bikeStation: self.station)
    }()
    
    @objc lazy var mapView: MKMapView =
    {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.removeAnnotations(mapView.annotations)
        mapView.showsUserLocation = false
        mapView.addAnnotation(self.annotation)
        mapView.showAnnotations([self.annotation], animated: false)
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Bike")
        return mapView
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
        #if !os(tvOS)
        tableView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        tableView.register(StationDetailGraphTableViewCell.self, forCellReuseIdentifier: "\(StationDetailGraphTableViewCell.self)")
        #endif
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StationDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 65.0
        return tableView
    }()
    
    var closebyStations = [BikeStation]()
    
    @objc lazy var visualEffectView: UIVisualEffectView =
    {
        let visualEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.alpha = 0.0
        return visualEffectView
    }()
    
    #if !os(tvOS)
    @objc lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        return refresh
    }()
    #endif

    
    @objc lazy var tableHeaderView: UIView =
    {
        let tableHeaderView = UIView()
        
        tableHeaderView.addSubview(self.mapView)
        self.mapView.topAnchor.constraint(equalTo: tableHeaderView.topAnchor).isActive = true
        self.mapView.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor).isActive = true
        self.mapView.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor).isActive = true
        self.mapView.bottomAnchor.constraint(equalTo: tableHeaderView.bottomAnchor).isActive = true
        
        tableHeaderView.addSubview(self.visualEffectView)
        self.visualEffectView.topAnchor.constraint(equalTo: tableHeaderView.topAnchor).isActive = true
        self.visualEffectView.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor).isActive = true
        self.visualEffectView.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor).isActive = true
        self.visualEffectView.bottomAnchor.constraint(equalTo: tableHeaderView.bottomAnchor).isActive = true
        return tableHeaderView
    }()
    
    #if !os(tvOS)
    @objc lazy var actionBarButton: UIBarButtonItem =
    {
        let actionBarButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.didPressAction))
        return actionBarButton
    }()
    #endif
    
    override var preferredFocusEnvironments: [UIFocusEnvironment]
    {
        return [self.tableView]
    }
    
    @objc var mapHeight: CGFloat
    {
        return self.view.bounds.height * 0.3
    }
    
    fileprivate var sections: [StationDetailSection]
    {
        if self.hasGraph
        {
            return [.graph, .station, .nearBy]
        }
        return [.station, .nearBy]
    }
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    #if os(iOS)
    override var keyCommands: [UIKeyCommand]?
    {
        let share = UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(self.didPressAction), discoverabilityTitle: "Share")
        let back = UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(self.back), discoverabilityTitle: "Back")
        let refresh = UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(self.fetchStations), discoverabilityTitle: "Refresh")
        return [share, back, refresh]
    }
    #endif
    
    //MARK: - LifeCycle
    init(with network: BikeNetwork, station: BikeStation, stations: [BikeStation], hasGraph: Bool = false)
    {
        self.network = network
        self.hasGraph = hasGraph
        self.station = station
        self.stations = stations.filter { $0.id != station.id }
        super.init(nibName: nil, bundle: nil)
        self.closebyStations = self.closebyStations(for: self.stations)
        self.mapView.addAnnotations(closebyStations.map(MapBikeStation.init))
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
    deinit
    {
        mapView.delegate = nil
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        #if !os(tvOS)
            self.view.backgroundColor = .app_beige
            self.setupNavigationBar()
            self.tableView.addSubview(refresh)
            self.addQuickAction()
            self.addToSpotlight()
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        #else
            self.view.backgroundColor = .clear
            self.tableView.backgroundColor = .clear
        #endif
        self.mapView.delegate = self
        self.title = self.station.name
        self.tableView.tableHeaderView = self.tableHeaderView
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        if self.hasGraph
        {
            self.fetchHistory()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.fetchStations()
    }
    
    @objc func applicationWillEnterForeground()
    {
        self.tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.mapHeight)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool
    {
        if let cell = UIScreen.main.focusedView as? UITableViewCell,
           let indexPath = self.tableView.indexPath(for: cell),
           indexPath.section == 1,
           indexPath.row == 0,
           context.focusHeading == .up
        {
            self.tableView.scrollRectToVisible(self.mapView.frame, animated: true)
        }
        return super.shouldUpdateFocus(in: context)
    }
    
    //MARK: - Actions
    @objc func didPressDone()
    {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    #if !os(tvOS)
    @objc func didPressAction()
    {
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.network.id)/station/\(self.station.id)") else { return }
        
        let customActivity = ActivityViewCustomActivity.stationFavoriteActivity(station: self.station, network: self.network)
        
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: [customActivity])
        if let presenter = activityController.popoverPresentationController
        {
            presenter.barButtonItem = self.actionBarButton
        }
        self.present(activityController, animated: true)
    }
    #endif
    
    @objc func back()
    {
        if self.presentingViewController != nil
        {
            self.didPressDone()
        }
        else
        {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func section(for section: Int) -> StationDetailSection?
    {
        guard 0 ..< self.sections.count ~= section else { return nil }
        return self.sections[section]
    }
    
    fileprivate func sectionIndex(for section: StationDetailSection) -> Int?
    {
        return self.sections.index(of: section)
    }
    
    //MARK: - Networking
    @objc func fetchStations()
    {
        #if !os(tvOS)
        self.setNetworkActivityIndicator(shown: true)
        #endif
        let stationsClient = StationsClient()
        stationsClient.fetchStations(with: self.network, fetchGBFSProperties: true)
        { response in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                self.setNetworkActivityIndicator(shown: false)
                self.navigationItem.prompt = nil
                self.refresh.endRefreshing()
                #endif
                stationsClient.invalidate()
                switch response
                {
                case .error(let errorMessage):
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self.present(alert, animated: true)
                case .success(var stations):
                    guard !stations.isEmpty else
                    {
                        let alert = UIAlertController(errorMessage: "Uh oh, looks like there are no stations for this network.\n\nThis might be for seasonal reasons or this network might no longer exist 😢.")
                        alert.modalPresentationStyle = .overFullScreen
                        self.present(alert, animated: true)
                        return
                    }
                    if let bikeStation = stations.first(where: { $0.id == self.station.id })
                    {
                        let index = stations.index(of: bikeStation)!
                        stations.remove(at: index)
                        let oldValue = self.closebyStations
                        self.stations = stations
                        self.closebyStations = self.closebyStations(for: self.stations)
                        UIView.animate(withDuration: 0.2, animations:
                        {
                            self.tableView.animateUpdate(with: oldValue, newDataSource: self.closebyStations, section: self.sectionIndex(for: .nearBy) ?? 0)
                        },
                       completion: { (_) in
                            if self.station != bikeStation
                            {
                                self.station = bikeStation
                                self.tableView.reloadRows(at: [IndexPath(row: 0, section: self.sections.index(of: StationDetailSection.station) ?? 0)], with: .automatic)
                            }
                        })
                        
                    }
                }
            }
        }
    }
    
    private func fetchHistory()
    {
        #if !os(tvOS)
            self.setNetworkActivityIndicator(shown: true)
        #endif
        let stationsClient = StationsClient()
        stationsClient.fetchStationStatuses(with: self.network.id, stationID: self.station.id)
        { (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    self.setNetworkActivityIndicator(shown: false)
                #endif
                stationsClient.invalidate()
                switch response
                {
                case .error(let errorMessage):
                    self.stationStatuses = nil
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self.present(alert, animated: true)
                case .success(let statuses):
                    #if !os(tvOS)
                        self.stationStatuses = statuses
                    #endif
                }
            }
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let press = presses.first,
            press.type == .menu
            else
        {
            super.pressesBegan(presses, with: event)
            return
        }
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let press = presses.first,
            press.type == .menu
            else
        {
            super.pressesEnded(presses, with: event)
            return
        }
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
    
    fileprivate func closebyStations(for stations: [BikeStation]) -> [BikeStation]
    {
        let sortedStations = stations.sorted{ $0.distance(to: self.station) < $1.distance(to: self.station) }
        let closebyStations = Array(sortedStations.prefix(8))
        self.mapView.showsUserLocation = false
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(closebyStations.map(MapBikeStation.init) + [self.annotation])
        self.mapView.showsUserLocation = true
        return closebyStations
    }
}

//MARK: - MKMapViewDelegate
extension StationDetailViewController: MKMapViewDelegate
{
    #if !os(tvOS)
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        guard let annotation = view.annotation as? MapBikeStation else { return }
        let ac = UIAlertController(title: "Maps", message: "Open in maps?", preferredStyle: .alert)
        let open = UIAlertAction(title: "Open", style: .default)
        { [unowned self] _ in
            self.openMapBikeStationInMaps(annotation)
        }
        ac.addAction(open)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    @objc func openMapBikeStationInMaps(_ mapBikeStation: MapBikeStation)
    {
        let placemark = MKPlacemark(coordinate: mapBikeStation.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mapBikeStation.title
        mapItem.openInMaps(launchOptions: nil)
    }
    #endif
    
    @objc func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard let station = annotation as? MapBikeStation else
        {
            return nil
        }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Bike")
        #if !os(tvOS)
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        #endif
        annotationView.markerTintColor = station.bikeStation.pinTintColor
        annotationView.canShowCallout = true
        return annotationView
    }
}

//MARK: - TableView
extension StationDetailViewController: UITableViewDelegate, UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let section = self.section(for: section) else { return 0 }
        switch section
        {
        case .graph: return 1
        case .station: return 1
        case .nearBy: return self.closebyStations.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let section = self.section(for: section) else { return nil }
        switch section
        {
        case .graph: return "Graph"
        case .station: return self.station.name
        case .nearBy: return "Close By Stations"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let section = self.section(for: indexPath.section) else { return UITableViewCell() }
        var cell: UITableViewCell
        switch section
        {
        case .station:
            let stationCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDetailTableViewCell
            stationCell.bikeStation = self.station
            cell = stationCell
            cell.accessoryType = .none
        case .nearBy:
            let stationCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDetailTableViewCell
            stationCell.bikeStation = self.closebyStations[indexPath.row]
            cell = stationCell
            cell.accessoryType = .disclosureIndicator
        case .graph:
            #if !os(tvOS)
            let graphCell = tableView.dequeueReusableCell(withIdentifier: "\(StationDetailGraphTableViewCell.self)", for: indexPath) as! StationDetailGraphTableViewCell
            if self.stationStatuses != nil
            {
                graphCell.stationStatuses = self.stationStatuses
                let freePlusEmpty = (self.station.freeBikes ?? 0) + (self.station.emptySlots ?? 0)
                graphCell.lineChartView.leftAxis.axisMaximum = Double(self.station.gbfsStationInformation?.capacity ?? freePlusEmpty)
            }
            else
            {
                graphCell.activityIndicator.startAnimating()
            }
            cell = graphCell
            #else
            cell = UITableViewCell()
            #endif
        }
        #if !os(tvOS)
        cell.contentView.backgroundColor = .app_beige
        cell.backgroundColor = .app_beige
        cell.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        #else
        cell.contentView.backgroundColor = .clear
        #endif
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard let section = self.section(for: indexPath.section) else { return 0.0 }
        switch section
        {
        case .nearBy, .station:
            return UITableViewAutomaticDimension
        case .graph:
            return self.mapHeight
        }
    }
}

private extension StationDetailViewController
{
    #if !os(tvOS)
    func addToSpotlight()
    {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeURL as String)
        attributeSet.title = self.station.name
        attributeSet.contentDescription = self.network.name
        let id = "bikeshare://network/\(self.network.id)/station/\(self.station.id)"
        let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: "com.bradgayman.bikeshare", attributeSet: attributeSet)
        
        item.expirationDate = Date.distantFuture
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id])
        { _ in
            CSSearchableIndex.default().indexSearchableItems([item])
            { error in
                if let error = error
                {
                    print(error.localizedDescription)
                }
            }
        }
    }
    #endif
}

//MARK: - Distance
fileprivate extension BikeStation
{
    func distance(to station: BikeStation) -> CLLocationDistance
    {
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let otherStationLocation = CLLocation(latitude: station.coordinates.latitude, longitude: station.coordinates.longitude)
        return stationLocation.distance(from: otherStationLocation)
    }
}

#if !os(tvOS)
class DateValueFormatter: NSObject, IAxisValueFormatter
{
    @objc static let dateFormatter: DateFormatter =
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        return dateFormatter
    }()
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String
    {
        return DateValueFormatter.dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
    // MARK: - ActivityViewCustomActivity
    final class ActivityViewCustomActivity: UIActivity
    {
        static func networkFavoriteActivity(with network: BikeNetwork) -> ActivityViewCustomActivity
        {
            let isHomeNetwork = UserDefaults.bikeShareGroup.isNetworkHomeNetwork(network: network)
            
            let image = isHomeNetwork ? #imageLiteral(resourceName: "Star") : #imageLiteral(resourceName: "Star Filled")
            let title = isHomeNetwork ? "Unmake Home Network" : "Make Home Network"
            
            let customActivity = ActivityViewCustomActivity(title: title, image: image)
            {
                if isHomeNetwork
                {
                    UserDefaults.bikeShareGroup.setHomeNetwork(nil)
                }
                else
                {
                    UserDefaults.bikeShareGroup.setHomeNetwork(network)
                }
            }
            return customActivity
        }
        
        static func stationFavoriteActivity(station: BikeStation, network: BikeNetwork) -> ActivityViewCustomActivity
        {
            let isFavorite = UserDefaults.bikeShareGroup.isStationFavorited(station: station, network: network)
            let image = isFavorite ? #imageLiteral(resourceName: "Star") : #imageLiteral(resourceName: "Star Filled")
            let title = isFavorite ? "Unstar Station" : "Star Station"
            
            let customActivity = ActivityViewCustomActivity(title: title, image: image)
            {
                if isFavorite
                {
                    UserDefaults.bikeShareGroup.removeStationFromFavorites(station: station, network: network)
                }
                else
                {
                    UserDefaults.bikeShareGroup.addStationToFavorites(station: station, network: network)
                }
            }
            return customActivity
        }
        
        static func openMapsActivity(station: BikeStation) -> ActivityViewCustomActivity
        {
            let customActivity = ActivityViewCustomActivity(title: "Open in Maps", image: #imageLiteral(resourceName: "icOpenMaps"))
            {
                let placemark = MKPlacemark(coordinate: station.coordinates)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = station.name
                mapItem.openInMaps(launchOptions: nil)
            }
            return customActivity
        }
        
        // MARK: - Properties
        
        @objc var customActivityType: UIActivityType
        @objc var activityName: String
        @objc var image: UIImage
        @objc var customActionWhenTapped: () -> Void
        
        
        // MARK: - Initializer
        
        @objc init(title: String, image: UIImage, performAction: @escaping () -> Void) {
            self.activityName = title
            self.image = image
            self.customActivityType = UIActivityType(rawValue: "Action \(title)")
            self.customActionWhenTapped = performAction
            super.init()
        }
        
        // MARK: Overrides
        override var activityType: UIActivityType?
        {
            return customActivityType
        }
        
        override var activityTitle: String?
        {
            return activityName
        }
        
        override class var activityCategory: UIActivityCategory
        {
            return .action
        }
        
        override var activityImage: UIImage?
        {
            return self.image
        }
        
        override func canPerform(withActivityItems activityItems: [Any]) -> Bool
        {
            return true
        }
        
        override func prepare(withActivityItems activityItems: [Any])
        {
            // Nothing to prepare
        }
        
        override func perform()
        {
            customActionWhenTapped()
        }
    }
#endif
