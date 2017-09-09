//
//  UILabel+Sizing.swift
//  BikeShare
//
//  Created by B Gay on 12/25/16.
//  Copyright © 2016 B Gay. All rights reserved.
//
#if os(macOS)
import AppKit

extension NSTextField
{
    static func labelSize(with string: String) -> CGSize
    {
        let label = NSTextField()
        label.font = NSFont.app_font(size: 16.0)
        label.stringValue = string
        label.sizeToFit()
        return label.bounds.size
    }
}
#else
import UIKit

extension UILabel
{
    @objc static func labelSize(with string: String?) -> CGSize
    {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = string
        label.sizeToFit()
        return label.bounds.size
    }
}
#endif
