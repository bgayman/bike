//
//  BikeStationDetailViewController.swift
//  BikeShareTV
//
//  Created by B Gay on 9/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit
import Charts
import Dwifft

// MARK: - Types
enum DetailSections
{
    case detail(station: BikeStation)
    case graph(graphData: [BikeStationStatus]?)
    case closeBy(stations: [BikeStation])
}
extension DetailSections: Equatable
{
    static func == (lhs: DetailSections, rhs: DetailSections) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.detail(let stationLHS), .detail(let stationRHS)):
            return stationLHS == stationRHS
        case (.graph(let graphDataLHS), .graph(let graphDataRHS)):
            switch(graphDataLHS, graphDataRHS)
            {
            case (nil, nil):
                return true
            case (nil, .some), (.some, nil):
                return false
            case (.some(let dataLHS), .some(let dataRHS)):
                return dataLHS == dataRHS
            }
        case (.closeBy(let stationsLHS), .closeBy(let stationsRHS)):
            return stationsLHS == stationsRHS
        default:
            return false
        }
    }
}

// MARK: - BikeStationDetailViewController
class BikeStationDetailViewController: UIViewController
{
    
    // MARK: - Outlets
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    
    // MARK: - Properties
    
    let bikeNetwork: BikeNetwork
    var bikeStation: BikeStation
    var bikeStations: [BikeStation]
    var closebyStations = [BikeStation]()
    let labelAlpha: CGFloat = 0.70
    var hasGraph: Bool
    var titleLabelTopOffset: CGFloat = 0.0
    var sections: [DetailSections] = []
    
    var stationStatuses: [BikeStationStatus]?
    {
        didSet
        {
            guard self.stationStatuses != nil else
            {
                self.hasGraph = false
                return
            }
            let bikeStationStatus = BikeStationStatus(numberOfBikesAvailable: self.bikeStation.freeBikes ?? 0,
                                                      stationID: self.bikeStation.id,
                                                      id: 0,
                                                      networkID: self.bikeNetwork.id,
                                                      timestamp: Date(),
                                                      numberOfDocksDisabled: self.bikeStation.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled,
                                                      numberOfDocksAvailable: self.bikeStation.emptySlots,
                                                      numberOfBikesDisabled: self.bikeStation.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled,
                                                      isRenting: self.bikeStation.gbfsStationInformation?.stationStatus?.isRenting,
                                                      isReturning: self.bikeStation.gbfsStationInformation?.stationStatus?.isReturning,
                                                      isInstalled: self.bikeStation.gbfsStationInformation?.stationStatus?.isInstalled)
            self.stationStatuses?.append(bikeStationStatus)
            updateChartData()
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment]
    {
        return [collectionView]
    }
    
    // MARK: - Lifecycle
    init(with bikeNetwork: BikeNetwork, station: BikeStation, stations: [BikeStation], hasGraph: Bool)
    {
        self.bikeNetwork = bikeNetwork
        self.bikeStation = station
        self.bikeStations = stations
        self.hasGraph = hasGraph
        super.init(nibName: "\(BikeStationDetailViewController.self)", bundle: nil)
        updateSections()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupUI()
        fetchHistory()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.visibleCells.flatMap { $0 as? BikeStationDetailCollectionViewCell }
                                   .forEach { $0.gradientLayer.frame = view.bounds }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        fetchStations()
    }
    
    // MARK: - Setup
    private func setupUI()
    {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let detailNib = UINib(nibName: "\(BikeStationDetailCollectionViewCell.self)", bundle: nil)
        collectionView.register(detailNib, forCellWithReuseIdentifier: "\(BikeStationDetailCollectionViewCell.self)")
        
        let graphNib = UINib(nibName: "\(BikeStationGraphCollectionViewCell.self)", bundle: nil)
        collectionView.register(graphNib, forCellWithReuseIdentifier: "\(BikeStationGraphCollectionViewCell.self)")
        
        let closebyNib = UINib(nibName: "\(BikeStationCloseByCollectionViewCell.self)", bundle: nil)
        collectionView.register(closebyNib, forCellWithReuseIdentifier: "\(BikeStationCloseByCollectionViewCell.self)")
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        pageControl.numberOfPages = sections.count
    }

    // MARK: - Helpers
    fileprivate func closebyStations(for stations: [BikeStation]) -> [BikeStation]
    {
        let sortedStations = stations.sorted{ $0.distance(to: self.bikeStation) < $1.distance(to: self.bikeStation) }
        let closebyStations = Array(sortedStations.prefix(8))
        return closebyStations
    }
    
    fileprivate func updateChartData()
    {
        guard let stationStatuses = self.stationStatuses else { return }
        self.sections = [.detail(station: bikeStation), .graph(graphData: stationStatuses), .closeBy(stations: self.closebyStations(for: bikeStations))]
        collectionView.reloadItems(at: [IndexPath(item: 1, section: 0)])
    }
    
    fileprivate func updateSections()
    {
        sections = hasGraph ? [.detail(station: bikeStation), .graph(graphData: stationStatuses), .closeBy(stations: closebyStations)] : [.detail(station: bikeStation), .closeBy(stations: closebyStations)]
    }
    
    // MARK: - Networking
    private func fetchHistory()
    {
        guard hasGraph else { return }
        let stationsClient = StationsClient()
        stationsClient.fetchStationStatuses(with: self.bikeNetwork.id, stationID: self.bikeStation.id)
        { (response) in
            DispatchQueue.main.async
            {
                stationsClient.invalidate()
                switch response
                {
                case .error:
                    break
                case .success(let statuses):
                    self.stationStatuses = statuses
                }
            }
        }
    }
    
    @objc func fetchStations()
    {
        let stationsClient = StationsClient()
        stationsClient.fetchStations(with: self.bikeNetwork, fetchGBFSProperties: true)
        { response in
            DispatchQueue.main.async
            {
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
                    if let bikeStation = stations.first(where: { $0.id == self.bikeStation.id })
                    {
                        let index = stations.index(of: bikeStation)!
                        stations.remove(at: index)
                        self.bikeStations = stations
                        self.closebyStations = self.closebyStations(for: self.bikeStations)
                        self.bikeStation = bikeStation
                        self.updateSections()
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension BikeStationDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let section = sections[indexPath.item]
        switch section
        {
        case .detail(let station):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(BikeStationDetailCollectionViewCell.self)", for: indexPath) as! BikeStationDetailCollectionViewCell
            cell.bikeStation = station
            return cell
        case .graph(let graphData):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(BikeStationGraphCollectionViewCell.self)", for: indexPath) as! BikeStationGraphCollectionViewCell
            cell.stationStatuses = graphData
            return cell
        case .closeBy(let stations):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(BikeStationCloseByCollectionViewCell.self)", for: indexPath) as! BikeStationCloseByCollectionViewCell
            cell.closebyStations = stations
            cell.network = bikeNetwork
            cell.collectionView.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if collectionView === self.collectionView
        {
            return view.bounds.size
        }
        else
        {
            return CGSize(width: collectionView.bounds.width / 8.0, height: collectionView.bounds.height)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if (-CGFloat.greatestFiniteMagnitude ... view.bounds.width * 0.5) ~= scrollView.contentOffset.x
        {
            pageControl.currentPage = 0
        }
        else if (view.bounds.width * 0.5 ... view.bounds.width * 1.5) ~= scrollView.contentOffset.x
        {
            pageControl.currentPage = 1
        }
        else if pageControl.numberOfPages > 2
        {
            pageControl.currentPage = 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let station = closebyStations[indexPath.item]
        let stationDetailViewController = BikeStationDetailViewController(with: bikeNetwork, station: station, stations: bikeStations, hasGraph: hasGraph)
        present(stationDetailViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        guard collectionView !== self.collectionView else { return }
        if let nextIndexPath = context.nextFocusedIndexPath,
           let cell = collectionView.cellForItem(at: nextIndexPath) as? BikeStationClosebyStationCollectionViewCell
        {
            cell.containerView.layer.borderWidth = 3.0
            cell.containerView.layer.borderColor = UIColor.app_blue.cgColor
            cell.containerView.layer.cornerRadius = 8.0
        }
        else if let previousIndexPath = context.previouslyFocusedIndexPath,
                let cell = collectionView.cellForItem(at: previousIndexPath) as? BikeStationClosebyStationCollectionViewCell
        {
            cell.containerView.layer.borderWidth = 0.0
            cell.containerView.layer.borderColor = nil
        }
    }
}

// MARK: - BikeStation + BikeStationDetailViewController
fileprivate extension BikeStation
{
    func distance(to station: BikeStation) -> CLLocationDistance
    {
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let otherStationLocation = CLLocation(latitude: station.coordinates.latitude, longitude: station.coordinates.longitude)
        return stationLocation.distance(from: otherStationLocation)
    }
}
