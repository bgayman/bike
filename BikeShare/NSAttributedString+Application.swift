//
//  NSAttributedString+Application.swift
//  BikeShare
//
//  Created by B Gay on 5/18/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

extension NSAttributedString
{
    @objc public var mutable: NSMutableAttributedString
    {
        return mutableCopy() as! NSMutableAttributedString
    }
    
    @objc public var range: NSRange
    {
        return NSRange(location: 0, length: (string as NSString).length)
    }
    
    @objc public convenience init(string: String, alignment: NSTextAlignment)
    {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.alignment = alignment
        self.init(string: string, attributes: [NSAttributedStringKey.paragraphStyle: style])
    }
}

public func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString
{
    let result = lhs.mutable
    result.append(rhs)
    return result
}
