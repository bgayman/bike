//
//  MenuSplitViewController.swift
//  BikeShare
//
//  Created by Brad G. on 1/7/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class MenuSplitViewController: UISplitViewController
{
    // MARK: Properties
    
    /**
     Set to true from `updateFocusToMasterViewController()` to indicate that
     the detail view controller should be the preferred focused view when
     this view controller is next queried.
     */
    private var preferMasterViewControllerOnNextFocusUpdate = false
    private var preferDetailViewControllerOnNextFocusUpdate = false
    
    // MARK: UIFocusEnvironment
    
    override var preferredFocusEnvironments: [UIFocusEnvironment]
    {
        let environments: [UIFocusEnvironment]
        
        /*
         Check if a request has been made to move the focus to the detail
         view controller.
         */
        if preferMasterViewControllerOnNextFocusUpdate, let masterViewController = viewControllers.first
        {
            environments = masterViewController.preferredFocusEnvironments
            preferMasterViewControllerOnNextFocusUpdate = false
        }
        else if preferDetailViewControllerOnNextFocusUpdate, let detailViewController = viewControllers.last as? MapViewController
        {
            environments = detailViewController.preferredFocusEnvironments
            preferDetailViewControllerOnNextFocusUpdate = false
        }
        else {
            environments = super.preferredFocusEnvironments
        }
        
        return environments
    }
    
    // MARK: Focus helpers
    
    /**
     Called from a containing `MenuTableViewController` whenever the user
     selects a table view row in a master view controller.
     */
    @objc func updateFocusToMasterViewController()
    {
        preferMasterViewControllerOnNextFocusUpdate = true
        
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
    
    @objc func updateFocusToDetailViewController()
    {
        preferDetailViewControllerOnNextFocusUpdate = true
        
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
}
