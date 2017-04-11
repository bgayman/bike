//
//  UIColor+Application.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

#if os(macOS)
import AppKit

extension NSColor
{
    static let app_blue = NSColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    static let app_green = NSColor(red: 91.0/255.0 , green: 221.0/255.0, blue: 103.0/255.0, alpha: 1.0)
}
#else
import UIKit

extension UIColor
{
    static let app_blue = UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    static let app_green = UIColor(red: 91.0/255.0 , green: 221.0/255.0, blue: 103.0/255.0, alpha: 1.0)
}
#endif
