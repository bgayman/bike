//
//  AppDelegate.swift
//  BikeShareTV
//
//  Created by Brad G. on 1/7/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    let userManager = UserManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.minimumPrimaryColumnWidth = 800
        
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        let store = NSUbiquitousKeyValueStore.default
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateKVStoreItems(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
        
        HistoryNetworksManager.shared.getHistoryNetworks()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        guard let deeplink = Deeplink(url: url) else { return false }
        self.handleDeeplink(deeplink: deeplink)
        return true
    }

    // MARK: - Split view
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
        return true
    }
    
    @objc func updateKVStoreItems(notification: Notification)
    {
        let userInfo = notification.userInfo
        guard let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else { return }
        let reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange
        {
            if let changedKeys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            {
                let store = NSUbiquitousKeyValueStore.default
                let userDefaults = UserDefaults.bikeShareGroup
                for key in changedKeys
                {
                    let value = store.object(forKey: key)
                    userDefaults.set(value, forKey: key)
                }
            }
        }
    }
    
    func handleDeeplink(deeplink: Deeplink)
    {
        guard let splitViewController = self.window?.rootViewController as? MenuSplitViewController else { return }
        guard let navController = splitViewController.viewControllers.first as? UINavigationController else { return }
        
        switch deeplink
        {
        case .network:
            if navController.presentedViewController != nil
            {
                navController.dismiss(animated: false)
            }
            guard let networkVC = navController.viewControllers.first as? NetworkTableViewController else { return }
            navController.popToRootViewController(animated: true)
            networkVC.handleDeeplink(deeplink)
        case .station(_, let stationID):
            if navController.presentedViewController != nil
            {
                navController.dismiss(animated: false)
            }
            if navController.viewControllers.count > 1
            {
                if let stationDetailVC = navController.topViewController as? StationDetailViewController
                {
                    guard stationDetailVC.station.id != stationID else
                    {
                        stationDetailVC.fetchStations()
                        return
                    }
                    _ = navController.popToViewController(navController.viewControllers[1], animated: false)
                    
                }
                guard let stationVC = navController.viewControllers[1] as? StationsTableViewController else
                {
                    guard let networkVC = navController.viewControllers.first as? NetworkTableViewController else { return }
                    networkVC.handleDeeplink(deeplink)
                    return
                }
                stationVC.handleDeeplink(deeplink)
            }
            else
            {
                guard let networkVC = navController.viewControllers.first as? NetworkTableViewController else { return }
                networkVC.handleDeeplink(deeplink)
            }
        case .systemInfo:
            break
        }
    }
}

