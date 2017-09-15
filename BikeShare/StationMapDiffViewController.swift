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
    
    weak var delegate: StationDiffViewControllerDelegate?
    
    var bikeStationDiffs: [BikeStationDiff]
    
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
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Lifecycle
    init(bikeNetwork: BikeNetwork, bikeStations: [BikeStation], bikeStationDiffs: [BikeStationDiff])
    {
        self.bikeStations = bikeStations
        self.network = bikeNetwork
        self.bikeStationDiffs = bikeStationDiffs.sorted()
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
    
    //MARK: - Setup
    private func styleViews()
    {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        self.view.backgroundColor = UIColor.app_beige
        self.navigationItem.titleView = self.activityIndicator
        self.activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItems = [self.refreshButton]
        self.navigationItem.prompt = "Network changes since first viewing."
        
        let overlays = bikeStationDiffs.map { $0.overlay }
        self.mapView.addOverlays(overlays)
    }
    
    //MARK: - Networking
    @objc private func fetchStations()
    {
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
                    self.bikeStationDiffs = diffs.sorted()
                    self.bikeStations = stations
                    self.delegate?.didUpdateBikeStations(stations: stations)
                    self.delegate?.didUpdateBikeStationDiffs(bikeStationDiffs: self.bikeStationDiffs)
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
}

// MARK: - MKMapViewDelegate
extension StationMapDiffViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let render = MKCircleRenderer(overlay: overlay)
        render.alpha = 0.20
        render.fillColor = UIColor.app_blue
        return render
    }
}
