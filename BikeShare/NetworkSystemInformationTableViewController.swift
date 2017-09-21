//
//  NetworkSystemInformationTableViewController.swift
//  BikeShare
//
//  Created by Brad G. on 2/11/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
#if os(iOS)
import MessageUI
import SafariServices
#endif
import MapKit

class NetworkSystemInformationTableViewController: UITableViewController
{
    let network: BikeNetwork
    let feeds: [GBFSFeed]
    var stations: [GBFSStationInformation]?
    
    var dataSource = [SystemInfoTableViewContent]()
    {
        didSet
        {
            self.animateUpdate(with: oldValue, newDataSource: self.dataSource)
            self.navigationItem.titleView = nil
            self.navigationItem.title = self.network.name
        }
    }
    
    @objc lazy var doneButton: UIBarButtonItem =
    {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone(sender:)))
        return doneButton
    }()
    
    @objc lazy var actionButton: UIBarButtonItem =
    {
        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.didPressAction(sender:)))
        return actionButton
    }()
    
    @objc lazy var mapView: MKMapView =
    {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(self.annotation)
        mapView.delegate = self
        mapView.centerCoordinate = self.annotation.coordinate
        return mapView
    }()
    
    @objc var annotation: MapBikeNetwork
    {
        return MapBikeNetwork(bikeNetwork: self.network)
    }
    
    @objc var mapHeight: CGFloat
    {
        return self.view.bounds.height * 0.3
    }
    
    init?(network: BikeNetwork, feeds: [GBFSFeed]?)
    {
        guard network.gbfsHref != nil,
              let feeds = feeds
        else { return nil }
        self.network = network
        self.feeds = feeds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder use `init(network:)`")
    }
    
    deinit
    {
        mapView.delegate = nil
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = .app_beige
        #if !os(tvOS)
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.navigationItem.titleView = activityIndicator
        activityIndicator.startAnimating()
        self.navigationItem.largeTitleDisplayMode = .never
        #endif
        self.navigationItem.rightBarButtonItem = self.doneButton
        self.navigationItem.leftBarButtonItem = self.actionButton
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.tableHeaderView = self.mapView
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "\(PricingPlanTableViewCell.self)", bundle: nil), forCellReuseIdentifier: "\(PricingPlanTableViewCell.self)")
        self.fetchSystemInfo()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.mapHeight)
    }
    
    @objc func fetchSystemInfo()
    {
        let systemInfoFeed = self.feeds.filter { $0.type == .systemInformation }.first
        guard systemInfoFeed != nil else { return }
        #if !os(tvOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        var gbfsSystemInformationClient = GBFSSystemInformationClient()
        gbfsSystemInformationClient.fetchGBFSSystemInformation(with: systemInfoFeed!.url)
        { [weak self] (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
                switch response
                {
                case .error(let errorMessage):
                    self?.present(UIAlertController(errorMessage: errorMessage), animated: true)
                case .success(let systemInfo):
                    let content = SystemInfoTableViewContent.content(for: systemInfo)
                    let systemPricingFeed = self?.feeds.filter { $0.name == "system_pricing_plans" }.first
                    self?.fetchSystemPricing(feed: systemPricingFeed, content: content)
                }
                gbfsSystemInformationClient.invalidate()
            }
        }
    }
    
    func fetchSystemPricing(feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
              feed.type == .systemPricingPlans else
        {
            let alertFeed = self.feeds.filter { $0.type == .systemAlerts }.first
            self.fetchSystemAlerts(with: alertFeed, content: content)
            return
        }
        #if !os(tvOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        var gbfsSystemPricingPlanClient = GBFSSystemPricingPlanClient()
        gbfsSystemPricingPlanClient.fetchGBFSPricingPlans(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
                if case .success(let plans) = response
                {
                    var newContent = content
                    for plan in plans
                    {
                        newContent += SystemInfoTableViewContent.content(for: plan)
                    }
                    let alertFeed = self.feeds.filter { $0.name == "system_alerts" }.first
                    self.fetchSystemAlerts(with: alertFeed, content: newContent)
                }
            }
        }
    }
    
    func fetchSystemAlerts(with feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
              feed.type == .systemAlerts else
        {
            self.dataSource += content
            return
        }
        #if !os(tvOS)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        var gbfsSystemAlertsClient = GBFSSystemAlertClient()
        gbfsSystemAlertsClient.fetchGBFSAlerts(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
                if case .success(let alerts) = response
                {
                    let newContent = content + alerts.map { SystemInfoTableViewContent.alert(alert: $0) }
                    let stationsFeed = self.feeds.filter{ $0.name == "station_information" }.first
                    self.fetchStationInformation(feed: stationsFeed, content: newContent)
                }
            }
            gbfsSystemAlertsClient.invalidate()
        }
    }
    
    func fetchStationInformation(feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
            feed.type == .stationInformation else
        {
            self.dataSource += content
            return
        }
        #if !os(tvOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        var stationsClient = GBFSStationsInformationClient()
        stationsClient.fetchGBFSStations(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                #if !os(tvOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
                if case .success(let stations) = response
                {
                    self.stations = stations
                    self.dataSource += content
                }
            }
            stationsClient.invalidate()
        }
    }
    
    @objc func didPressDone(sender: UIBarButtonItem)
    {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @objc func didPressAction(sender: UIBarButtonItem)
    {
        guard let url = URL(string: Constants.WebSiteDomain + "/systemInfo/" + self.network.id) else { return }
        #if !os(tvOS)
            
        let customActivity = ActivityViewCustomActivity.networkFavoriteActivity(with: self.network)

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [customActivity])
        if let popover = activityViewController.popoverPresentationController
        {
            popover.barButtonItem = self.actionButton
        }
        self.present(activityViewController, animated: true)
        #endif
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let content = self.dataSource[indexPath.row]
        let unwrappedCell: UITableViewCell
        if case .pricingPlan(let plan) = content
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(PricingPlanTableViewCell.self)", for: indexPath) as! PricingPlanTableViewCell
            cell.pricingPlan = plan
            unwrappedCell = cell as UITableViewCell
        }
        else if case .alert(var alert) = content
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(PricingPlanTableViewCell.self)", for: indexPath) as! PricingPlanTableViewCell
            
            if let stationIDs = alert.stationIDs
            {
                alert.stations = self.stations?.filter { stationIDs.contains($0.stationID) }
            }
            cell.alert = alert
            unwrappedCell = cell as UITableViewCell
        }
        else
        {
            var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
            if cell == nil
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
            }
            unwrappedCell = cell!
            content.configure(cell: unwrappedCell)
            
        }
        return unwrappedCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let content = self.dataSource[indexPath.row]
        switch content
        {
        case .name, .shortName, .operator, .stateDate, .timeZone:
            break
        case .email(let email):
            #if !os(tvOS)
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients([email])
            self.present(composeVC, animated: true)
            #else
            break
            #endif
        case .phoneNumber(let phoneNumber):
            tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
            let number = phoneNumber.replacingOccurrences(of: "-", with: "")
            guard let url = URL(string: "tel://" + number) else { return }
            UIApplication.shared.open(url, options: [:])
        case .url(let url), .licenseURL(let url), .purchaseURL(let url):
            #if !os(tvOS)
            let safariVC = SFSafariViewController(url: url)
            self.present(safariVC, animated: true)
            #else
                break
            #endif
        case .pricingPlan(let plan):
            guard let url = plan.url else { return }
            #if !os(tvOS)
                let safariVC = SFSafariViewController(url: url)
                self.present(safariVC, animated: true)
            #else
                break
            #endif
        case .alert(let alert):
            guard let url = alert.url else { return }
            #if !os(tvOS)
                let safariVC = SFSafariViewController(url: url)
                self.present(safariVC, animated: true)
            #else
                break
            #endif
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        let cell = tableView.cellForRow(at: indexPath)
        return cell?.accessoryType ?? .none == .disclosureIndicator ? indexPath : nil
    }

}

extension NetworkSystemInformationTableViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let identifier = "Bike"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil
        {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        annotationView?.markerTintColor = UIColor.app_blue
        annotationView?.canShowCallout = true
        return annotationView
    }
}

extension NetworkSystemInformationTableViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if self.tableView.contentOffset.y <= 0.0
        {
            return true
        }
        return false
    }
}

#if os(iOS)
extension NetworkSystemInformationTableViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        self.dismiss(animated: true)
    }
}
#endif

