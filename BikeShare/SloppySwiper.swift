//
//  SloppySwiper.swift
//  BikeShare
//
//  Created by B Gay on 4/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import Hero

final class SloppySwiper: NSObject, UINavigationControllerDelegate, UIGestureRecognizerDelegate
{
    weak var panRecognizer: UIPanGestureRecognizer?
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController)
    {
        self.navigationController = navigationController
        super.init()
        let panRecognizer = SloppySwipePanGesture(target: self, action: #selector(self.pan(recognizer:)))
        panRecognizer.direction = .right
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        self.navigationController.view.addGestureRecognizer(panRecognizer)
        self.panRecognizer = panRecognizer
        self.navigationController.delegate = self
        self.navigationController.isHeroEnabled = true
        self.navigationController.heroNavigationAnimationType = .auto
    }
    
    func pan(recognizer: UIPanGestureRecognizer)
    {
        let view = self.navigationController.view
        switch recognizer.state
        {
        case .began:
            if self.navigationController.viewControllers.count > 1
            {
                self.navigationController.popViewController(animated: true)
            }
        case .changed:
            let translation = recognizer.translation(in: view)
            let d = translation.x > 0 ? translation.x / (view?.bounds.width)! : 0.0
            Hero.shared.update(progress: Double(d))
        case .ended, .cancelled:
            if recognizer.velocity(in: view).x > 0
            {
                DispatchQueue.main.async
                {
                    Hero.shared.end()
                }
            } else
            {
                Hero.shared.cancel()
            }
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return self.navigationController.viewControllers.count > 1
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool)
    {
        if navigationController.viewControllers.count <= 1
        {
            self.panRecognizer?.isEnabled = false
        }
        else
        {
            self.panRecognizer?.isEnabled = true
        }
    }
}

