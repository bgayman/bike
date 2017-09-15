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
        
        let nib = UINib(nibName: "\(StationDiffTableViewCell.self)", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "Cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationDiffTableViewCell
        
        cell.bikeStationDiff = diff
        cell.searchString = self.searchString
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
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
