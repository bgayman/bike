//
//  BikeDetailCalloutAccessoryView.swift
//  BikeShare
//
//  Created by B Gay on 12/25/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit
import MapKit

protocol BikeDetailCalloutAccessoryViewDelegate: class
{
    func didSelectNetworkCallout(with mapBikeNetwork: MapBikeNetwork)
    func didSelectStationCallout(with mapBikeStation: MapBikeStation)

}

enum BikeDetailCalloutAnnotation
{
    case mapBikeNetwork(network: MapBikeNetwork)
    case mapBikeStation(network: MapBikeNetwork, station: MapBikeStation)
}

class BikeDetailCalloutAccessoryView: UIView
{
    let annotation: BikeDetailCalloutAnnotation
    @objc let imageWidthHeight: CGFloat = 150.0
    weak var delegate: BikeDetailCalloutAccessoryViewDelegate?
    
    @objc var rowHeight: CGFloat
    {
        let label = UILabel()
        label.font = BikeDetailAccessoryTableViewCell.Constants.LabelFont
        switch annotation
        {
        case .mapBikeNetwork(let network):
            label.text = network.subtitle ?? ""
        case .mapBikeStation(_, let station):
            label.text = station.subtitle ?? ""
        }
        let size = label.sizeThatFits(CGSize(width: self.imageWidthHeight, height: CGFloat.greatestFiniteMagnitude))
        var height = self.imageWidthHeight + (8 * BikeDetailAccessoryTableViewCell.Constants.LayoutMargin) + size.height
        if case BikeDetailCalloutAnnotation.mapBikeStation(_, let station) = annotation
        {
            label.font = BikeDetailAccessoryTableViewCell.Constants.SubtitleLabelFont
            label.text = station.dateComponentText
            let size2 = label.sizeThatFits(CGSize(width: self.imageWidthHeight, height: CGFloat.greatestFiniteMagnitude))
            height += BikeDetailAccessoryTableViewCell.Constants.LayoutMargin + size2.height
        }
        
        return height
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment]
    {
        return [self.tableView]
    }
    
    @objc var userManager: UserManager
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    @objc lazy var tableView: UITableView =
    {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        #if !os(tvOS)
            tableView.separatorStyle = .none
            tableView.dragDelegate = self
        #endif
        return tableView
    }()
    
    @objc lazy var snapshotOptions: MKMapSnapshotOptions =
    {
        let options = MKMapSnapshotOptions()
        options.size = CGSize(width: self.imageWidthHeight, height: self.imageWidthHeight)
        options.mapType = .satelliteFlyover
        options.showsPointsOfInterest = true
        options.scale = UIScreen.main.scale
        switch self.annotation
        {
        case .mapBikeStation(_, let station):
            options.camera = MKMapCamera(lookingAtCenter: station.coordinate, fromDistance: 250, pitch: 65, heading: 0)
        case .mapBikeNetwork(let network):
            options.camera = MKMapCamera(lookingAtCenter: network.coordinate, fromDistance: 3500, pitch: 35, heading: 0)
        }
        return options
    }()
    
    init(annotation: BikeDetailCalloutAnnotation)
    {
        self.annotation = annotation
        super.init(frame: CGRect.zero)
        let nib = UINib(nibName: "\(MapDetailTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
        let labelSize: CGSize
        switch annotation
        {
        case .mapBikeNetwork(let network):
            labelSize = UILabel.labelSize(with: network.title ?? "")
        case .mapBikeStation(_, let station):
            labelSize = UILabel.labelSize(with: station.title)
        }
        self.widthAnchor.constraint(equalToConstant: max(200.0, labelSize.width)).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.rowHeight).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Don't use a coder")
    }
    
}

extension BikeDetailCalloutAccessoryView: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MapDetailTableViewCell
        switch annotation
        {
        case .mapBikeStation(let network, let station):
            cell.titleLabel.text = station.subtitle
            cell.timeLabel.text = station.dateComponentText
            cell.distanceLabel.text = self.userManager.currentLocation != nil ? station.bikeStation.distanceDescription : nil
            cell.timeLabel.isHidden = false
            cell.favoritesButton.isSelected = UserDefaults.bikeShareGroup.isStationFavorited(station: station.bikeStation, network: network.bikeNetwork)
            cell.favoritesButton.addTarget(self, action: #selector(self.didPressHomeNetwork(_:)), for: .touchUpInside)
            cell.acceptsLabel.isHidden = station.bikeStation.gbfsStationInformation == nil
            if let rentalMethods = station.bikeStation.gbfsStationInformation?.rentalMethods
            {
                cell.acceptsLabel.text = rentalMethods.map { $0.displayString }.joined(separator: ", ")
            }
            
        case .mapBikeNetwork(let network):
            cell.titleLabel.text = network.subtitle
            cell.distanceLabel.text = self.userManager.currentLocation != nil ? network.bikeNetwork.location.distanceDescription : nil
            cell.timeLabel.isHidden = true
            cell.favoritesButton.isSelected = UserDefaults.bikeShareGroup.isNetworkHomeNetwork(network: network.bikeNetwork)
            cell.favoritesButton.addTarget(self, action: #selector(self.didPressHomeNetwork(_:)), for: .touchUpInside)
            cell.acceptsLabel.isHidden = true
        }
        self.configureImageView(with: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
        switch annotation
        {
        case .mapBikeNetwork(let network):
            self.delegate?.didSelectNetworkCallout(with: network)
        case .mapBikeStation(_, let station):
            self.delegate?.didSelectStationCallout(with: station)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return self.rowHeight
    }
}

#if !os(tvOS)
extension BikeDetailCalloutAccessoryView: UITableViewDragDelegate
{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem]
    {
        switch annotation
        {
        case .mapBikeNetwork(let network):
            guard let url = URL(string: "\(Constants.WebSiteDomain)/stations/\(network.bikeNetwork.id)") else { return [] }
            let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            let dragStringItem = UIDragItem(itemProvider: NSItemProvider(object: "\(network.bikeNetwork.name)" as NSString))
            return [dragURLItem, dragStringItem]
        case .mapBikeStation(let network, let station):
            guard let url = URL(string: "\(Constants.WebSiteDomain)/network/\(network.bikeNetwork.id)/station/\(station.bikeStation.id)") else { return [] }
            let dragURLItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            let dragStringItem = UIDragItem(itemProvider: NSItemProvider(object: "\(station.bikeStation.name) \(station.bikeStation.statusDisplayText)" as NSString))
            return [dragURLItem, dragStringItem]
        }
    }
}
#endif

extension BikeDetailCalloutAccessoryView
{
    @objc func configureImageView(with cell: MapDetailTableViewCell)
    {
        cell.bikeImageView.isHidden = true
        cell.bikeImageView.alpha = 0
        cell.activityIndicator.startAnimating()
        let snapshotter = MKMapSnapshotter(options: self.snapshotOptions)
        snapshotter.start
        { (snapshot, _) in
            cell.bikeImageView.image = snapshot?.image
            cell.activityIndicator.stopAnimating()
            cell.stackView.removeArrangedSubview(cell.activityIndicator)
            cell.stackView.insertArrangedSubview(cell.bikeImageView, at: 0)
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations:
            {
                cell.bikeImageView.isHidden = false
                cell.bikeImageView.alpha = 1
            })
        }
    }
    
    //MARK: - Actions
    @objc func didPressHomeNetwork(_ sender: UIButton)
    {
        switch self.annotation
        {
        case .mapBikeNetwork:
            if sender.isSelected
            {
                sender.isSelected = false
                UserDefaults.bikeShareGroup.setHomeNetwork(nil)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: NSNull() as AnyObject])
                #endif
            }
            else
            {
                guard case BikeDetailCalloutAnnotation.mapBikeNetwork(let network) = self.annotation else { return }
                sender.isSelected = true
                UserDefaults.bikeShareGroup.setHomeNetwork(network.bikeNetwork)
                #if os(iOS) || os(watchOS)
                    try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [Constants.HomeNetworkKey: network.bikeNetwork.jsonDict as AnyObject])
                #endif
            }
        case .mapBikeStation(let network, let station):
            if sender.isSelected
            {
                sender.isSelected = false
                UserDefaults.bikeShareGroup.removeStationFromFavorites(station: station.bikeStation, network: network.bikeNetwork)
            }
            else
            {
                sender.isSelected = true
                UserDefaults.bikeShareGroup.addStationToFavorites(station: station.bikeStation, network: network.bikeNetwork)
            }
        }
        
    }
}

