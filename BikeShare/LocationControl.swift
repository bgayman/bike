//
//  LocationControl.swift
//  BikeShare
//
//  Created by B Gay on 5/7/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

final class LocationControl: UIControl
{
    var color = UIColor.app_blue
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
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
    
    private func commonInit()
    {
        self.backgroundColor = .clear
        self.isOpaque = false
    }
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: self.bounds.midY))
        path.addLine(to: CGPoint(x: self.bounds.maxX, y: 0.0))
        path.addLine(to: CGPoint(x: self.bounds.midX, y: self.bounds.maxY))
        path.addLine(to: CGPoint(x: self.bounds.midX, y: self.bounds.midY))
        path.close()
        path.lineWidth = 1.0
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        self.color.setStroke()
        path.stroke()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.color = self.color.withAlphaComponent(0.5)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.color = self.color.withAlphaComponent(1.0)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.color = self.color.withAlphaComponent(1.0)
        guard let touch = touches.first else { return }
        if self.bounds.contains(touch.location(in: self))
        {
            self.sendActions(for: .touchUpInside)
        }
    }
}
