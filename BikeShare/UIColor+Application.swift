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
    static let app_green = NSColor(hex: 0x5cce6f)
    static let app_red = NSColor(hex: 0xf41411)
    static let app_orange = NSColor.orange
    static let app_sandyBrown = NSColor(hex: 0xf6b530)
    static let app_beige = NSColor(hex: 0xf8f5f1)
    static let app_lightBlue = NSColor(hex: 0xaadced)
    static let app_brown = NSColor(hex: 0x5b3b1c)
    
    convenience init(hex:Int)
    {
        let redComponent = CGFloat((hex >> 16 & 0xFF)) / 255.0
        let greenComponent = CGFloat((hex >> 8 & 0xFF)) / 255.0
        let blueComponent = CGFloat((hex & 0xFF)) / 255.0
        let alpha:CGFloat = 1.0
        self.init(red: redComponent, green: greenComponent, blue: blueComponent, alpha: alpha)
    }
}
#else
import UIKit

extension UIColor
{
    @objc static let app_blue = UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    @objc static let app_green = UIColor(hex: 0x5cce6f)
    @objc static let app_red = UIColor(hex: 0xf41411)
    @objc static let app_orange = UIColor.orange
    @objc static let app_sandyBrown = UIColor(hex: 0xf6b530)
    @objc static let app_beige = UIColor(hex: 0xf8f5f1)
    @objc static let app_lightBlue = UIColor(hex: 0xaadced)
    @objc static let app_brown = UIColor(hex: 0x5b3b1c)
    
    @objc convenience init(hex:Int)
    {
        let redComponent = CGFloat((hex >> 16 & 0xFF)) / 255.0
        let greenComponent = CGFloat((hex >> 8 & 0xFF)) / 255.0
        let blueComponent = CGFloat((hex & 0xFF)) / 255.0
        let alpha:CGFloat = 1.0
        self.init(red: redComponent, green: greenComponent, blue: blueComponent, alpha: alpha)
    }
}
#endif
