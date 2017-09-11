//
//  BikeStationTableViewCell.swift
//  BikeShare
//
//  Created by Brad G. on 9/10/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class BikeStationTableViewCell: UITableViewCell
{
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = self.bikeStation else { return }
            guard self.searchString == nil else
            {
                self.configureCell(searchString: self.searchString!)
                return
            }
            self.configureCell(bikeStation: bikeStation)
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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stationStatusLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor.app_beige
        backgroundColor = UIColor.app_beige
        titleLabel.font = UIFont.app_font(forTextStyle: .title2, weight: UIFont.Weight.semibold)
        titleLabel.numberOfLines = 0
        stationStatusLabel.numberOfLines = 1
        stationStatusLabel.font = UIFont.app_font(forTextStyle: .title1, weight: UIFont.Weight.light)
        distanceLabel.font = UIFont.app_font(forTextStyle: .caption1, weight: UIFont.Weight.medium)
        timeLabel.font = UIFont.app_font(forTextStyle: .caption1, weight: UIFont.Weight.medium)
        summaryLabel.font = UIFont.app_font(forTextStyle: .headline, weight: .heavy)
        summaryLabel.textColor = .white
        summaryLabel.layer.cornerRadius = 8.0
        summaryLabel.layer.masksToBounds = true
    }
    
    private func configureCell(bikeStation: BikeStation)
    {
        self.titleLabel.text = bikeStation.name
        self.stationStatusLabel.attributedText = bikeStation.statusAttributedString
        self.timeLabel.text = bikeStation.dateComponentText
        if bikeStation.distanceDescription.isEmpty == false
        {
            self.distanceLabel.isHidden = false
            self.distanceLabel.text = bikeStation.distanceDescription
        }
        else
        {
            self.distanceLabel.isHidden = true
        }
        summaryLabel.backgroundColor = bikeStation.pinTintColor
        switch bikeStation.pinTintColor
        {
        case UIColor.app_red:
            summaryLabel.text = "Grr!"
        case UIColor.app_orange:
            summaryLabel.text = "Whoa!"
        case UIColor.app_green:
            summaryLabel.text = "Go!"
        default:
            summaryLabel.text = nil
        }
    }
    
    private func configureCell(searchString: String)
    {
        guard let bikeStation = self.bikeStation else { return }
        configureCell(bikeStation: bikeStation)
        let titleAttribString = NSMutableAttributedString(string: bikeStation.name, attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title1)])
        
        self.titleLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
    }
    
    private func searchHightlighted(attribString: NSMutableAttributedString, searchString: String) -> NSAttributedString
    {
        let range = (attribString.string.lowercased() as NSString).range(of: searchString.lowercased())
        attribString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.app_blue], range: range)
        return attribString
    }
    
}
