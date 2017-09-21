//
//  MapDetailTableViewCell.swift
//  BikeShare
//
//  Created by B Gay on 9/13/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class MapDetailTableViewCell: UITableViewCell
{
    
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
        static let CornerRadius: CGFloat = 8.0
        static let LabelFont = UIFont.app_font(forTextStyle: .body)
        static let SubtitleLabelFont = UIFont.app_font(forTextStyle: .caption1)
    }

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var bikeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var acceptsLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = .clear
        self.separatorInset = UIEdgeInsetsMake(0, Constants.LayoutMargin, 0, 0)
        bikeImageView.removeFromSuperview()
        bikeImageView.layer.cornerRadius = Constants.CornerRadius
        titleLabel.font = Constants.LabelFont
        timeLabel.font = Constants.SubtitleLabelFont
        timeLabel.textColor = UIColor.gray
        distanceLabel.font = Constants.SubtitleLabelFont
        distanceLabel.textColor = UIColor.gray
        acceptsLabel.font = Constants.SubtitleLabelFont
        acceptsLabel.textColor = UIColor.lightGray
        let attributes = [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .title1), NSAttributedStringKey.foregroundColor: UIColor.app_blue]
        let normalAttribString = NSAttributedString(string: "☆", attributes: attributes)
        let selectedAttribString = NSAttributedString(string: "★", attributes: attributes)
        favoritesButton.setAttributedTitle(normalAttribString, for: .normal)
        favoritesButton.setAttributedTitle(selectedAttribString, for: .selected)
    }
}
