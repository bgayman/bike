//
//  DispatchQueue+Helper.swift
//  BikeShare
//
//  Created by B Gay on 12/25/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation

extension DispatchQueue
{
    func delay(_ delay:Double, closure:@escaping ()->())
    {
        let when = DispatchTime.now() + delay
        self.asyncAfter(deadline: when, execute: closure)
    }
}
