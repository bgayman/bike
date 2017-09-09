//
//  StationDiffViewControllerSearchController.swift
//  BikeShare
//
//  Created by B Gay on 5/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

protocol StationDiffViewControllerSearchControllerDelegate: class
{
    func didSelect(diff: BikeStationDiff)
}

class StationDiffViewControllerSearchController: UITableViewController
{
    var all = [BikeStationDiff]()
    var searchResults = [BikeStationDiff]()
    {
        didSet
        {
            self.tableView.reloadData()
        }
    }
    
    @objc var searchString = ""
    {
        didSet
        {
            self.searchResults = self.all.filter
            { diff in
                return diff.bikeStation.name.lowercased().contains(self.searchString.lowercased()) || diff.statusText.lowercased().contains(self.searchString.lowercased())
            }
            self.tableView.tableFooterView = self.searchResults.isEmpty ? UIView() : nil
        }
    }
    
    weak var delegate: StationDiffViewControllerSearchControllerDelegate?
    
    //MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = .app_beige
        self.tableView.register(BikeTableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.estimatedRowHeight = 65.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let diff = self.searchResults[indexPath.row]
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
        cell.searchString = self.searchString
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let diff = self.searchResults[indexPath.row]
        self.delegate?.didSelect(diff: diff)
    }
}

extension StationDiffViewControllerSearchController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let title = NSAttributedString(string: "No Changes", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title2), NSAttributedStringKey.foregroundColor: UIColor.gray])
        return title
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        let description = NSAttributedString(string: "No changes match search. Try reloading in a few moments.", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .subheadline), NSAttributedStringKey.foregroundColor: UIColor.lightGray])
        return description
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!
    {
        return #imageLiteral(resourceName: "seatedBear")
    }
}
