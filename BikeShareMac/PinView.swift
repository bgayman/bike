//
//  PinView.swift
//  BikeShare
//
//  Created by Brad G. on 3/11/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

class PinView: NSView
{
    var pinTintColor = NSColor.red
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        let shaftRect = CGRect(x: self.bounds.midX - self.bounds.width * 0.05, y: self.bounds.height * 0.05, width: self.bounds.width * 0.1, height: self.bounds.height * 0.9)
        let pinShadow = NSBezierPath(ovalIn: CGRect(x: self.bounds.midX - shaftRect.width * 0.75, y: shaftRect.minY - self.bounds.height * 0.02, width: shaftRect.width * 1.5, height: self.bounds.height * 0.04))
        pinShadow.fill()
        
        let shaft =  NSBezierPath(roundedRect: shaftRect, xRadius: shaftRect.width * 0.5, yRadius: shaftRect.width * 0.5)
        shaft.lineWidth = 0.25
        NSColor.black.setStroke()
        NSColor.lightGray.setFill()
        shaft.stroke()
        shaft.fill()
        
        let bulbRect = CGRect(x: 0.5, y: self.bounds.height - 0.5 - (self.bounds.width - 1.0), width: self.bounds.width - 1.0, height: self.bounds.width - 1.0)
        let bulb = NSBezierPath(ovalIn: bulbRect)
        self.pinTintColor.setFill()
        bulb.fill()
        
        let bulbHighlight = NSBezierPath(ovalIn: CGRect(x: bulbRect.midX - self.bounds.width * 0.3, y: bulbRect.midY + self.bounds.width * 0.3 - self.bounds.width * 0.2, width: self.bounds.width * 0.2, height: self.bounds.width * 0.2))
        NSColor.white.setFill()
        bulbHighlight.fill()
    }
}

