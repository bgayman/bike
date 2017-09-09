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
    
    @objc lazy var footerView: BikeTableFooterView =
    {
        let height: CGFloat = max(BikeTableFooterView(reuseIdentifier: "thing").poweredByButton.intrinsicContentSize.height, 44.0)
        let footerView = BikeTableFooterView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height))
        return footerView
    }()
    
    @objc lazy var searchController: UISearchController =
    {
        let searchResultsController = StationDiffViewControllerSearchController()
        searchResultsController.delegate = self
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
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
        self.view.backgroundColor = UIColor.app_beige
        self.navigationItem.titleView = self.activityIndicator
        self.activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItems = [self.refreshButton]
        self.navigationItem.prompt = "Network changes since first viewing."
        self.refreshControl = refresh
        self.configureTableView()
        self.fetchStations()
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
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(BikeTableFooterView.self, forHeaderFooterViewReuseIdentifier: "thing")
        
        #if !os(tvOS)
            footerView.poweredByButton.addTarget(self, action: #selector(self.poweredByPressed), for: .touchUpInside)
            self.tableView.tableHeaderView = self.searchController.searchBar
            self.definesPresentationContext = true
            self.refreshControl = refresh
        #endif
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
                        self.tableView.tableFooterView = UIView()
                    }
                    else
                    {
                        self.tableView.tableFooterView = self.footerView
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

    @objc func poweredByPressed()
    {
        let safariVC = SFSafariViewController(url: URL(string: "https://citybik.es/#about")!)
        self.present(safariVC, animated: true)
    }
    
    //MARK: - Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return bikeStationDiffs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let diff = self.bikeStationDiffs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BikeTableViewCell
        cell.titleLabel.font = UIFont.app_font(forTextStyle: .body)
        cell.titleLabel.text = diff.bikeStation.name
        cell.subtitleLabel.font = UIFont.app_font(forTextStyle: .caption1)
        cell.accessoryType = .disclosureIndicator
        var subtitleText = [diff.statusText]
        if let _ = diff.dateComponentText
        {
            subtitleText.append(diff.bikeStation.dateComponentText)
        }
        cell.subtitleLabel.text = subtitleText.joined(separator: "\n")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "thing")
        return footer
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let diff = self.bikeStationDiffs[indexPath.row]
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
        let stationDetailViewController = StationDetailViewController(with: self.network, station: station, stations: self.bikeStations, hasGraph: HistoryNetworksManager.shared.historyNetworks.contains(self.network.id))
        return stationDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
    }
}

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

extension StationDiffViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        guard let controller = searchController.searchResultsController as? StationDiffViewControllerSearchController else { return }
        guard let text = searchController.searchBar.text else { return }
        controller.searchString = text
    }
}

extension StationDiffViewController: StationDiffViewControllerSearchControllerDelegate
{
    func didSelect(diff: BikeStationDiff)
    {
        self.delegate?.didSelectBikeStation(station: diff.bikeStation)
    }
}
