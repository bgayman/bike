//
//  VZSlideTransitionController.swift
//  ViewZyme
//
//  Created by App Partner on 10/4/17.
//  Copyright © 2017 AppPartner. All rights reserved.
//

import UIKit

final class SlideTransitionController: NSObject
{
    enum PresentingSlideDirection
    {
        case right
        case left
        case up
        case down
    }
    
    let duration: TimeInterval
    let isAppearing: Bool
    var transitionContext: UIViewControllerContextTransitioning?
    let alphaFadeTo: CGFloat = 0.5
    let presentingSlideDirection: PresentingSlideDirection
    
    init(duration: TimeInterval = 0.25,  isAppearing: Bool, presentingSlideDirection: SlideTransitionController.PresentingSlideDirection)
    {
        self.presentingSlideDirection = presentingSlideDirection
        self.duration = duration
        self.isAppearing = isAppearing
        super.init()
    }
    
    fileprivate func finishDismissTransition()
    {
        guard let transitionContext = self.transitionContext,
              let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else { return }

        let toView = toVC.view
        let fromView = fromVC.view
        let containerView = transitionContext.containerView
        
        UIView.animate(withDuration: duration, animations:
        {
            toView?.alpha = 1.0
            toView?.frame = transitionContext.finalFrame(for: toVC)
            var fromFrame = fromView?.frame
            switch self.presentingSlideDirection
            {
            case .up:
                fromFrame?.origin.y = containerView.frame.height
            case .left:
                fromFrame?.origin.x = containerView.frame.width
            case .down:
                fromFrame?.origin.y = -containerView.frame.height
            case .right:
                fromFrame?.origin.x = -containerView.frame.width
            }
            
            fromView?.frame = fromFrame ?? .zero
        })
        { (finished) in
            let wasCancelled = transitionContext.transitionWasCancelled
            let didComplete = finished && wasCancelled == false
            if didComplete
            {
                fromView?.removeFromSuperview()
            }
            toView?.isUserInteractionEnabled = true
            transitionContext.completeTransition(didComplete)
        }
    }
}

extension SlideTransitionController: UIViewControllerAnimatedTransitioning
{
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        self.transitionContext = transitionContext
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromView = fromVC.view,
            let toView = toVC.view else { return }
        
        let containerView = transitionContext.containerView
        let duration = self.transitionDuration(using: transitionContext)
        
        if self.isAppearing
        {
            var toViewInitialFrame = transitionContext.containerView.frame
            switch self.presentingSlideDirection
            {
            case .up:
                toViewInitialFrame.origin.y = containerView.frame.height
            case .left:
                toViewInitialFrame.origin.x = containerView.frame.width
            case .down:
                toViewInitialFrame.origin.y = -containerView.frame.height
            case .right:
                toViewInitialFrame.origin.x = -containerView.frame.width
            }
            toView.frame = toViewInitialFrame
            toView.layer.shadowOpacity = 0.2
            toView.layer.shadowRadius = 30.0
            if let navVC = toVC as? UINavigationController
            {
                navVC.topViewController?.view.layoutIfNeeded()
            }
            else
            {
                toView.layoutIfNeeded()
            }
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: duration, animations:
            {
                toView.frame = transitionContext.finalFrame(for: toVC)
                fromView.frame = transitionContext.finalFrame(for: fromVC)
                fromView.alpha = self.alphaFadeTo
            },
            completion:
            { (finished) in
                let wasCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(finished && wasCancelled == false)
            })
        }
        else
        {
            finishDismissTransition()
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return duration
    }
}


