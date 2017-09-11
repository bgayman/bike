//
//  BikeStationDetailScrollView.swift
//  BikeShare
//
//  Created by B Gay on 9/11/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class BikeStationDetailScrollView: UIScrollView
{
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        
        if self.contentOffset.y >= 150.0
        {
            let rect = CGRect(x: 0, y: self.contentSize.height - self.contentOffset.y, width: self.bounds.width, height: self.contentOffset.y)
            if rect.contains(point)
            {
                self.isScrollEnabled = false
            }
            return true
        }
        self.isScrollEnabled = true
        return super.point(inside: point, with: event)
    }
}
