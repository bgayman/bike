//
//  StationMapDiffViewController.swift
//  BikeShare
//
//  Created by B Gay on 9/13/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit
import SafariServices
import MobileCoreServices

// MARK: - StationMapDiffViewController
class StationMapDiffViewController: UIViewController
{
    // MARK: - Properties
    let network: BikeNetwork
    var bikeStations: [BikeStation]
    
    // MARK: - Outlets
    @IBOutlet weak var tableViewContainerView: UIView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var tableViewContainerToBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButtonVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var infoButtonVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var refreshButtonVisualEffectView: UIVisualEffectView!
    
    weak var delegate: StationDiffViewControllerDelegate?
    
    var bikeStationDiffs: [BikeStationDiff]
    var bottomConstraintStartValue: CGFloat = 115
    
    @objc lazy var refreshButton: UIBarButtonItem =
    {
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.didPressRefresh(sender:)))
        return refresh
    }()
    
    @objc lazy var doneButton: UIBarButtonItem =
    {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone(sender:)))
        return doneButton
    }()
    
    @objc lazy var activityIndicator: UIActivityIndicatorView =
    {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        return activityIndicator
    }()
    
    lazy var stationDiffViewController: StationDiffViewController =
    {
        let stationDiffViewController = StationDiffViewController(bikeNetwork: network, bikeStations: bikeStations, bikeStationDiffs: bikeStationDiffs)
        stationDiffViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: stationDiffViewController)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(navigationController)
        navigationController.view.frame = self.tableViewContainerView.bounds
        self.tableViewContainerView.insertSubview(navigationController.view, belowSubview: self.handleView)
        navigationController.view.topAnchor.constraint(equalTo: self.tableViewContainerView.topAnchor).isActive = true
        navigationController.view.leadingAnchor.constraint(equalTo: self.tableViewContainerView.leadingAnchor).isActive = true
        navigationController.view.trailingAnchor.constraint(equalTo: self.tableViewContainerView.trailingAnchor).isActive = true
        navigationController.view.bottomAnchor.constraint(equalTo: self.tableViewContainerView.bottomAnchor).isActive = true
        navigationController.didMove(toParentViewController: self)
        return stationDiffViewController
    }()
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Lifecycle
    init(bikeNetwork: BikeNetwork, bikeStations: [BikeStation], bikeStationDiffs: [BikeStationDiff])
    {
        self.bikeStations = bikeStations
        self.network = bikeNetwork
        self.bikeStationDiffs = bikeStationDiffs.sorted().filter { $0.statusText.isEmpty == false }
        super.init(nibName: "\(StationMapDiffViewController.self)", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        styleViews()
        fetchStations()
        stationDiffViewController.tableView.panGestureRecognizer.addTarget(self, action: #selector(self.handlePan(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.fetchStations), object: nil)
    }
    
    //MARK: - Setup
    private func styleViews()
    {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .never
        
        view.addInteraction(UIDropInteraction(delegate: self))
        
        view.backgroundColor = UIColor.app_beige
        navigationItem.titleView = self.activityIndicator
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItems = [self.refreshButton]
        navigationItem.leftBarButtonItem = self.doneButton
        
        let annotations = bikeStations.map(MapBikeStation.init)
        mapView.register(DotAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Dot")
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: true)
        
        stationDiffViewController.view.isHidden = false
        
        tableViewContainerView.layer.cornerRadius = 20
        tableViewContainerView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height * 0.5
        handleView.layer.masksToBounds = true
        
        infoButtonVisualEffectView.layer.cornerRadius = infoButtonVisualEffectView.bounds.height * 0.5
        infoButtonVisualEffectView.layer.masksToBounds = true
        
        closeButtonVisualEffectView.layer.cornerRadius = closeButtonVisualEffectView.bounds.height * 0.5
        closeButtonVisualEffectView.layer.masksToBounds = true
        
        refreshButtonVisualEffectView.layer.cornerRadius = refreshButtonVisualEffectView.bounds.height * 0.5
        refreshButtonVisualEffectView.layer.masksToBounds = true
        
        let overlays = bikeStationDiffs.map { $0.overlay }
        mapView.addOverlays(overlays)
    }
    
    //MARK: - Networking
    @objc private func fetchStations()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.fetchStations), object: nil)
        #if !os(tvOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        let stationsClient = StationsClient()
        stationsClient.fetchStations(with: self.network, fetchGBFSProperties: true)
        { response in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.title = "\(self.network.name) Recent Activity"
                #endif
                stationsClient.invalidate()
                switch response
                {
                case .error(let errorMessage):
                    let alert = UIAlertController(errorMessage: errorMessage)
                    alert.modalPresentationStyle = .overFullScreen
                    self.present(alert, animated: true)
                case .success(let stations):
                    guard !stations.isEmpty else
                    {
                        let alert = UIAlertController(errorMessage: "Uh oh, looks like there are no stations for this network.\n\nThis might be for seasonal reasons or this network might no longer exist 😢.")
                        alert.modalPresentationStyle = .overFullScreen
                        self.present(alert, animated: true)
                        return
                    }
                    self.navigationItem.titleView = nil
                    self.title = self.network.name
                    let newDiffs = BikeStationDiff.performDiff(with: self.bikeStations, newDataSource: stations) ?? [BikeStationDiff]()
                    let diffs =  newDiffs + self.bikeStationDiffs
                    self.mapView.addOverlays(newDiffs.map { $0.overlay })
                    self.bikeStationDiffs = diffs.sorted().filter { $0.statusText.isEmpty == false }
                    self.bikeStations = stations
                    self.stationDiffViewController.bikeStationDiffs = self.bikeStationDiffs
                    self.stationDiffViewController.bikeStations = stations
                    self.delegate?.didUpdateBikeStations(stations: stations)
                    self.delegate?.didUpdateBikeStationDiffs(bikeStationDiffs: self.bikeStationDiffs)
                    self.perform(#selector(self.fetchStations), with: nil, afterDelay: 30.0)
                }
            }
        }
    }
    
    //MARK: - Actions
    @objc func didPressRefresh(sender: UIBarButtonItem?)
    {
        self.navigationItem.titleView = self.activityIndicator
        self.activityIndicator.startAnimating()
        self.fetchStations()
    }
    
    @objc func didPressDone(sender: UIBarButtonItem)
    {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func didPressRefreshButton(_ sender: UIButton)
    {
        didPressRefresh(sender: nil)
    }
    
    @IBAction func didPressClose(_ sender: UIButton)
    {
        self.dismiss(animated: true)
    }
    
    @IBAction func didPressInfoButton(_ sender: UIButton)
    {
        didPressInfo(sender)
    }
    
    @objc func didPressInfo(_ sender: UIButton?)
    {
        let infoViewController = StationDiffingInfoViewController(bikeNetwork: network, bikeStations: bikeStations)
        let navigationController = UINavigationController(rootViewController: infoViewController)
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = infoViewController
        self.present(navigationController, animated: true)
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer)
    {
        if stationDiffViewController.tableView.panGestureRecognizer === sender && stationDiffViewController.tableView.contentOffset.y >= 0.0
        {
            return
        }
        let velocity = sender.velocity(in: view)
        let translation = sender.translation(in: view)
        switch sender.state
        {
        case .began:
            bottomConstraintStartValue = tableViewContainerToBottomConstraint.constant
        case .changed:
            tableViewContainerToBottomConstraint.constant = min(self.view.bounds.height - 40.0, max(115.0, bottomConstraintStartValue + -translation.y))
        case .failed, .possible:
            break
        case .cancelled, .ended:
            if velocity.y >= 0
            {
                animateDown()
            }
            else
            {
                animateUp()
            }
        
        }
    }
    
    //MARK: - Animation
    private func animateDown()
    {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        stationDiffViewController.searchController.isActive = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.tableViewContainerToBottomConstraint.constant = 115.0
            self.view.layoutIfNeeded()
        })
    }
    
    private func animateUp()
    {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [], animations:
        { [unowned self] in
            self.tableViewContainerToBottomConstraint.constant = self.view.bounds.height - 40.0
            self.view.layoutIfNeeded()
        })
    }
    
}

// MARK: - MKMapViewDelegate
extension StationMapDiffViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if overlay is RedMKCircle
        {
            let render = MKCircleRenderer(overlay: overlay)
            render.alpha = 0.3
            render.fillColor = UIColor.app_red
            return render
        }
        else
        {
            let render = MKCircleRenderer(overlay: overlay)
            render.alpha = 0.3
            render.fillColor = UIColor.app_green
            return render
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Dot", for: annotation)
        return view
    }
}

extension StationMapDiffViewController: StationDiffViewControllerDelegate
{
    func didUpdateBikeStations(stations: [BikeStation])
    {
    }
    
    func didUpdateBikeStationDiffs(bikeStationDiffs: [BikeStationDiff])
    {
    }
    
    func didSelectBikeStation(station: BikeStation)
    {
    }
    
    func searchBarDidBecomeActive()
    {
        animateUp()
    }
}

extension StationMapDiffViewController: UIDropInteractionDelegate
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
                case .network:
                    break
                case let .station(_, stationID):
                    let annotation = self.mapView.annotations.flatMap { $0 as? MapBikeStation }.first(where: { $0.bikeStation.id == stationID})
                    guard let station = annotation else { break }
                    self.mapView.showAnnotations([station], animated: true)
                case .systemInfo:
                    break
                }
            }
        }
    }
}

