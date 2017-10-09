//
//  StationDiffViewController.swift
//  BikeShare
//
//  Created by Brad G. on 3/18/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import SafariServices
import DZNEmptyDataSet

protocol StationDiffViewControllerDelegate: class
{
    func didUpdateBikeStations(stations: [BikeStation])
    func didUpdateBikeStationDiffs(bikeStationDiffs: [BikeStationDiff])
    func didSelectBikeStation(station: BikeStation)
    func searchBarDidBecomeActive()
}

class StationDiffViewController: UITableViewController
{
    //MARK: - Properties
    let network: BikeNetwork
    var bikeStations: [BikeStation]
    
    weak var delegate: StationDiffViewControllerDelegate?
    
    var bikeStationDiffs: [BikeStationDiff]
    {
        didSet
        {
            self.tableView.reloadData()
            if let searchResultsController = searchController.searchResultsController as? StationDiffViewControllerSearchController
            {
                searchResultsController.all = bikeStationDiffs
            }
        }
    }
    
    @objc lazy var refresh: UIRefreshControl =
    {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.fetchStations), for: .valueChanged)
        return refresh
    }()
    
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
    
    @objc lazy var searchController: UISearchController =
    {
        let searchResultsController = StationDiffViewControllerSearchController()
        searchResultsController.delegate = self
        searchResultsController.network = self.network
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    //MARK: - Lifecycle
    init(bikeNetwork: BikeNetwork, bikeStations: [BikeStation], bikeStationDiffs: [BikeStationDiff])
    {
        self.bikeStations = bikeStations
        self.network = bikeNetwork
        self.bikeStationDiffs = bikeStationDiffs.sorted()
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.title = "Station Differences"
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.configureTableView()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if self.traitCollection.forceTouchCapability == .available
        {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    private func configureTableView()
    {
        self.tableView.estimatedRowHeight = 55.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        let nib = UINib(nibName: "\(StationDiffTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")
        self.definesPresentationContext = true
        self.refreshControl = refresh
        self.tableView.dragDelegate = self
        self.tableView.dragInteractionEnabled = true
        self.tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
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
                    self.refreshControl?.endRefreshing()
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
                    if diffs.isEmpty
                    {
                        self.tableView.emptyDataSetDelegate = self
                        self.tableView.emptyDataSetSource = self
                        let footerView = UIView()
                        footerView.backgroundColor = .clear
                        self.tableView.tableFooterView = footerView
                    }
                    self.bikeStationDiffs = diffs.sorted()
                    if let diffSearchController = self.searchController.searchResultsController as? StationDiffViewControllerSearchController
                    {
                        diffSearchController.all = self.bikeStationDiffs
                    }
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
    
    //MARK: - Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return bikeStationDiffs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let diff = self.bikeStationDiffs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDiffTableViewCell
        cell.bikeStationDiff = diff
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let diff = bikeStationDiffs[indexPath.row]
        self.delegate?.didSelectBikeStation(station: diff.bikeStation)
    }
}

//MARK: - UIViewControllerPreviewingDelegate
extension StationDiffViewController: UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        let station = self.bikeStationDiffs[indexPath.row].bikeStation
        let stationDetailViewController = BikeStationDetailViewController(with: self.network, station: station, stations: self.bikeStations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        return stationDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

// MARK: - DZNEmptyDataSetSource / DZNEmptyDataSetDelegate
extension StationDiffViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let title = NSAttributedString(string: "No Changes", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title2), NSAttributedStringKey.foregroundColor: UIColor.gray])
        return title
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let description = NSAttributedString(string: "No changes have been logged. Try reloading in a few moments.", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .subheadline), NSAttributedStringKey.foregroundColor: UIColor.lightGray])
        return description
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!
    {
        return #imageLiteral(resourceName: "seatedBear")
    }
}

// MARK: - UISearchResultsUpdating
extension StationDiffViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        guard let controller = searchController.searchResultsController as? StationDiffViewControllerSearchController else { return }
        guard let text = searchController.searchBar.text else { return }
        controller.searchString = text
    }
}

// MARK: - UISearchBarDelegate
extension StationDiffViewController: UISearchBarDelegate
{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        delegate?.searchBarDidBecomeActive()
    }
}

// MARK: - StationDiffViewControllerSearchControllerDelegate
extension StationDiffViewController: StationDiffViewControllerSearchControllerDelegate
{
    func didSelect(diff: BikeStationDiff)
    {
        self.delegate?.didSelectBikeStation(station: diff.bikeStation)
    }
}

// MARK: - UITableViewDragDelegate
extension StationDiffViewController: UITableViewDragDelegate
{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
    {
        let diff = self.bikeStationDiffs[indexPath.row]
        guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(self.network.id)/station/\(diff.bikeStation.id)") else { return [] }
        let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
        return [dragURLItem]
    }
}
