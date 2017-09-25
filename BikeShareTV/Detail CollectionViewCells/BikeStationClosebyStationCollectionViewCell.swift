//
//  BikeStationClosebyStationCollectionViewCell.swift
//  BikeShareTV
//
//  Created by B Gay on 9/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class BikeStationClosebyStationCollectionViewCell: UICollectionViewCell
{
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var timeDistanceLabel: UILabel!
    @IBOutlet fileprivate weak var summaryLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = bikeStation else { return }
            timeDistanceLabel.text = "\(bikeStation.dateComponentText) | \(bikeStation.distanceDescription)"
            titleLabel.text = bikeStation.name
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
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        titleLabel.font = UIFont.app_font(forTextStyle: .callout, weight: UIFont.Weight.semibold)
        timeDistanceLabel.font = UIFont.app_font(forTextStyle: .caption1, weight: UIFont.Weight.medium)
        summaryLabel.font = UIFont.app_font(forTextStyle: .headline, weight: .heavy)
        summaryLabel.textColor = .white
        summaryLabel.layer.cornerRadius = 8.0
        summaryLabel.layer.masksToBounds = true
    }
}
