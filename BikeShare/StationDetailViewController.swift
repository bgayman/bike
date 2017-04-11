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

class StationDetailViewController: UIViewController
{
    let network: BikeNetwork
    var station: BikeStation
    var stations: [BikeStation]
    
    lazy var annotation: MapBikeStation =
    {
        return MapBikeStation(bikeStation: self.station)
    }()
    
    lazy var mapView: MKMapView =
    {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.removeAnnotations(mapView.annotations)
        mapView.showsUserLocation = true
        mapView.addAnnotation(self.annotation)
        mapView.showAnnotations([self.annotation], animated: false)
        mapView.delegate = self
        return mapView
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
        #if !os(tvOS)
        tableView.allowsSelection = false
        #endif
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StationDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 65.0
        tableView.rowHeight = UITableViewAutomaticDimension
        return tableView
    }()
    
    lazy var closebyStations: [BikeStation]! =
    {
        let sortedStations = self.stations.sorted{ $0.0.distance(to: self.station) < $0.1.distance(to: self.station) }
        let closebyStations = Array(sortedStations.prefix(8))
        self.mapView.addAnnotations(closebyStations.map(MapBikeStation.init))
        return closebyStations
    }()
    
    lazy var visualEffectView: UIVisualEffectView =
    {
        let visualEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.alpha = 0.0
        return visualEffectView
    }()
    
    #if !os(tvOS)
    lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        return refresh
    }()
    #endif

    
    lazy var tableHeaderView: UIView =
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
    lazy var actionBarButton: UIBarButtonItem =
    {
        let actionBarButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.didPressAction))
        return actionBarButton
    }()
    #endif
    
    var mapHeight: CGFloat
    {
        return self.view.bounds.height * 0.3
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
        return [share, back]
    }
    #endif
    
    //MARK: - LifeCycle
    init(with network: BikeNetwork, station: BikeStation, stations: [BikeStation])
    {
        self.network = network
        self.station = station
        self.stations = stations.filter { $0.id != station.id }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        #if !os(tvOS)
            self.view.backgroundColor = .white
            self.setupNavigationBar()
            self.tableView.addSubview(refresh)
            self.addQuickAction()
            self.addToSpotlight()
        #else
            self.view.backgroundColor = .clear
        #endif
        self.mapView.delegate = self
        self.title = self.station.name
        self.tableView.tableHeaderView = self.tableHeaderView
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func applicationWillEnterForeground()
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
    func didPressDone()
    {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    #if !os(tvOS)
    func didPressAction()
    {
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.network.id)/station/\(self.station.id)") else { return }
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let presenter = activityController.popoverPresentationController
        {
            presenter.barButtonItem = self.actionBarButton
        }
        self.present(activityController, animated: true)
    }
    #endif
    
    func back()
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
                    if let bikeStation = stations.filter({ $0.id == self.station.id }).first
                    {
                        self.station = bikeStation
                        let index = stations.index(of: bikeStation)!
                        stations.remove(at: index)
                        let oldValue = self.closebyStations
                        self.closebyStations = nil
                        self.stations = stations
                        self.tableView.animateUpdate(with: oldValue!, newDataSource: self.closebyStations)
                    }
                }
            }
        }
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
    
    func openMapBikeStationInMaps(_ mapBikeStation: MapBikeStation)
    {
        let placemark = MKPlacemark(coordinate: mapBikeStation.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mapBikeStation.title
        mapItem.openInMaps(launchOptions: nil)
    }
    #endif
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let identifier = "Bike"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil
        {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        guard let station = annotation as? MapBikeStation else
        {
            return nil
        }
        annotationView?.pinTintColor = station.bikeStation.pinTintColor
        annotationView?.canShowCallout = true
        annotationView?.animatesDrop = true
        return annotationView
    }
}

//MARK: - TableView
extension StationDetailViewController: UITableViewDelegate, UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0: return 1
        case 1: return self.closebyStations.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0: return self.station.name
        case 1: return "Close By Stations"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDetailTableViewCell
        switch indexPath.section
        {
        case 0:
            cell.bikeStation = self.station
        case 1:
            cell.bikeStation = self.closebyStations[indexPath.row]
        default:
            break
        }
        if self.traitCollection.isSmallerDevice
        {
            #if !os(tvOS)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 0)
            #endif
        }
        else
        {
            #if !os(tvOS)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 90)
            #endif
            cell.titleLabel.textAlignment = .center
            cell.subtitleLabel.textAlignment = .center
        }
        #if !os(tvOS)
        cell.contentView.backgroundColor = .white
        #else
        cell.contentView.backgroundColor = .clear
        #endif
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        self.visualEffectView.alpha = min(scrollView.contentOffset.y / self.mapHeight * 2, 1)
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

