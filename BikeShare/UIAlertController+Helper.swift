//
//  UIAlertController+Helper.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit

extension UIAlertController
{
    @objc convenience init(errorMessage: String)
    {
        self.init(title: "🙈", message: errorMessage)
    }
    
    @objc convenience init(title: String, message: String)
    {
        self.init(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default)
        self.addAction(action)
    }
}
