//
//  NSTextAttachment+Application.swift
//  BikeShare
//
//  Created by B Gay on 9/10/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

extension NSTextAttachment
{
    func setImageHeight(height: CGFloat)
    {
        guard let image = image else { return }
        let ratio = image.size.width / image.size.height
        
        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: ratio * height, height: height)
    }
}


extension BikeStation
{
    var statusAttributedString: NSAttributedString
    {
        let initialString: NSString = statusDisplayText as NSString
        let mutableAttribString = NSMutableAttributedString(string: initialString as String)
        let bikeTextAttachment = NSTextAttachment()
        bikeTextAttachment.image = #imageLiteral(resourceName: "icBikeBear")
        let emptySlotTextAttachment = NSTextAttachment()
        emptySlotTextAttachment.image = #imageLiteral(resourceName: "icSlot")
        let stationClosedTextAttachment = NSTextAttachment()
        stationClosedTextAttachment.image = #imageLiteral(resourceName: "icClosedStation")
        let brokenBikeTextAttachment = NSTextAttachment()
        brokenBikeTextAttachment.image = #imageLiteral(resourceName: "icBrokenBike")
        let brokenSlotTextAttachment = NSTextAttachment()
        brokenSlotTextAttachment.image = #imageLiteral(resourceName: "icBrokenStation")
        
        let bikeRange = initialString.range(of: "🚲")
        
        mutableAttribString.replaceCharacters(in: bikeRange, with: NSAttributedString(attachment: bikeTextAttachment))
        
        let closeRange = initialString.range(of: "🚳")
        
        if self.gbfsStationInformation?.stationStatus?.isRenting == false ||
            self.gbfsStationInformation?.stationStatus?.isInstalled == false
        {
            mutableAttribString.replaceCharacters(in: closeRange, with: NSAttributedString(attachment: stationClosedTextAttachment))
        }
        else if self.gbfsStationInformation?.stationStatus?.numberOfBikesDisabled ?? 0 > 0
            
        {
            mutableAttribString.replaceCharacters(in: closeRange, with: NSAttributedString(attachment: brokenBikeTextAttachment))
        }
        
        let emptySlotRange = initialString.range(of: "🆓")
        mutableAttribString.replaceCharacters(in: emptySlotRange, with: NSAttributedString(attachment: emptySlotTextAttachment))
        
        let brokenSlotRange = initialString.range(of: "⛔️")
        mutableAttribString.replaceCharacters(in: brokenSlotRange, with: NSAttributedString(attachment: brokenSlotTextAttachment))
        
        return mutableAttribString
        
    }
}
