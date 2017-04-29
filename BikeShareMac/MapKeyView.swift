//
//  MapKeyView.swift
//  BikeShare
//
//  Created by Brad G. on 3/11/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa


class MapKeyView: NSView
{
    var pinHeight: CGFloat = 30
    var pinWidth: CGFloat
    {
        return pinHeight / 3.0
    }
    
    lazy var stackView: NSStackView =
    {
        let stackView = NSStackView(views: [self.greenPin, self.greenLabel, self.orangePin, self.orangeLabel, self.redPin, self.redLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.greenLabel.widthAnchor.constraint(equalTo: self.orangeLabel.widthAnchor).isActive = true
        self.greenLabel.widthAnchor.constraint(equalTo: self.redLabel.widthAnchor).isActive = true
        
        self.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        return stackView
    }()
    
    lazy var greenPin: PinView =
    {
        let greenPin = PinView(frame: NSRect(x: 0, y: 0, width: 20, height: 60))
        greenPin.translatesAutoresizingMaskIntoConstraints = false
        greenPin.pinTintColor = NSColor.app_green
        greenPin.widthAnchor.constraint(equalToConstant: self.pinWidth).isActive = true
        greenPin.heightAnchor.constraint(equalToConstant: self.pinHeight).isActive = true
        return greenPin
    }()
    
    lazy var orangePin: PinView =
    {
        let orangePin = PinView(frame: NSRect(x: 0, y: 0, width: 20, height: 60))
        orangePin.translatesAutoresizingMaskIntoConstraints = false
        orangePin.pinTintColor = NSColor.app_orange
        orangePin.widthAnchor.constraint(equalToConstant: self.pinWidth).isActive = true
        orangePin.heightAnchor.constraint(equalToConstant: self.pinHeight).isActive = true
        return orangePin
    }()
    
    lazy var redPin: PinView =
    {
        let redPin = PinView(frame: NSRect(x: 0, y: 0, width: 20, height: 60))
        redPin.translatesAutoresizingMaskIntoConstraints = false
        redPin.pinTintColor = NSColor.app_red
        redPin.widthAnchor.constraint(equalToConstant: self.pinWidth).isActive = true
        redPin.heightAnchor.constraint(equalToConstant: self.pinHeight).isActive = true
        return redPin
    }()
    
    lazy var greenLabel: NSTextField =
    {
        let greenLabel = NSTextField(wrappingLabelWithString: "Good mix of bikes and empty slots")
        greenLabel.translatesAutoresizingMaskIntoConstraints = false
        greenLabel.alignment = .center
        greenLabel.font = NSFont.systemFont(ofSize: 10.0)
        return greenLabel
    }()
    
    lazy var orangeLabel: NSTextField =
    {
        let orangeLabel = NSTextField(wrappingLabelWithString: "Approaching full or empty")
        orangeLabel.translatesAutoresizingMaskIntoConstraints = false
        orangeLabel.alignment = .center
        orangeLabel.font = NSFont.systemFont(ofSize: 10.0)
        return orangeLabel
    }()
    
    lazy var redLabel: NSTextField =
    {
        let redLabel = NSTextField(wrappingLabelWithString: "Station is full or empty")
        redLabel.translatesAutoresizingMaskIntoConstraints = false
        redLabel.alignment = .center
        redLabel.font = NSFont.systemFont(ofSize: 10.0)
        return redLabel
    }()
    
    lazy var visualEffectView: NSVisualEffectView =
    {
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 80, height: 300))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(visualEffectView)
        
        visualEffectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        return visualEffectView
    }()
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        self.commonInit()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        self.commonInit()
    }
    
    func commonInit()
    {
        self.wantsLayer = true
        self.visualEffectView.blendingMode = .withinWindow
        self.stackView.alignment = .centerX
        self.stackView.spacing = 4.0
        self.stackView.orientation = .horizontal
        self.stackView.distribution = .fill
        self.layer?.cornerRadius = 8.0
        self.layer?.masksToBounds = true
    }
}
