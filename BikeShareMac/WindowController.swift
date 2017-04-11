//
//  WindowController.swift
//  BikeShare
//
//  Created by Brad G. on 1/16/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

//MARK: - WindowController
class WindowController: NSWindowController
{

    //MARK: - Type
    enum State
    {
        case networks
        case stations
    }
    
    //MARK: - Properties
    var bikeNetwork: BikeNetwork?
    {
        didSet
        {
            self.stationsButton.isEnabled = self.bikeNetwork != nil
            self.stationsButton.state = (self.bikeNetwork != nil && self.networkViewController != nil) ? 1 : 0
            self.networksButton.state = (self.bikeNetwork == nil && self.networkViewController != nil) ? 1 : 0
            self.searchField.placeholderString = self.bikeNetwork == nil ? "Search Networks" : "Search Stations"
            self.searchField.stringValue = ""
            self.promptLabel.stringValue = ""
            self.searchField.resignFirstResponder()
            self.infoButton.isEnabled = self.bikeNetwork?.gbfsHref != nil
        }
    }
    
    var allNetworks = [BikeNetwork]()
    {
        didSet
        {
            self.networkViewController?.networks = self.allNetworks
            if let deeplink = self.deeplink
            {
                switch deeplink
                {
                case .network(let networkID):
                    self.mapViewController?.network = self.allNetworks.filter{ $0.id == networkID }.first
                    self.mapViewController?.fetchStations()
                    self.deeplink = nil
                case .station(let networkID, _):
                    self.mapViewController?.network = self.allNetworks.filter{ $0.id == networkID }.first
                    self.mapViewController?.fetchStations()
                case .systemInfo(let networkID):
                    self.mapViewController?.network = self.allNetworks.filter{ $0.id == networkID }.first
                    self.mapViewController?.fetchStations()
                    self.didPressInfoButton(self.infoButton)
                    self.deeplink = nil
                }
            }
        }
    }
    
    var allStations = [BikeStation]()
    {
        didSet
        {
            self.networkViewController?.stations = self.allStations
            if let deeplink = self.deeplink
            {
                switch deeplink
                {
                case .network(_):
                    break
                case .station(_, let stationID):
                    let station = self.allStations.filter{ $0.id == stationID }.first
                    if station != nil
                    {
                        self.mapViewController?.focus(on: [station!])
                    }
                    self.deeplink = nil
                case .systemInfo:
                    break
                }
            }
        }
    }
    
    var networkSearchResults = [BikeNetwork]()
    {
        didSet
        {
            self.networkViewController?.searchString = self.searchString
            self.networkViewController?.networks = self.networkSearchResults
        }
    }
    var stationSearchResults = [BikeStation]()
    {
        didSet
        {
            self.networkViewController?.searchString = self.searchString
            self.networkViewController?.stations = self.stationSearchResults
        }
    }
    var networkViewController: NetworkViewController?
    var deeplink: Deeplink?
    fileprivate var popover: NSPopover?
    
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var stationsButton: NSButton!
    @IBOutlet weak var promptLabel: NSTextField!
    @IBOutlet weak var networksButton: NSButton!
    @IBOutlet weak var infoButton: NSButton!
    
    //MARK: - Computed Properties
    var state: State
    {
        return self.bikeNetwork == nil ? .networks : .stations
    }
    
    var searchString = ""
    {
        didSet
        {
            switch self.state
            {
            case .networks:
                self.networkSearchResults = self.allNetworks.filter
                { network in
                    return network.name.lowercased().contains(self.searchString.lowercased()) || network.locationDisplayName.lowercased().contains(self.searchString.lowercased())
                }
            case .stations:
                self.stationSearchResults = self.allStations.filter
                { station in
                    return station.name.lowercased().contains(self.searchString.lowercased())
                }
            }
        }
    }
    
    var mapViewController: MapViewController?
    {
        return self.contentViewController as? MapViewController
    }
    
    //MARK: - Lifecycle
    override func windowDidLoad()
    {
        super.windowDidLoad()
        self.window?.titleVisibility = .hidden
        self.promptLabel.stringValue = ""
        self.bikeNetwork = self.mapViewController?.network
    }

    //MARK: - Actions
    @IBAction func searchChanged(_ sender: NSSearchField)
    {
        guard !sender.stringValue.isEmpty else
        {
            self.networkViewController?.searchString = ""
            switch self.state
            {
            case .networks:
                self.mapViewController?.networks = self.allNetworks
                self.networkViewController?.networks = self.allNetworks
            case .stations:
                self.mapViewController?.stations = self.allStations
                self.networkViewController?.stations = self.allStations
            }
            return
        }
        self.searchString = sender.stringValue
        switch  self.state
        {
        case .networks:
            self.mapViewController?.networks = self.networkSearchResults
        case .stations:
            self.mapViewController?.stations = self.stationSearchResults
        }
    }
    
    @IBAction func didClickStations(_ sender: NSButton)
    {
        guard self.networkViewController == nil
            else
        {
            self.networkViewController?.view.removeFromSuperview()
            self.networkViewController?.removeFromParentViewController()
            self.networkViewController = nil
            return
        }
        self.addNetworkViewController()
        if !self.searchString.isEmpty
        {
            self.networkViewController?.stations = self.stationSearchResults
        }
        else
        {
            self.networkViewController?.stations = self.allStations
            self.mapViewController?.fetchStations()
        }
    }
    
    @IBAction func didClickNetworks(_ sender: NSButton)
    {
        
        self.mapViewController?.network = nil
        
        guard self.networkViewController == nil || self.state != .networks
        else
        {
            self.networkViewController?.view.removeFromSuperview()
            self.networkViewController?.removeFromParentViewController()
            self.networkViewController = nil
            return
        }

        if self.networkViewController == nil
        {
            self.addNetworkViewController()
            self.networkViewController?.networks = self.allNetworks
        }
        if self.state != .networks
        {
            self.networkViewController?.networks = self.allNetworks
            self.mapViewController?.networks = UserDefaults.bikeShareGroup.networks ?? []
            self.mapViewController?.fetchNetworks()
        }
        self.bikeNetwork = nil
        if !self.searchString.isEmpty
        {
            self.networkViewController?.networks = self.networkSearchResults
        }
        
    }
    
    func addNetworkViewController()
    {
        guard let mapViewController = self.mapViewController else { return }
        
        self.networkViewController = self.storyboard?.instantiateController(withIdentifier: "\(NetworkViewController.self)") as? NetworkViewController
        self.mapViewController?.view.addSubview(self.networkViewController!.view)
        self.mapViewController?.addChildViewController(self.networkViewController!)
        self.networkViewController!.view.wantsLayer = true
        self.networkViewController!.view.layer?.backgroundColor = NSColor.clear.cgColor
        self.networkViewController?.view.layer?.masksToBounds = true
        self.networkViewController?.view.layer?.cornerRadius = 8.0
        self.networkViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        self.networkViewController?.view.topAnchor.constraint(equalTo: mapViewController.view.topAnchor, constant: 60.0).isActive = true
        self.mapViewController?.delegate = self.networkViewController
        self.networkViewController?.view.leadingAnchor.constraint(equalTo: mapViewController.view.leadingAnchor, constant: 20.0).isActive = true
        self.networkViewController?.view.bottomAnchor.constraint(equalTo: mapViewController.view.bottomAnchor, constant: -20.0).isActive = true
        self.networkViewController?.view.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
    }
    
    @IBAction func didChangeSegmentedControl(_ sender: NSSegmentedControl)
    {
        switch sender.label(forSegment: sender.selectedSegment) ?? ""
        {
        case "Map":
            self.mapViewController?.mapView.mapType = .standard
        case "Hybrid":
            self.mapViewController?.mapView.mapType = .hybrid
        case "Satellite":
            self.mapViewController?.mapView.mapType = .satellite
        case "Flyover":
            self.mapViewController?.mapView.mapType = .hybridFlyover
        default:
            break
        }
    }
    
    @IBAction func didPressInfoButton(_ sender: NSButton)
    {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let infoVC = storyboard.instantiateController(withIdentifier: "\(NetworkInformationViewController.self)") as? NetworkInformationViewController else { return }
        infoVC.network = self.bikeNetwork
        infoVC.view.wantsLayer = true
        let popoverView = NSPopover()
        popoverView.contentViewController = infoVC
        popoverView.behavior = .transient
        popoverView.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        self.popover = popoverView
    }
    
    //MARK: - Deeplink
    func handle(deeplink: Deeplink)
    {
        self.deeplink = deeplink
        switch deeplink
        {
        case .network:
            self.mapViewController?.fetchNetworks()
        case .station(let networkID, _):
            if networkID != self.bikeNetwork?.id
            {
                self.mapViewController?.fetchNetworks()
            }
            else
            {
                self.mapViewController?.fetchStations()
            }
        case .systemInfo:
            self.mapViewController?.fetchNetworks()
        }
    }
}

//MARK: - NSSearchFieldDelegate
extension WindowController: NSSearchFieldDelegate
{
    func searchFieldDidEndSearching(_ sender: NSSearchField)
    {
        guard let mapViewController = self.contentViewController as? MapViewController else { return }
        self.networkViewController?.searchString = ""
        switch self.state
        {
        case .networks:
            mapViewController.networks = self.allNetworks
            self.networkViewController?.networks = self.allNetworks
        case .stations:
            mapViewController.stations = self.allStations
            self.networkViewController?.stations = self.allStations
        }
    }
}
