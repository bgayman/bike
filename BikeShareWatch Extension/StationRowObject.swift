//
//  StationRowObject.swift
//  BikeShare
//
//  Created by Brad G. on 1/28/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit

class StationRowObject: NSObject
{
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var subtitleLabel: WKInterfaceLabel!
    @IBOutlet var goLabel: WKInterfaceLabel!
    @IBOutlet var goGroup: WKInterfaceGroup!
    
    
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = bikeStation else { return }
            goGroup.setBackgroundColor(bikeStation.pinTintColor)
            switch bikeStation.pinTintColor
            {
            case UIColor.app_red:
                goLabel.setText("Grr!")
            case UIColor.app_orange:
                goLabel.setText("Whoa!")
            case UIColor.app_green:
                goLabel.setText("Go!")
            default:
                goLabel.setText(nil)
            }
            self.titleLabel.setText(bikeStation.name)
            self.subtitleLabel.setText(bikeStation.statusDisplayText)
            goGroup.setHidden(false)
        }
    }
    
    var bikeNetwork: BikeNetwork?
    {
        didSet
        {
            guard let bikeNetwork = self.bikeNetwork else { return }
            self.titleLabel.setText(bikeNetwork.name)
            self.subtitleLabel.setText(bikeNetwork.locationDisplayName)
        }
    }
    
    @objc var isEmptyRow: Bool = false
    {
        didSet
        {
            guard self.isEmptyRow else { return }
            self.titleLabel.setText("Updating")
            self.subtitleLabel.setText("Fetching Stations")
            goGroup.setHidden(true)
        }
    }
    
    @objc var errorMessage: String?
    {
        didSet
        {
            guard let errorMessage = errorMessage else { return }
            self.titleLabel.setText("🙈")
            self.subtitleLabel.setText(errorMessage)
            goGroup.setHidden(true)
        }
    }
    
    var message: (String?, String?)
    {
        didSet
        {
            self.titleLabel.setText(self.message.0)
            self.subtitleLabel.setText(self.message.1)
            goGroup?.setHidden(true)
        }
    }
}
