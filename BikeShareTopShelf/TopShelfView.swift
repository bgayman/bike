//
//  TopShelfView.swift
//  BikeShare
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class TopShelfView: UIView
{
    lazy var imageView: UIImageView =
        {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(imageView)
            imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            imageView.contentMode = .scaleAspectFill
            return imageView
    }()
    
    lazy var pinView: PinView =
        {
            let pinView = PinView(frame: CGRect.zero)
            pinView.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(pinView, aboveSubview: self.imageView)
            pinView.topAnchor.constraint(equalTo: self.topAnchor, constant: 60.0).isActive = true
            pinView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.1).isActive = true
            pinView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            pinView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -60.0).isActive = true
            pinView.isOpaque = false
            pinView.backgroundColor = .clear
            pinView.contentMode = .redraw
            pinView.layer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
            pinView.layer.shadowRadius = 8.0
            pinView.layer.shadowOpacity = 0.25
            pinView.layer.shadowOffset = CGSize(width: 8.0, height: 8.0)
            return pinView
    }()
    
    lazy var titleLabel: UILabel =
        {
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont.app_font(forTextStyle: .title1)
            self.insertSubview(titleLabel, aboveSubview: self.pinView)
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 60.0).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 60.0).isActive = true
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.pinView.leadingAnchor, constant: -8.0).isActive = true
            titleLabel.layer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
            titleLabel.layer.shadowRadius = 8.0
            titleLabel.layer.shadowOpacity = 0.25
            titleLabel.layer.shadowOffset = CGSize(width: 8.0, height: 8.0)
            return titleLabel
    }()
    
    lazy var subtitleLabel: UILabel =
        {
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont.app_font(forTextStyle: .title2)
            self.insertSubview(titleLabel, aboveSubview: self.titleLabel)
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -60.0).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -60.0).isActive = true
            titleLabel.textAlignment = .right
            titleLabel.layer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
            titleLabel.layer.shadowRadius = 8.0
            titleLabel.layer.shadowOpacity = 0.25
            titleLabel.layer.shadowOffset = CGSize(width: 8.0, height: 8.0)
            return titleLabel
    }()
    
    init(title: String, subtitle: String, pinColor: UIColor? = nil)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 1940, height: 692))
        self.backgroundColor = .white
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
        if let pinColor = pinColor
        {
            self.pinView.pinTintColor = pinColor
        }
        self.pinView.setNeedsDisplay()
        let rand = arc4random_uniform(5)
        switch rand
        {
        case 0:
            self.imageView.image = UIImage(named: "brooklyn.png")
        case 1:
            self.imageView.image = UIImage(named: "LA.png")
        case 2:
            self.imageView.image = UIImage(named: "london.png")
        case 3:
            self.imageView.image = UIImage(named: "sanFrancisco.png")
        case 4:
            self.imageView.image = UIImage(named: "toronto.png")
        default:
            break
        }
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = [UIColor(white: 1, alpha: 0.15).cgColor, UIColor(white: 1, alpha: 0.95).cgColor, UIColor(white: 1, alpha: 0.15).cgColor]
        self.imageView.layer.mask = gradient
    }
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
