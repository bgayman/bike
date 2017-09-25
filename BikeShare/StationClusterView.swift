//
//  StationClusterView.swift
//  BikeShare
//
//  Created by B Gay on 9/9/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import MapKit

class StationClusterView: MKAnnotationView
{
    lazy var countLabel: UILabel =
    {
        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(countLabel)
        countLabel.minimumScaleFactor = 0.25
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        countLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 14.0).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -14.0).isActive = true
        #if !os(tvOS)
            countLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        #else
            countLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        #endif
        countLabel.textAlignment = .center
        return countLabel
    }()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?)
    {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -10)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation?
    {
        willSet
        {
            guard let cluster = newValue as? MKClusterAnnotation,
                  let annotations = cluster.memberAnnotations as? [MapBikeStation] else { return }
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
            countLabel.text = "\(cluster.memberAnnotations.count)"
            let count = CGFloat(cluster.memberAnnotations.count)
            let redCount = CGFloat(annotations.filter { $0.bikeStation.pinTintColor == .app_red }.count)
            let orangeCount = CGFloat(annotations.filter { $0.bikeStation.pinTintColor == .app_orange }.count)
            let greenCount = CGFloat(annotations.filter { $0.bikeStation.pinTintColor == .app_green }.count)
            image = renderer.image
            { (_) in
                UIColor.app_red.setFill()
                let redPath = UIBezierPath()
                redPath.addArc(withCenter: CGPoint(x: 20, y: 20), radius: 20,
                               startAngle: 0, endAngle: (CGFloat.pi * 2.0 * redCount) / count,
                               clockwise: true)
                redPath.addLine(to: CGPoint(x: 20, y: 20))
                redPath.close()
                redPath.fill()
                
                UIColor.app_orange.setFill()
                let orangePath = UIBezierPath()
                let orangeStart = (CGFloat.pi * 2.0 * redCount) / count
                orangePath.addArc(withCenter: CGPoint(x: 20, y: 20), radius: 20,
                               startAngle: orangeStart,
                               endAngle: (CGFloat.pi * 2.0 * orangeCount) / count + orangeStart,
                               clockwise: true)
                orangePath.addLine(to: CGPoint(x: 20, y: 20))
                orangePath.close()
                orangePath.fill()
                
                UIColor.app_green.setFill()
                let greenPath = UIBezierPath()
                let greenStart = (CGFloat.pi * 2.0 * orangeCount) / count + orangeStart
                greenPath.addArc(withCenter: CGPoint(x: 20, y: 20), radius: 20,
                                  startAngle: greenStart,
                                  endAngle: (CGFloat.pi * 2.0 * greenCount) / count + greenStart,
                                  clockwise: true)
                greenPath.addLine(to: CGPoint(x: 20, y: 20))
                greenPath.close()
                greenPath.fill()
                
                UIColor.app_beige.setFill()
                UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 24, height: 24)).fill()
            }
        }
    }
}
