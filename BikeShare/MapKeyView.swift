//
//  MapKeyView.swift
//  BikeShare
//
//  Created by Brad G. on 3/4/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class MapKeyView: UIView
{
    lazy var visualEffectView: UIVisualEffectView =
    {
        let blurEffect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.layer.cornerRadius = 8.0
        visualEffectView.layer.masksToBounds = true
        self.addSubview(visualEffectView)
        visualEffectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        return visualEffectView
    }()
    
    lazy var greenPin: PinView =
    {
        let greenPin = PinView(frame: CGRect(x: 0, y: 0, width: 20, height: 60))
        greenPin.backgroundColor = .clear
        greenPin.isOpaque = false
        greenPin.translatesAutoresizingMaskIntoConstraints = false
        greenPin.pinTintColor = UIColor.app_green
        greenPin.widthAnchor.constraint(equalToConstant: 20).isActive = true
        greenPin.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return greenPin
    }()
    
    lazy var orangePin: PinView =
    {
        let orangePin = PinView(frame: CGRect(x: 0, y: 0, width: 20, height: 60))
        orangePin.backgroundColor = .clear
        orangePin.isOpaque = false
        orangePin.translatesAutoresizingMaskIntoConstraints = false
        orangePin.pinTintColor = UIColor.app_orange
        orangePin.widthAnchor.constraint(equalToConstant: 20).isActive = true
        orangePin.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return orangePin
    }()
    
    lazy var redPin: PinView =
    {
        let redPin = PinView(frame: CGRect(x: 0, y: 0, width: 20, height: 60))
        redPin.backgroundColor = .clear
        redPin.isOpaque = false
        redPin.translatesAutoresizingMaskIntoConstraints = false
        redPin.pinTintColor = UIColor.app_red
        redPin.widthAnchor.constraint(equalToConstant: 20).isActive = true
        redPin.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return redPin
    }()
    
    lazy var greenLabel: UILabel =
    {
        let greenLabel = UILabel()
        greenLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        greenLabel.textColor = .white
        greenLabel.textAlignment = .center
        greenLabel.translatesAutoresizingMaskIntoConstraints = false
        greenLabel.text = "Good mix\nof bikes\nand empty\nslots"
        greenLabel.numberOfLines = 0
        return greenLabel
    }()
    
    lazy var orangeLabel: UILabel =
    {
        let orangeLabel = UILabel()
        orangeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        orangeLabel.textColor = .white
        orangeLabel.textAlignment = .center
        orangeLabel.translatesAutoresizingMaskIntoConstraints = false
        orangeLabel.text = "Approach-\ning full\nor empty"
        orangeLabel.numberOfLines = 0
        return orangeLabel
    }()
    
    lazy var redLabel: UILabel =
    {
        let redLabel = UILabel()
        redLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        redLabel.textColor = .white
        redLabel.textAlignment = .center
        redLabel.translatesAutoresizingMaskIntoConstraints = false
        redLabel.text = "Station\nis full\nor empty"
        redLabel.numberOfLines = 0
        return redLabel
    }()
    
    lazy var stackView: UIStackView =
    {
        let stackView = UIStackView(arrangedSubviews: [self.greenPin, self.greenLabel, self.orangePin, self.orangeLabel, self.redPin, self.redLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.visualEffectView.contentView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.visualEffectView.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.visualEffectView.contentView.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.visualEffectView.contentView.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.visualEffectView.contentView.bottomAnchor).isActive = true
        return stackView
    }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit()
    {
        self.backgroundColor = .clear
        self.stackView.axis = .horizontal
        self.stackView.alignment = .center
        self.stackView.spacing = 4.0
        self.greenLabel.widthAnchor.constraint(equalTo: self.orangeLabel.widthAnchor).isActive = true
        self.greenLabel.widthAnchor.constraint(equalTo: self.redLabel.widthAnchor).isActive = true
    }
}
