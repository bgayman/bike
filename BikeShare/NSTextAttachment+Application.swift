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
        
        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y - height * 0.15, width: ratio * height, height: height)
    }
}
