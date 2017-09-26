//
//  DrawerScrollView.swift
//  BikeShare
//
//  Created by B Gay on 9/25/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class DrawerScrollView: UIScrollView
{

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if CGRect(x: 0.0, y: -20.0 - contentOffset.y, width: bounds.width, height: 20.0 + contentOffset.y + frame.height).contains(point)
        {
            return true
        }
        return super.point(inside: point, with: event)
    }

}
