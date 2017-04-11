//
//  NetworkInformationViewController.swift
//  BikeShare
//
//  Created by Brad G. on 2/25/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

class NetworkInformationViewController: NSViewController
{
    var network: BikeNetwork? = nil
    var feeds: [GBFSFeed]? = nil
    var stations: [GBFSStationInformation]?
    
    var dataSource = [SystemInfoTableViewContent]()
    {
        didSet
        {
            self.activityIndicator.stopAnimation(nil)
            self.tableView.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.selectionHighlightStyle = .none
        self.fetchFeeds()
    }
    
    func fetchFeeds()
    {
        self.activityIndicator.startAnimation(nil)
        var gbfsFeedsClient = GBFSFeedClient()
        gbfsFeedsClient.fetchGBFFeeds(with: self.network?.gbfsHref)
        { (response) in
            DispatchQueue.main.async
            {
                switch response
                {
                case .error(let errorMessage):
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = errorMessage
                    alert.runModal()
                case .success(let feeds):
                    self.feeds = feeds
                    self.fetchSystemInfo()
                }
                gbfsFeedsClient.invalidate()
            }
        }
    }
    
    func fetchSystemInfo()
    {
        let systemInfoFeed = self.feeds?.filter { $0.name == "system_information" }.first
        guard systemInfoFeed != nil else { return }
        var gbfsSystemInformationClient = GBFSSystemInformationClient()
        gbfsSystemInformationClient.fetchGBFSSystemInformation(with: systemInfoFeed!.url)
        { [weak self] (response) in
            DispatchQueue.main.async
            {
                switch response
                {
                case .error(let errorMessage):
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = errorMessage
                    alert.runModal()
                case .success(let systemInfo):
                    let content = SystemInfoTableViewContent.content(for: systemInfo)
                    let systemPricingFeed = self?.feeds?.filter { $0.name == "system_pricing_plans" }.first
                    self?.fetchSystemPricing(feed: systemPricingFeed, content: content)
                }
                gbfsSystemInformationClient.invalidate()
            }
        }
    }
    
    func fetchSystemPricing(feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
            feed.name == "system_pricing_plans" else
        {
            let alertFeed = self.feeds?.filter { $0.name == "system_alerts" }.first
            self.fetchSystemAlerts(with: alertFeed, content: content)
            return
        }
        var gbfsSystemPricingPlanClient = GBFSSystemPricingPlanClient()
        gbfsSystemPricingPlanClient.fetchGBFSPricingPlans(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                if case .success(let plans) = response
                {
                    var newContent = content
                    for plan in plans
                    {
                        newContent += SystemInfoTableViewContent.content(for: plan)
                    }
                    let alertFeed = self.feeds?.filter { $0.name == "system_alerts" }.first
                    self.fetchSystemAlerts(with: alertFeed, content: newContent)
                }
            }
        }
    }
    
    func fetchSystemAlerts(with feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
            feed.name == "system_alerts" else
        {
            self.dataSource += content
            return
        }
        var gbfsSystemAlertsClient = GBFSSystemAlertClient()
        gbfsSystemAlertsClient.fetchGBFSAlerts(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                if case .success(let alerts) = response
                {
                    let newContent = content + alerts.map { SystemInfoTableViewContent.alert(alert: $0) }
                    let stationsFeed = self.feeds?.filter{ $0.name == "station_information" }.first
                    self.fetchStationInformation(feed: stationsFeed, content: newContent)
                }
            }
            gbfsSystemAlertsClient.invalidate()
        }
    }
    
    func fetchStationInformation(feed: GBFSFeed?, content: [SystemInfoTableViewContent])
    {
        guard let feed = feed,
            feed.name == "station_information" else
        {
            self.dataSource += content
            return
        }
        var stationsClient = GBFSStationsInformationClient()
        stationsClient.fetchGBFSStations(with: feed.url)
        { (response) in
            DispatchQueue.main.async
            {
                if case .success(let stations) = response
                {
                    self.stations = stations
                    self.dataSource += content
                }
            }
            stationsClient.invalidate()
        }
    }
}

extension NetworkInformationViewController: NSTableViewDelegate, NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        guard let cell = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as? InfoTableCellView else { return  nil }
        let content = self.dataSource[row]
        switch content
        {
        case .name(let name):
            cell.titleTextField.stringValue = "Name:"
            cell.subtitleTextField.stringValue = name
        case .shortName(let shortName):
            cell.titleTextField.stringValue = "Short Name:"
            cell.subtitleTextField.stringValue = shortName
        case .operator(let op):
            cell.titleTextField.stringValue = "Operator:"
            cell.subtitleTextField.stringValue = op
        case .url(let url):
            cell.titleTextField.stringValue = "Website:"
            cell.subtitleTextField.stringValue = url.absoluteString
            if url.absoluteString.contains("https:")
            {
                cell.subtitleTextField.textColor = NSColor.app_blue
            }
        case .purchaseURL(let url):
            cell.titleTextField.stringValue = "Signup Website:"
            cell.subtitleTextField.stringValue = url.absoluteString
            if url.absoluteString.contains("https:")
            {
                cell.subtitleTextField.textColor = NSColor.app_blue
            }
        case .stateDate(let date):
            cell.titleTextField.stringValue = "Start Date:"
            cell.subtitleTextField.stringValue = SystemInfoTableViewContent.dateFormatter.string(from: date)
        case .phoneNumber(let phoneNumber):
            cell.titleTextField.stringValue = "Phone Number:"
            cell.subtitleTextField.stringValue = phoneNumber
            cell.subtitleTextField.textColor = NSColor.app_blue
            
        case .email(let email):
            cell.titleTextField.stringValue = "Email:"
            cell.subtitleTextField.stringValue = email
            cell.subtitleTextField.textColor = NSColor.app_blue
        case .licenseURL(let url):
            cell.titleTextField.stringValue = "License Website:"
            cell.subtitleTextField.stringValue = url.absoluteString
            if url.absoluteString.contains("https:")
            {
                cell.subtitleTextField.textColor = NSColor.app_blue
            }
        case .timeZone(let timeZone):
            cell.titleTextField.stringValue = "Time Zone:"
            cell.subtitleTextField.stringValue = timeZone
        case .pricingPlan(let plan):
            SystemInfoTableViewContent.numberFormatter.currencyCode = plan.currency
            cell.titleTextField.stringValue = SystemInfoTableViewContent.numberFormatter.string(from: NSNumber(value: plan.price)) ?? plan.name
            cell.subtitleTextField.stringValue = plan.description.isEmpty ? plan.name : plan.description
        case.alert(let alert):
            cell.titleTextField.stringValue = alert.summary
            var string = alert.description ?? ""
            alert.stationIDs?.forEach
            { stationID in
                let filteredStations = self.stations?.filter{ $0.stationID == stationID }
                if let station = filteredStations?.first
                {
                    string += "\n\(station.name)"
                }
            }
            cell.subtitleTextField.stringValue = string
            break
        }

        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        let content = self.dataSource[row]
        switch content
        {
        case .alert:
            return 150
        case .pricingPlan:
            return 75
        default:
            return 75
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        guard self.tableView.selectedRow != -1 else { return }
        let content = self.dataSource[self.tableView.selectedRow]
        switch content
        {
        case .name:
            break
        case .shortName:
            break
        case .operator:
            break
        case .url(let url):
            if url.absoluteString.contains("https:")
            {
                NSWorkspace.shared().open(url)
            }
        case .purchaseURL(let url):
            if url.absoluteString.contains("https:")
            {
                NSWorkspace.shared().open(url)
            }
        case .stateDate:
            break
        case .phoneNumber(let phoneNumber):
            guard let url = URL(string: "tel:\(phoneNumber)") else { return }
            NSWorkspace.shared().open(url)
        case .email(let email):
            guard let url = URL(string: "mailto:\(email)") else { return }
            NSWorkspace.shared().open(url)
        case .licenseURL(let url):
            if url.absoluteString.contains("https:")
            {
                NSWorkspace.shared().open(url)
            }
        case .timeZone:
            break
        case .pricingPlan:
            break
        case.alert:
            break
        }
    }
}
