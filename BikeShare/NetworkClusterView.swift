//
//  NetworkClusterView.swift
//  BikeShare
//
//  Created by Brad G. on 9/9/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import MapKit

class NetworkClusterView: MKAnnotationView
{
    lazy var countLabel: UILabel =
    {
        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(countLabel)
        countLabel.minimumScaleFactor = 0.25
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        countLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 14).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -14).isActive = true
        #if !os(tvOS)
            countLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        #else
            countLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        #endif
        countLabel.textColor = .white
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
                let _ = cluster.memberAnnotations as? [MapBikeNetwork] else { return }
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
            let count = cluster.memberAnnotations.count
            countLabel.text = "\(count)"
            image = renderer.image
            { (_) in
                UIColor.app_blue.setFill()
                let bluePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40))
                bluePath.fill()
            }
        }
    }
}
