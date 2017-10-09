//
//
//  Created by Brad Gayman on 10/4/17.
//  Copyright © 2017 Brad Gayman. All rights reserved.
//

import UIKit

// MARK: - PanInteractionControllerDelegate
protocol PanInteractionControllerDelegate: class
{
    func interactiveAnimationDidStart(controller: PanInteractionController)
}

final class PanInteractionController: UIPercentDrivenInteractiveTransition
{
    // MARK: - Types
    enum PanDirection
    {
        case up
        case down
        case left
        case right
        
        init(translation: CGPoint)
        {
            if abs(translation.x) > abs(translation.y)
            {
                if translation.x > 0
                {
                    self = .right
                }
                else
                {
                    self = .left
                }
            }
            else
            {
                if translation.y > 0
                {
                    self = .down
                }
                else
                {
                    self = .up
                }
            }
        }
    }
    
    // MARK: - Properties
    lazy var pan: UIPanGestureRecognizer =
    {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(pan:)))
        pan.delegate = self
        return pan
    }()
    
    var panDirection = PanDirection.right
    weak var delegate: PanInteractionControllerDelegate?
    
    var isActive: Bool
    {
        return pan.state != .possible && pan.state != .failed
    }
    
    // MARK: - Public Methods
    func attach(to view: UIView)
    {
        view.addGestureRecognizer(pan)
    }
    
    // MARK: - Actions
    @objc
    private func handlePan(pan: UIPanGestureRecognizer)
    {
        guard let view = pan.view else { return }
        let translation = pan.translation(in: view)
        switch pan.state
        {
        case .began:
            let direction = PanDirection(translation: translation)
            if direction == self.panDirection
            {
                delegate?.interactiveAnimationDidStart(controller: self)
                let progress = self.progress(with: translation)
                update(progress)
            }
        case .changed:
            let progress = self.progress(with: translation)
            update(progress)
        case .ended:
            let velocity = pan.velocity(in: view)
            let isCanceled = self.isCanceled(with: velocity)
            if isCanceled
            {
                cancel()
            }
            else
            {
                finish()
            }
        case .cancelled, .failed:
            cancel()
        case .possible:
            break
        }
    }
    
    // MARK: - Helpers
    private func isCanceled(with velocity: CGPoint) -> Bool
    {
        let isCanceled: Bool
        switch panDirection
        {
        case .up:
            isCanceled = velocity.y >= 0.0
        case .down:
            isCanceled = velocity.y <= 0.0
        case .left:
            isCanceled = velocity.x >= 0.0
        case .right:
            isCanceled = velocity.x <= 0.0
        }
        return isCanceled
    }
    
    private func progress(with translation: CGPoint) -> CGFloat
    {
        guard let view = pan.view else { return 0.0 }
        let progress: CGFloat
        switch panDirection
        {
        case .up:
            let change = max(0.0, -translation.y)
            progress = change / view.bounds.height
        case .down:
            let change = max(0.0, translation.y)
            progress = change / view.bounds.height
        case .left:
            let change = max(0.0, -translation.x)
            progress = change / view.bounds.width
        case .right:
            let change = max(0.0, translation.x)
            progress = change / view.bounds.width
        }
        return progress
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PanInteractionController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return otherGestureRecognizer is UIPanGestureRecognizer
    }
}
