//
//  BikeDetailAccessoryTableViewCell.swift
//  BikeShare
//
//  Created by B Gay on 12/25/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit

class BikeDetailAccessoryTableViewCell: UITableViewCell
{
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
        static let CornerRadius: CGFloat = 8.0
        static let LabelFont = UIFont.app_font(forTextStyle: .body)
        static let SubtitleLabelFont = UIFont.app_font(forTextStyle: .caption1)
    }
    
    #if !os(tvOS)
    @objc let activityIndicator: UIActivityIndicatorView =
    {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 150.0).isActive = true
        return indicator
    }()
    #endif
    
    
    @objc lazy var stackView: UIStackView =
    {
        #if !os(tvOS)
        let stackView = UIStackView(arrangedSubviews: [self.activityIndicator, self.calloutLabel, self.calloutSubtitleLabel])
        #else
        let stackView = UIStackView(arrangedSubviews: [self.calloutLabel, self.calloutSubtitleLabel])
        #endif
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: Constants.LayoutMargin).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.LayoutMargin).isActive = true
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()
    
    @objc lazy var calloutLabel: UILabel =
    {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = Constants.LabelFont
        label.textAlignment = .center
        return label
    }()
    
    @objc lazy var calloutSubtitleLabel: UILabel =
    {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = Constants.SubtitleLabelFont
        label.textColor = UIColor.gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    @objc lazy var bikeImageView: UIImageView =
    {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Constants.CornerRadius
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override func willMove(toSuperview newSuperview: UIView?)
    {
        super.willMove(toSuperview: newSuperview)
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = .clear
        self.stackView.spacing = Constants.LayoutMargin
        #if !os(tvOS)
        self.separatorInset = UIEdgeInsetsMake(0, Constants.LayoutMargin, 0, 0)
        #endif
    }
}
