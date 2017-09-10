//
//  BikeStation+AttributedString.swift
//  BikeShare
//
//  Created by Brad G. on 9/10/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

extension BikeStation
{
    var statusAttributedString: NSAttributedString
    {
        let font = UIFont.app_font(forTextStyle: .caption1)
        let size = font.pointSize * 3.0
        
        guard let freeBikes = self.freeBikes,
            let emptySlots = self.emptySlots else { return NSAttributedString(string: "🤷‍♀️") }
        
        let bikeTextAttachment = NSTextAttachment()
        bikeTextAttachment.image = #imageLiteral(resourceName: "icBikeBearSmall")
        bikeTextAttachment.setImageHeight(height: size)
        let emptySlotTextAttachment = NSTextAttachment()
        emptySlotTextAttachment.image = #imageLiteral(resourceName: "icSlotSmall")
        emptySlotTextAttachment.setImageHeight(height: size)

        let stationClosedTextAttachment = NSTextAttachment()
        stationClosedTextAttachment.image = #imageLiteral(resourceName: "icClosedStationSmall")
        stationClosedTextAttachment.setImageHeight(height: size)
        
        let brokenBikeTextAttachment = NSTextAttachment()
        brokenBikeTextAttachment.image = #imageLiteral(resourceName: "icBrokenBikeSmall")
        brokenBikeTextAttachment.setImageHeight(height: size)
        
        let brokenSlotTextAttachment = NSTextAttachment()
        brokenSlotTextAttachment.image = #imageLiteral(resourceName: "icBrokenStationSmall")
        brokenSlotTextAttachment.setImageHeight(height: size)
        
        var status = NSAttributedString(string: "\(freeBikes) ") + NSAttributedString(attachment: bikeTextAttachment) + NSAttributedString(string: ", \(emptySlots) ") + NSAttributedString(attachment: emptySlotTextAttachment)
        
        if self.gbfsStationInformation?.stationStatus?.isRenting == false ||
            self.gbfsStationInformation?.stationStatus?.isInstalled == false
        {
            return NSAttributedString(attachment: stationClosedTextAttachment) + NSAttributedString(string: " Station Closed")
        }
        else if self.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0 > 0
            
        {
            status = status + NSAttributedString(string: ", \(self.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0) ") + NSAttributedString(attachment: brokenBikeTextAttachment)
        }
        else if self.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0 > 0
        {
            status = status + NSAttributedString(string: ", \(self.gbfsStationInformation?.stationStatus?.numberOfDocksDisabled ?? 0) ") + NSAttributedString(attachment: brokenSlotTextAttachment)
        }
        
        return status
        
    }
}
