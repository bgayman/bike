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
            self.titleLabel.setText(bikeStation.name)
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
}
