//
//  DotAnnotationView.swift
//  BikeShare
//
//  Created by B Gay on 9/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import MapKit

class DotAnnotationView: MKAnnotationView
{
    override init(annotation: MKAnnotation?, reuseIdentifier: String?)
    {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: 0)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation?
    {
        willSet
        {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 5, height: 5))
            image = renderer.image
            { (_) in
                UIColor.app_blue.withAlphaComponent(0.2).setFill()
                let bluePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 5, height: 5))
                bluePath.fill()
            }
        }
    }
}
