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
            image = renderer.image
            { (_) in
                UIColor.app_blue.setFill()
                let bluePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40))
                bluePath.fill()
                
                let attributes = [ NSAttributedStringKey.foregroundColor: UIColor.white,
                                   NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 13)]
                let text = "\(count)"
                let size = text.size(withAttributes: attributes)
                let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
                text.draw(in: rect, withAttributes: attributes)
            }
        }
    }
}
