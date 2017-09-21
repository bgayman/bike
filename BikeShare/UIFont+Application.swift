//
//  UIFont+Application.swift
//  BikeShare
//
//  Created by B Gay on 1/8/17.
//  Copyright © 2017 B Gay. All rights reserved.
//
#if os(macOS)
import AppKit

extension NSFont
{
    static let app_fontName = "AvenirNext-Medium"
    static let app_titleFont = NSFont(name: NSFont.app_fontName, size: 20.0)!
    
    static func app_font(size: CGFloat) -> NSFont
    {
        let font = NSFont(name: app_fontName, size: size)!
        return font
    }
}
#else
import UIKit

extension UIFont
{
    @objc static let app_fontName = "AvenirNext-Medium"
    
    @objc static func app_font(forTextStyle textStyle: UIFontTextStyle) -> UIFont
    {
        let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)
        return preferredFont
    }
    
    @objc static func app_font(forTextStyle textStyle: UIFontTextStyle, weight: UIFont.Weight) -> UIFont
    {
        let preferredFont = UIFont.preferredFont(forTextStyle: textStyle)
        let font = UIFont.systemFont(ofSize: preferredFont.pointSize, weight: weight)
        return font
    }
}
#endif
