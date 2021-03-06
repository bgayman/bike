//
//  MapSettingsViewController.swift
//  BikeShare
//
//  Created by B Gay on 4/30/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

enum MapSettingsSections: Int
{
    case pins
    case status
    case rentalMethods
    case networkInfo
    
    var title: String
    {
        switch self
        {
        case .pins:
            return "Map Annotations"
        case .rentalMethods:
            return "Rental Methods"
        case .status:
            return "Station Status"
        case .networkInfo:
            return "Network Information"
        }
    }
    
    static var all: [MapSettingsSections] = [.pins, .rentalMethods, .status, .networkInfo]
}

enum StationStatus: Int
{
    case availibleBikes
    case openDock
    case disabledBikes
    case disabledDock
    case unknownStatus
    
    static var all = [StationStatus.availibleBikes, StationStatus.openDock, StationStatus.disabledBikes, disabledDock, StationStatus.unknownStatus]
    
    var string: String
    {
        switch self
        {
        case .availibleBikes:
            return "🚲"
        case .openDock:
            return "🆓"
        case .disabledBikes:
            return "🚳"
        case .disabledDock:
            return "⛔️"
        case .unknownStatus:
            return "🤷‍♀️"
        }
    }
    
    var meaning: String
    {
        switch self
        {
        case .availibleBikes:
            return "Availible Bikes"
        case .openDock:
            return "Open Docks"
        case .disabledBikes:
            return "Disabled Bikes"
        case .disabledDock:
            return "Disabled Docks"
        case .unknownStatus:
            return "Status Cannot be Determined"
        }
    }
}

enum NetworkInformation
{
    case gbfs
    
    static var all = [NetworkInformation.gbfs]
    
    var string: String
    {
        switch self
        {
        case .gbfs:
            return "GBFS"
        }
    }
    
    var meaning: String
    {
        switch self
        {
        case .gbfs:
            return "General Bikeshare Feed Specification"
        }
    }
}

class MapSettingsViewController: UIViewController
{
    @objc lazy var tableView: UITableView =
    {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
        let nib = UINib(nibName: "\(MapPinTableViewCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "\(MapPinTableViewCell.self)")
        return tableView
    }()
    
    let pins: [(UIColor, String)] = [(UIColor.app_green, "Good mix of bikes and empty slots"), (UIColor.app_orange, "Approaching full or empty / Status cannot be determined"), (UIColor.app_red, "Station is full or empty"), (UIColor.app_blue, "Bike network")]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.app_beige
        self.tableView.isHidden = false
        self.title = "Map Symbols"
        self.navigationController?.navigationBar.barTintColor = UIColor.app_beige
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone(sender:)))
    }
    
    @objc func didPressDone(sender: UIBarButtonItem)
    {
        self.dismiss(animated: true)
    }
}

extension MapSettingsViewController: UITableViewDelegate, UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return MapSettingsSections.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let section = MapSettingsSections(rawValue: section) else { fatalError("Add new section to MapSettingsSections") }
        switch section
        {
        case .pins:
            return self.pins.count
        case .status:
            return StationStatus.all.count
        case .rentalMethods:
            return RentalMethod.all.count
        case .networkInfo:
            return NetworkInformation.all.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let section = MapSettingsSections(rawValue: indexPath.section) else { fatalError("Add new section to MapSettingsSections") }
        switch section
        {
        case .pins:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(MapPinTableViewCell.self)", for: indexPath) as! MapPinTableViewCell
            let pin = self.pins[indexPath.row]
            cell.pinView.pinTintColor = pin.0
            cell.pinView.backgroundColor = .app_beige
            cell.pinView.isOpaque = false
            cell.meaningLabel.text = pin.1
            cell.meaningLabel.textColor = .gray
            cell.contentView.backgroundColor = .app_beige
            cell.backgroundColor = .app_beige
            return cell
        case .status:
            guard let status = StationStatus(rawValue: indexPath.row) else { return UITableViewCell() }
            var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
            if cell == nil
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
            }
            cell?.textLabel?.text = status.string
            cell?.detailTextLabel?.text = status.meaning
            cell?.contentView.backgroundColor = .app_beige
            cell?.backgroundColor = .app_beige
            return cell!
        case .rentalMethods:
            var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
            if cell == nil
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
            }
            let rentalMethod = RentalMethod.all[indexPath.row]
            cell?.textLabel?.text = rentalMethod.displayString
            cell?.detailTextLabel?.text = rentalMethod.meaningString
            cell?.contentView.backgroundColor = .app_beige
            cell?.backgroundColor = .app_beige
            return cell!
        case .networkInfo:
            var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
            if cell == nil
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
            }
            let networkInfo = NetworkInformation.all[indexPath.row]
            cell?.textLabel?.text = networkInfo.string
            cell?.detailTextLabel?.text = networkInfo.meaning
            cell?.detailTextLabel?.numberOfLines = 0
            cell?.contentView.backgroundColor = .app_beige
            cell?.backgroundColor = .app_beige
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let section = MapSettingsSections(rawValue: section) else { return "" }
        return section.title
    }
}
