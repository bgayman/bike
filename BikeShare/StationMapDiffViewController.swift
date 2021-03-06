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
    
    @objc lazy var infoBarButton: UIBarButtonItem =
    {
        let btn = UIButton(type: .infoLight)
        btn.addTarget(self, action: #selector(self.didPressInfo), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: btn)
        return infoBarButton
    }()
    
    @objc lazy var activityIndicator: UIActivityIndicatorView =
    {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        return activityIndicator
    }()
    
    lazy var stationDiffViewController: StationDiffViewController =
    {
        let stationDiffViewController = StationDiffViewController(bikeNetwork: network, bikeStations: bikeStations, bikeStationDiffs: bikeStationDiffs)
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
        
        view.backgroundColor = UIColor.app_beige
        navigationItem.titleView = self.activityIndicator
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItems = [self.refreshButton, self.infoBarButton]
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
    @objc func didPressRefresh(sender: UIBarButtonItem)
    {
        self.navigationItem.titleView = self.activityIndicator
        self.activityIndicator.startAnimating()
        self.fetchStations()
    }
    
    @objc func didPressDone(sender: UIBarButtonItem)
    {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @objc func poweredByPressed()
    {
        let safariVC = SFSafariViewController(url: URL(string: "https://citybik.es/#about")!)
        self.present(safariVC, animated: true)
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
        let velocity = sender.velocity(in: view)
        let translation = sender.translation(in: view)
        switch sender.state
        {
        case .began:
            bottomConstraintStartValue = tableViewContainerToBottomConstraint.constant
        case .changed:
            tableViewContainerToBottomConstraint.constant = max(115.0, bottomConstraintStartValue + -translation.y)
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

