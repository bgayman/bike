//
//  BikeDetailAccessoryTableViewCell.swift
//  BikeShare
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

class BikeDetailAccessoryTableViewCell: NSTableCellView
{
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
        static let CornerRadius: CGFloat = 8.0
        static let LabelFont = NSFont.app_font(size: 14.0)
        static let SubtitleLabelFont = NSFont.app_font(size: 12.0)
    }
    
    lazy var stackView: NSStackView =
    {
        let stackView = NSStackView(views: [self.calloutLabel, self.calloutSubtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.LayoutMargin).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.LayoutMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.LayoutMargin).isActive = true
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        return stackView
    }()
    
    lazy var calloutLabel: NSTextField =
    {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.font = Constants.LabelFont
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        return label
    }()
    
    lazy var calloutSubtitleLabel: NSTextField =
    {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.maximumNumberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.font = Constants.SubtitleLabelFont
        label.textColor = NSColor.gray
        label.alignment = .center
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.isHidden = true
        return label
    }()
    
    lazy var bikeImageView: NSImageView =
    {
        let imageView = NSImageView()
        imageView.wantsLayer = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer?.cornerRadius = Constants.CornerRadius
        imageView.layer?.masksToBounds = true
        return imageView
    }()
    
    override func viewWillMove(toWindow newWindow: NSWindow?)
    {
        super.viewWillMove(toWindow: newWindow)
        self.wantsLayer = true
        self.stackView.spacing = Constants.LayoutMargin
    }
}
