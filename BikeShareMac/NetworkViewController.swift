//
//  NetworkViewController.swift
//  BikeShare
//
//  Created by Brad G. on 1/17/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

class NetworkViewController: NSViewController
{

    enum State
    {
        case networks
        case stations
    }
    
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var tableView: NSTableView!
    
    var networks = [BikeNetwork]()
    {
        didSet
        {
            self.state = .networks
            self.tableView.deselectAll(nil)
            self.tableView.reloadData()
        }
    }
    
    var stations = [BikeStation]()
    {
        didSet
        {
            self.state = .stations
            self.tableView.deselectAll(nil)
            self.tableView.reloadData()
        }
    }
    var searchString = ""
    var state = State.networks
    {
        didSet
        {
            guard oldValue != self.state else { return }
            self.searchString = ""
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.selectionHighlightStyle = .none
    }
    
}

extension NetworkViewController: NSTableViewDelegate, NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        switch self.state
        {
        case .networks:
            return self.networks.count
        case .stations:
            return self.stations.count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        guard let cell = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as? NetworkTableCell else { return  nil }
        let attributes = cell.backgroundStyle == .dark ? [NSForegroundColorAttributeName: NSColor.white] : [NSForegroundColorAttributeName: NSColor.darkGray]
        switch self.state
        {
        case .networks:
            guard self.networks.indices ~= row else { return nil }
            let string = self.networks[row].name as NSString
            let attribString = NSMutableAttributedString(string: "\(string)", attributes: attributes)
            let range = (string.lowercased as NSString).range(of: self.searchString.lowercased())
            attribString.addAttributes([NSForegroundColorAttributeName: NSColor.app_blue], range: range)
            
            let string2 = self.networks[row].locationDisplayName as NSString
            let attribString2 = NSMutableAttributedString(string: "\(string2)", attributes: attributes)
            let range2 = (string2.lowercased as NSString).range(of: self.searchString.lowercased())
            attribString2.addAttributes([NSForegroundColorAttributeName: NSColor.app_blue], range: range2)
            
            cell.titleTextField.attributedStringValue = attribString
            cell.subtitleTextField.attributedStringValue = attribString2
            return cell
        case .stations:
            guard self.stations.indices ~= row else { return nil }
            let station = self.stations[row]
            let string = station.name as NSString
            let attribString = NSMutableAttributedString(string: "\(string)", attributes: attributes)
            let range = (string.lowercased as NSString).range(of: self.searchString.lowercased())
            attribString.addAttributes([NSForegroundColorAttributeName: NSColor.app_blue], range: range)
            
            let string2 = "\(station.statusDisplayText)\n\(station.dateComponentText)\n\(station.distanceDescription)"
            let attribString2 = NSMutableAttributedString(string: string2, attributes: attributes)
            
            cell.titleTextField.attributedStringValue = attribString
            cell.subtitleTextField.attributedStringValue = attribString2
            return cell
        }
        
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        switch self.state {
        case .networks:
            return 65.0
        case .stations:
            return 100.0
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        switch self.state
        {
        case .networks:
            guard let mapViewController = self.parent as? MapViewController,
                self.tableView.selectedRow != -1
                else { return }
            let network = self.networks[self.tableView.selectedRow]
            self.networks = []
            mapViewController.network = network
            mapViewController.fetchStations()
        case .stations:
            guard let mapViewController = self.parent as? MapViewController,
                self.tableView.selectedRow != -1
                else { return }
            let station = self.stations[self.tableView.selectedRow]
            mapViewController.focus(on: [station])
        }
    }
}

extension NetworkViewController: MapViewControllerDelegate
{
    func didRequestCallout(forMapBikeNetwork: MapBikeNetwork)
    {
        guard let index = self.networks.index(of: forMapBikeNetwork.bikeNetwork) else { return }
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.allowsImplicitAnimation = true
            self.tableView.scrollRowToVisible(index)
        }, completionHandler: nil)
    }
    
    func didRequestCallout(forMapBikeStation: MapBikeStation)
    {
        guard let index = self.stations.index(of: forMapBikeStation.bikeStation) else { return }
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.allowsImplicitAnimation = true
            self.tableView.scrollRowToVisible(index)
        }, completionHandler: nil)
    }
}
