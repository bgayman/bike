//
//  StationDetailTableViewCell.swift
//  BikeShare
//
//  Created by B Gay on 12/27/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit

class StationDetailTableViewCell: UITableViewCell
{
    //MARK: - Constants
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
        static let LabelFont = UIFont.app_font(forTextStyle: .title1)
        static let SubtitleLabelFont = UIFont.app_font(forTextStyle: .caption1)
    }
    
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = self.bikeStation else
            {
                self.titleLabel.text = nil
                self.subtitleLabel.text = nil
                return
            }
            self.titleLabel.text = bikeStation.statusDisplayText
            self.subtitleLabel.text = "\(bikeStation.name) — \(bikeStation.dateComponentText)" + (bikeStation.distance > 0 ? "— \(bikeStation.distanceDescription)" : "")
            #if !os(tvOS)
                self.separatorInset = UIEdgeInsets(top: 0, left: Constants.LayoutMargin, bottom: 0, right: 0)
            #endif
        }
    }
    
    lazy var titleLabel: UILabel =
    {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = Constants.LabelFont
        self.contentView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: Constants.LayoutMargin).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.contentView.readableContentGuide.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.contentView.readableContentGuide.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: self.subtitleLabel.topAnchor, constant: -Constants.LayoutMargin).isActive = true
        return titleLabel
    }()
    
    lazy var subtitleLabel: UILabel =
    {
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.font = Constants.SubtitleLabelFont
        self.contentView.addSubview(subtitleLabel)
        subtitleLabel.leadingAnchor.constraint(equalTo: self.contentView.readableContentGuide.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: self.contentView.readableContentGuide.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.LayoutMargin).isActive = true
        return subtitleLabel
    }()
}
