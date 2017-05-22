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
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = bikeStation else { return }
            let dotString = NSAttributedString(string: " • ", attributes: [NSForegroundColorAttributeName: bikeStation.pinTintColor])
            let titleString = NSAttributedString(string: bikeStation.name)
            self.titleLabel.setAttributedText(dotString + titleString)
            self.subtitleLabel.setText("\(bikeStation.statusDisplayText) - \(bikeStation.dateComponentText)")
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
    
    var isEmptyRow: Bool = false
    {
        didSet
        {
            guard self.isEmptyRow else { return }
            self.titleLabel.setText("Updating")
            self.subtitleLabel.setText("Fetching Stations...")
        }
    }
    
    var errorMessage: String?
    {
        didSet
        {
            guard let errorMessage = errorMessage else { return }
            self.titleLabel.setText("🙈")
            self.subtitleLabel.setText(errorMessage)
        }
    }
    
    var message: (String?, String?)
    {
        didSet
        {
            self.titleLabel.setText(self.message.0)
            self.subtitleLabel.setText(self.message.1)
        }
    }
}
