//
//  StationDiffTableViewCell.swift
//  BikeShare
//
//  Created by B Gay on 9/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class StationDiffTableViewCell: UITableViewCell
{

    var bikeStationDiff: BikeStationDiff?
    {
        didSet
        {
            stationNameLabel.text = bikeStationDiff?.bikeStation.name
            
            let subtitleText = [bikeStationDiff?.statusText ?? ""]
            diffStatusLabel.text = subtitleText.joined(separator: " | ")
            
            radiusView.backgroundColor = bikeStationDiff?.overlayColor
            radiusViewWidthConstraint.constant = abs(CGFloat(bikeStationDiff?.bikesAdded ?? 0)) * 20.0
            
            radiusView.layer.cornerRadius = radiusViewWidthConstraint.constant * 0.5
            
            if let searchString = self.searchString
            {
                configureCell(searchString: searchString)
            }
        }
    }
    
    @objc var searchString: String?
    {
        didSet
        {
            guard let searchString = self.searchString else { return }
            self.configureCell(searchString: searchString)
        }
    }
    
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var diffStatusLabel: UILabel!
    @IBOutlet weak var radiusView: UIView!
    @IBOutlet weak var radiusViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        stationNameLabel.font = UIFont.app_font(forTextStyle: .title3, weight: .semibold)
        diffStatusLabel.font = UIFont.app_font(forTextStyle: .callout, weight: .medium)
        stationNameLabel.numberOfLines = 0
        stationNameLabel.lineBreakMode = .byWordWrapping
        diffStatusLabel.numberOfLines = 0
        diffStatusLabel.lineBreakMode = .byWordWrapping
        radiusView.alpha = 0.30
        radiusView.layer.masksToBounds = true
        selectionStyle = .none
    }
    
    private func configureCell(searchString: String)
    {
        guard let bikeStation = self.bikeStationDiff?.bikeStation else { return }
        let titleAttribString = NSMutableAttributedString(string: bikeStation.name)
        
        self.stationNameLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
    }
    
    private func searchHightlighted(attribString: NSMutableAttributedString, searchString: String) -> NSAttributedString
    {
        let range = (attribString.string.lowercased() as NSString).range(of: searchString.lowercased())
        attribString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.app_blue], range: range)
        return attribString
    }
    
}
