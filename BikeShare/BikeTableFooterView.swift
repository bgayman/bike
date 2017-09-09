//
//  BikeTableFooterView.swift
//  BikeShare
//
//  Created by B Gay on 1/8/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class BikeTableFooterView: UITableViewHeaderFooterView
{

    @objc lazy var poweredByButton: UIButton =
    {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        #if !os(tvOS)
        let attribTitle = NSMutableAttributedString(string: "Powered by Citybikes", attributes: [NSAttributedStringKey.font: UIFont.app_font(forTextStyle: .body)])
        let range = (attribTitle.string as NSString).range(of: "Citybikes")
        attribTitle.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.app_blue], range: range)
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = self.contentView.bounds
        shapeLayer.lineWidth = 0.25
        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 8.0, y:0))
        path.addLine(to: CGPoint(x: self.contentView.bounds.maxX, y: 0))
        shapeLayer.path = path.cgPath
        self.contentView.layer.addSublayer(shapeLayer)
        #else
        let attribTitle = NSMutableAttributedString(string: "Powered by Citybikes @ citybik.es", attributes: [NSFontAttributeName: UIFont.app_font(forTextStyle: .body)])
        #endif
        button.setAttributedTitle(attribTitle, for: .normal)
        
        self.contentView.addSubview(button)
        button.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        return button
    }()
    
    override func awakeFromNib()
    {
        
    }
}
