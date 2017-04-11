//
//  BikeDetailCalloutAccessoryView.swift
//  BikeShare
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa
import MapKit

protocol BikeDetailCalloutAccessoryViewDelegate: class
{
    func didSelectNetworkCallout(with mapBikeNetwork: MapBikeNetwork)
    func didSelectStationCallout(with mapBikeStation: MapBikeStation)
    
}

enum BikeDetailCalloutAnnotation
{
    case mapBikeNetwork(network: MapBikeNetwork)
    case mapBikeStation(station: MapBikeStation)
}

class BikeDetailCalloutAccessoryView: NSView
{
    let annotation: BikeDetailCalloutAnnotation
    let imageWidthHeight: CGFloat = 250.0
    weak var delegate: BikeDetailCalloutAccessoryViewDelegate?
    
    var rowHeight: CGFloat
    {
        let label = NSTextField()
        label.font = BikeDetailAccessoryTableViewCell.Constants.LabelFont
        switch annotation
        {
        case .mapBikeNetwork(let network):
            label.stringValue = network.subtitle ?? ""
        case .mapBikeStation(let station):
            label.stringValue = station.subtitle ?? ""
        }
        let size = label.sizeThatFits(CGSize(width: self.imageWidthHeight, height: CGFloat.greatestFiniteMagnitude))
        var height = self.imageWidthHeight + (3 * BikeDetailAccessoryTableViewCell.Constants.LayoutMargin) + size.height
        if case BikeDetailCalloutAnnotation.mapBikeStation(let station) = annotation
        {
            label.font = BikeDetailAccessoryTableViewCell.Constants.SubtitleLabelFont
            label.stringValue = station.dateComponentText
            let size2 = label.sizeThatFits(CGSize(width: self.imageWidthHeight, height: CGFloat.greatestFiniteMagnitude))
            height += BikeDetailAccessoryTableViewCell.Constants.LayoutMargin + size2.height
        }
        else
        {
            height += BikeDetailAccessoryTableViewCell.Constants.LayoutMargin + self.homeNetworkButton.intrinsicContentSize.height
        }
        return height
    }
    
    var userManager: UserManager
    {
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    lazy var tableView: NSTableView =
    {
        let tableView = NSTableView(frame: CGRect.zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        tableView.backgroundColor = .clear
        let column = NSTableColumn(identifier: "Column")
        column.width = self.bounds.width
        tableView.addTableColumn(column)
        return tableView
    }()
    
    lazy var snapshotOptions: MKMapSnapshotOptions =
    {
        let options = MKMapSnapshotOptions()
        options.size = CGSize(width: self.imageWidthHeight, height: self.imageWidthHeight)
        options.mapType = .satelliteFlyover
        options.showsPointsOfInterest = true
        switch self.annotation
        {
        case .mapBikeStation(let station):
            options.camera = MKMapCamera(lookingAtCenter: station.coordinate, fromDistance: 250, pitch: 65, heading: 0)
        case .mapBikeNetwork(let network):
            options.camera = MKMapCamera(lookingAtCenter: network.coordinate, fromDistance: 3500, pitch: 35, heading: 0)
        }
        return options
    }()
    
    lazy var homeNetworkButton: NSButton =
    {
        let button = NSButton(title: "☆", target: self, action: #selector(self.didPressHomeNetwork(_:)))
        let attributes = [NSFontAttributeName: NSFont.app_font(size: 16), NSForegroundColorAttributeName: NSColor.app_blue]
        let normalAttribString = NSAttributedString(string: "☆", attributes: attributes)
        let selectedAttribString = NSAttributedString(string: "★", attributes: attributes)
        
        button.attributedTitle = normalAttribString
        button.attributedAlternateTitle = selectedAttribString
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(annotation: BikeDetailCalloutAnnotation)
    {
        self.annotation = annotation
        super.init(frame: CGRect.zero)
        let labelSize: CGSize
        switch annotation
        {
        case .mapBikeNetwork(let network):
            labelSize = NSTextField.labelSize(with: network.title ?? "")
        case .mapBikeStation(let station):
            labelSize = NSTextField.labelSize(with: station.title ?? "")
        }
        self.frame = CGRect(x: 0, y: 0, width: max(275.0, labelSize.width), height: self.rowHeight)
        self.tableView.reloadData()
        self.layoutSubtreeIfNeeded()
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension BikeDetailCalloutAccessoryView: NSTableViewDelegate, NSTableViewDataSource
{
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        var c = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as? BikeDetailAccessoryTableViewCell
        if c == nil
        {
            c = BikeDetailAccessoryTableViewCell(frame: self.bounds)
            c?.identifier = "column"
        }
        guard let cell = c else { return nil }
        switch annotation
        {
        case .mapBikeStation(let station):
            let string = self.userManager.currentLocation != nil ? (station.subtitle ?? "") + " - \(station.bikeStation.distanceDescription)" : (station.subtitle ?? "")
            cell.calloutLabel.stringValue = string
            cell.calloutSubtitleLabel.stringValue = station.dateComponentText
            cell.calloutSubtitleLabel.isHidden = false
        case .mapBikeNetwork(let network):
            let string = self.userManager.currentLocation != nil ? (network.subtitle ?? "") + " - \(network.bikeNetwork.location.distanceDescription)" : (network.subtitle ?? "")
            cell.calloutLabel.stringValue = string
            cell.calloutSubtitleLabel.isHidden = true
            #if !os(tvOS)
                cell.stackView.addArrangedSubview(self.homeNetworkButton)
            #endif
            if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork,
                homeNetwork.id == network.bikeNetwork.id
            {
                self.homeNetworkButton.state = 1
            }
            else
            {
                self.homeNetworkButton.state = 0
            }
        }
        self.configureImageView(with: cell)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return self.rowHeight
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        switch annotation
        {
        case .mapBikeNetwork(let network):
            self.delegate?.didSelectNetworkCallout(with: network)
        case .mapBikeStation(let station):
            self.delegate?.didSelectStationCallout(with: station)
        }
    }
}

extension BikeDetailCalloutAccessoryView
{
    func configureImageView(with cell: BikeDetailAccessoryTableViewCell)
    {
        cell.bikeImageView.isHidden = true
        let snapshotter = MKMapSnapshotter(options: self.snapshotOptions)
        snapshotter.start
        { (snapshot, _) in
            cell.bikeImageView.image = snapshot?.image
            cell.stackView.insertArrangedSubview(cell.bikeImageView, at: 0)
            cell.bikeImageView.isHidden = false
        }
    }
    
    //MARK: - Actions
    func didPressHomeNetwork(_ sender: NSButton)
    {
        if sender.state == 1
        {
            sender.state = 0
            UserDefaults.bikeShareGroup.setHomeNetwork(nil)
            #if os(iOS) || os(watchOS)
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: NSNull() as AnyObject])
            #endif
        }
        else
        {
            guard case BikeDetailCalloutAnnotation.mapBikeNetwork(let network) = self.annotation else { return }
            sender.state = 1
            UserDefaults.bikeShareGroup.setHomeNetwork(network.bikeNetwork)
            #if os(iOS) || os(watchOS)
                try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: network.bikeNetwork.jsonDict as AnyObject])
            #endif
        }
    }
}

extension BikeStation
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
        return stationLocation.distance(from: currentLocation)
    }
    
    var distanceDescription: String
    {
        guard self.distance > 0 else { return "" }
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
