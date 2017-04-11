//
//  MapViewController+macOS.swift
//  BikeShare
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import AppKit
import MapKit

extension MapViewController
{
    
    var buttonAttributes: [String: Any]
    {
        return [NSFontAttributeName: NSFont.app_font(size: 12), NSForegroundColorAttributeName: NSColor.app_blue]
    }
    
    //MARK: - Networking
    @objc func fetchNetworks()
    {
        var networkClient = NetworksClient()
        self.activityIndicator.startAnimation(nil)
        if let windowController = self.view.window?.windowController as? WindowController
        {
            windowController.networkViewController?.activityIndicator.startAnimation(nil)
        }
        networkClient.fetchNetworks
        { [weak self] response in
            DispatchQueue.main.async
            {
                self?.activityIndicator.stopAnimation(nil)
                switch response
                {
                case .error(let errorMessage):
                    let alert = NSAlert()
                    alert.messageText = "🙈"
                    alert.informativeText = errorMessage
                    alert.runModal()
                    if let windowController = self?.view.window?.windowController as? WindowController
                    {
                        windowController.networkViewController?.activityIndicator.stopAnimation(nil)
                    }
                case .success(let networks):
                    self?.updateNetworksData(networks: networks)
                }
                networkClient.invalidate()
            }
        }
    }
    
    func updateNetworksData(networks: [BikeNetwork])
    {
        guard self.userManager.currentLocation != nil else
        {
            self.networks = networks
            UserDefaults.bikeShareGroup.setNetworks(networks: networks)
            guard let windowController = self.view.window?.windowController as? WindowController else { return }
            windowController.allNetworks = networks
            windowController.networkViewController?.activityIndicator.stopAnimation(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async
        { [weak self] in
            let sortedNetworks = networks.sorted { $0.0.location.distance < $0.1.location.distance }
            DispatchQueue.main.async
            {
                self?.networks = sortedNetworks
                UserDefaults.bikeShareGroup.setNetworks(networks: sortedNetworks)
                guard let windowController = self?.view.window?.windowController as? WindowController else { return }
                windowController.allNetworks = sortedNetworks
                windowController.networkViewController?.activityIndicator.stopAnimation(nil)
            }
        }
    }
    
    @objc func fetchStations()
    {
        guard let network = self.network else { return }
        let stationsClient = StationsClient()
        self.activityIndicator.startAnimation(nil)
        if let windowController = self.view.window?.windowController as? WindowController
        {
            windowController.networkViewController?.activityIndicator.startAnimation(nil)
        }
        stationsClient.fetchStations(with: network, fetchGBFSProperties: true)
        { [weak self] response in
            DispatchQueue.main.async
            {
                switch response
                {
                case .error(let errorMessage):
                    let alert = NSAlert()
                    alert.messageText = "🙈"
                    alert.informativeText = errorMessage
                    alert.runModal()
                    if let windowController = self?.view.window?.windowController as? WindowController
                    {
                        windowController.networkViewController?.activityIndicator.stopAnimation(nil)
                    }
                case .success(let stations):
                    guard !stations.isEmpty else
                    {
                        let alert = NSAlert()
                        alert.messageText = "🙈"
                        alert.informativeText = "Uh oh, looks like there are no stations for this network.\n\nThis might be for seasonal reasons or this network might no longer exist 😢."
                        alert.runModal()
                        return
                    }
                    if self?.network?.gbfsHref != nil
                    {
                        self?.fetchGBFSInfo(with: stations)
                    }
                    else
                    {
                        self?.updateStationsData(stations: stations)
                    }
                }
            }
        }
    }
    
    func fetchGBFSInfo(with stations: [BikeStation])
    {
        var gbfsFeedClient = GBFSFeedClient()
        gbfsFeedClient.fetchGBFFeeds(with: self.network?.gbfsHref)
        { (response) in
            guard case .success(let feeds) = response else
            {
                DispatchQueue.main.async
                {
                    self.updateStationsData(stations: stations)
                }
                return
            }
            gbfsFeedClient.invalidate()
            self.fetchStationInfo(with: feeds, stations: stations)
        }
    }
    
    func fetchStationInfo(with feeds: [GBFSFeed], stations: [BikeStation])
    {
        let stationFeed = feeds.filter { $0.name == "station_information" }
        guard let stationInfoFeed = stationFeed.first else
        {
            DispatchQueue.main.async
            {
                self.updateStationsData(stations: stations)
            }
            return
        }
        var gbfsStationInformationClient = GBFSStationsInformationClient()
        gbfsStationInformationClient.fetchGBFSStations(with: stationInfoFeed.url)
        { (response) in
            guard case .success(let stationsInformation) = response else
            {
                DispatchQueue.main.async
                {
                    self.updateStationsData(stations: stations)
                }
                return
            }
            let stationsDict: [String: GBFSStationInformation] = stationsInformation.reduce([String: GBFSStationInformation]())
            { (result, stationInformation) in
                var result = result
                result[stationInformation.stationID] = stationInformation
                return result
            }
            self.fetchStationStatus(with: feeds, stationsDict: stationsDict, stations: stations)
            gbfsStationInformationClient.invalidate()
        }
    }
    
    func fetchStationStatus(with feeds: [GBFSFeed], stationsDict: [String: GBFSStationInformation], stations: [BikeStation])
    {
        var stationsDict = stationsDict
        let stationFeed = feeds.filter { $0.name == "station_status" }
        guard let stationStatusFeed = stationFeed.first else
        {
            DispatchQueue.main.async
            {
                self.updateStationsData(stations: stations)
            }
            return
        }
        var gbfsStationStatusClient = GBFSStationsStatusClient()
        gbfsStationStatusClient.fetchGBFSStationStatuses(with: stationStatusFeed.url)
        { (response) in
            DispatchQueue.main.async
            {
                guard case .success(let stationsStatuses) = response else
                {
                    self.updateStationsData(stations: stations)
                    return
                }
                for stationStatus in stationsStatuses
                {
                    stationsDict[stationStatus.stationID]?.stationStatus = stationStatus
                }
                var newStationsDict = [String: GBFSStationInformation]()
                for (_, value) in stationsDict
                {
                    newStationsDict[value.name] = value
                }
                let newStations: [BikeStation] = stations.map
                    {
                        var station = $0
                        station.gbfsStationInformation = newStationsDict[station.name]
                        return station
                }
                self.updateStationsData(stations: newStations)
            }
            gbfsStationStatusClient.invalidate()
        }
    }

    
    func updateStationsData(stations: [ BikeStation])
    {
        self.activityIndicator.stopAnimation(nil)
        guard self.userManager.currentLocation != nil else
        {
            self.stations = stations
            guard let windowController = self.view.window?.windowController as? WindowController else { return }
            windowController.allStations = stations
            windowController.networkViewController?.activityIndicator.stopAnimation(nil)
            return
        }
        DispatchQueue.global(qos: .userInteractive).async
        {
            let bikes = stations.reduce(0){ $0 + ($1.freeBikes ?? 0) }
            let docks = stations.reduce(0){ $0 + ($1.emptySlots ?? 0) }
            let stationsString = Constants.numberFormatter.string(from: NSNumber(value: stations.count)) ?? ""
            let bikesString = Constants.numberFormatter.string(from: NSNumber(value: bikes)) ?? ""
            let docksString = Constants.numberFormatter.string(from: NSNumber(value: docks)) ?? ""
            
            let prompt = "\(self.network?.name ?? "") - \(stationsString) stations\n\(bikesString) available bikes - \(docksString) empty slots"
            let sortedStations = stations.sorted{ $0.distance < $1.distance }
            DispatchQueue.main.async
            {
                self.stations = sortedStations
                guard let windowController = self.view.window?.windowController as? WindowController else { return }
                windowController.allStations = sortedStations
                windowController.promptLabel.stringValue = prompt
                windowController.promptLabel.textColor = NSColor.app_blue
                windowController.networkViewController?.activityIndicator.stopAnimation(nil)
            }
        }
    }
    
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let identifier = "Bike"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil
        {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        switch self.state
        {
        case .networks:
            guard annotation is MapBikeNetwork else { return nil }
            annotationView?.annotation = annotation
            annotationView?.pinTintColor = NSColor.app_blue
            let button = NSButton(title: "View Stations", target: self, action: #selector(self.viewStationsClicked(sender:)))
            button.setButtonType(NSMomentaryPushInButton)
            
            let homeButton = NSButton(title: "☆", target: self, action: #selector(self.didClickHomeNetwork(sender:)))
            homeButton.setButtonType(NSMomentaryPushInButton)
            let normalAttribString = NSAttributedString(string: "☆", attributes: self.buttonAttributes)
            let selectedAttribString = NSAttributedString(string: "★", attributes: self.buttonAttributes)
            guard let annot = annotation as? MapBikeNetwork else { return nil }
            homeButton.attributedTitle = UserDefaults.bikeShareGroup.homeNetwork == annot.bikeNetwork ? selectedAttribString : normalAttribString
            
            annotationView?.rightCalloutAccessoryView = button
            annotationView?.leftCalloutAccessoryView = homeButton
            annotationView?.animatesDrop = true
        case .stations:
            guard annotation is MapBikeStation else { return nil }
            annotationView?.annotation = annotation
            let station = annotation as! MapBikeStation
            annotationView?.pinTintColor = station.bikeStation.pinTintColor
            let image = NSImage(named: NSImageNameShareTemplate)!
            let button = NSButton(image: image, target: self, action: #selector(self.didClickShare(sender:)))
            button.setButtonType(NSMomentaryPushInButton)
            button.sendAction(on: .leftMouseDown)
            annotationView?.rightCalloutAccessoryView = button
            annotationView?.leftCalloutAccessoryView = nil
            annotationView?.animatesDrop = false
        }
        
        annotationView?.canShowCallout = true
        
        return annotationView
    }
    
    //MARK: - Actions
    func viewStationsClicked(sender: NSButton)
    {
        guard let selectedAnnotation = self.mapView.selectedAnnotations.first as? MapBikeNetwork else { return }
        self.network = selectedAnnotation.bikeNetwork
        if let windowController = self.view.window?.windowController as? WindowController
        {
            windowController.networkViewController?.networks = []
        }
        self.fetchStations()
    }

    func didClickHomeNetwork(sender: NSButton)
    {
        guard let selectedAnnotation = self.mapView.selectedAnnotations.first as? MapBikeNetwork else { return }
        
        let normalAttribString = NSAttributedString(string: "☆", attributes: self.buttonAttributes)
        let selectedAttribString = NSAttributedString(string: "★", attributes: self.buttonAttributes)
        
        if UserDefaults.bikeShareGroup.homeNetwork == selectedAnnotation.bikeNetwork
        {
            UserDefaults.bikeShareGroup.setHomeNetwork(nil)
            sender.attributedTitle = normalAttribString
        }
        else
        {
            UserDefaults.bikeShareGroup.setHomeNetwork(selectedAnnotation.bikeNetwork)
            sender.attributedTitle = selectedAttribString
        }
    }
    
    func didClickShare(sender: NSButton)
    {
        guard let annotation = self.mapView.selectedAnnotations.first as? MapBikeStation,
              let network = self.network,
              let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.id)/station/\(annotation.bikeStation.id)")
        else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
    
}

extension BikeNetworkLocation
{
    var userManager: UserManager
    {
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    var distance: CLLocationDistance
    {
        guard let currentCoor = self.userManager.currentLocation else { return -1 }
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let currentLocation = CLLocation(latitude: currentCoor.latitude, longitude: currentCoor.longitude)
        let distance = stationLocation.distance(from: currentLocation)
        return distance
    }
    
    var distanceDescription: String
    {
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
