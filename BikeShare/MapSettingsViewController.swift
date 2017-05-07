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
        }
    }
    
    static var all: [MapSettingsSections] = [.pins, .rentalMethods, .status]
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

class MapSettingsViewController: UIViewController
{
    lazy var tableView: UITableView =
    {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        let nib = UINib(nibName: "\(MapPinTableViewCell.self)", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "\(MapPinTableViewCell.self)")
        return tableView
    }()
    
    let pins: [(UIColor, String)] = [(UIColor.app_green, "Good mix of bikes and empty slots"), (UIColor.app_orange, "Approaching full or empty"), (UIColor.app_red, "Station is full or empty")]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.isHidden = false
        self.automaticallyAdjustsScrollViewInsets = false
        self.title = "Map Symbols"
        self.navigationController?.navigationBar.barTintColor = UIColor.app_beige
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone(sender:)))
    }
    
    func didPressDone(sender: UIBarButtonItem)
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
            return 3
        case .status:
            return 4
        case .rentalMethods:
            return RentalMethod.all.count
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
            cell.meaningLabel.textColor = .lightGray
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
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let section = MapSettingsSections(rawValue: section) else { return "" }
        return section.title
    }
}
