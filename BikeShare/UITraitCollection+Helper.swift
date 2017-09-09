//
//  UITraitCollection+Helper.swift
//  BikeShare
//
//  Created by B Gay on 12/27/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit

extension UITraitCollection
{
    @objc var isSmallerDevice: Bool
    {
        return self.horizontalSizeClass == .compact || self.verticalSizeClass == .compact
    }
}
