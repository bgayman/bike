//
//  SloppySwipePanGesture.swift
//  BikeShare
//
//  Created by B Gay on 4/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

enum PanDirection: Int
{
    case right
    case down
    case left
    case up
}

final class SloppySwipePanGesture: UIPanGestureRecognizer
{
    private var isDragging = false
    var direction: PanDirection = .left
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesMoved(touches, with: event)
        guard self.state != .failed else { return }
        let velocity = self.velocity(in: self.view)
        guard self.isDragging && velocity != .zero else { return }
        let velocities: [CGFloat: PanDirection] = [velocity.x: .right, velocity.y: .down, -velocity.x: .left, -velocity.y: .up]
        let sortedKeys = velocities.keys.sorted()
        if velocities[sortedKeys.last ?? 0.0] != self.direction
        {
            self.state = .failed
        }
        self.isDragging = true
    }
    
    override func reset()
    {
        super.reset()
        self.isDragging = false
    }
}
