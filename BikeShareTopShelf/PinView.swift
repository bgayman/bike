//
//  PinView.swift
//  BikeShare
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class PinView: UIView
{
    var pinTintColor = UIColor.red
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        let shaftRect = CGRect(x: self.bounds.midX - self.bounds.width * 0.05, y: self.bounds.height * 0.05, width: self.bounds.width * 0.1, height: self.bounds.height * 0.9)
        
        let pinShadow = UIBezierPath(ovalIn: CGRect(x: self.bounds.midX - shaftRect.width * 0.75, y: shaftRect.maxY - self.bounds.height * 0.02, width: shaftRect.width * 1.5, height: self.bounds.height * 0.04))
        pinShadow.fill()
        
        let shaft =  UIBezierPath(roundedRect: shaftRect, cornerRadius: shaftRect.width * 0.5)
        shaft.lineWidth = 0.25
        UIColor.black.setStroke()
        UIColor.lightGray.setFill()
        shaft.stroke()
        shaft.fill()
        
        let bulbRect = CGRect(x: 0.5, y: 0.5, width: self.bounds.width - 1.0, height: self.bounds.width - 1.0)
        let bulb = UIBezierPath(ovalIn: bulbRect)
        self.pinTintColor.setFill()
        bulb.fill()
        
        let bulbHighlight = UIBezierPath(ovalIn: CGRect(x: bulbRect.midX - self.bounds.width * 0.3, y: bulbRect.midY - self.bounds.width * 0.3, width: self.bounds.width * 0.2, height: self.bounds.width * 0.2))
        UIColor.white.setFill()
        bulbHighlight.fill()
    }
}
