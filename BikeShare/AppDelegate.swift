//
//  AppDelegate.swift
//  BikeShare
//
//  Created by B Gay on 12/23/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    let userManager = UserManager()
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.preferredDisplayMode = .allVisible
        if splitViewController.traitCollection.userInterfaceIdiom == .phone
        {
            splitViewController.preferredDisplayMode = .primaryHidden
        }
        splitViewController.maximumPrimaryColumnWidth = 320
        self.window?.tintColor = .app_blue
        
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.navigationBar.barTintColor = .app_beige
        splitViewController.delegate = self
        
        let store = NSUbiquitousKeyValueStore.default()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateKVStoreItems(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
        
        WatchSessionManager.sharedManager.startSession()
        HistoryNetworksManager.shared.getHistoryNetworks()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: - URL
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        guard let deeplink = Deeplink(url: url) else { return false }
        self.handleDeeplink(deeplink: deeplink)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool
    {
        switch userActivity.activityType
        {
        case NSUserActivityTypeBrowsingWeb:
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                  let deeplink = Deeplink(url: userActivity.webpageURL!)
            else
            {
                restorationHandler(nil)
                return false
            }
            self.handleDeeplink(deeplink: deeplink)
            restorationHandler(nil)
            return true
        case CSSearchableItemActionType:
            guard let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: uniqueIdentifier),
                let deeplink = Deeplink(url: url)
                else
            {
                restorationHandler(nil)
                return false
            }
            self.handleDeeplink(deeplink: deeplink)
            restorationHandler(nil)
            return true
        default:
            restorationHandler(nil)
            return false
        }
        
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void)
    {
        guard let userInfo = shortcutItem.userInfo,
              let dl = userInfo["deeplink"] as? String,
              let url = URL(string: dl),
              let deeplink = Deeplink(url: url)
        else
        {
            completionHandler(false)
            return
        }
        self.handleDeeplink(deeplink: deeplink)
        completionHandler(true)
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
        return true
    }

}

extension AppDelegate
{
    func updateKVStoreItems(notification: Notification)
    {
        let userInfo = notification.userInfo
        guard let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else { return }
        let reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange
        {
            if let changedKeys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            {
                let store = NSUbiquitousKeyValueStore.default()
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
        guard let splitViewController = self.window?.rootViewController as? UISplitViewController else { return }
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
        case .station(let networkID, let stationID):
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
                guard let stationVC = navController.viewControllers[1] as? StationsTableViewController, networkID == stationVC.network.id else
                {
                    _ = navController.popToRootViewController(animated: false)
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
        case .systemInfo(let networkID):
            if navController.presentedViewController != nil
            {
                navController.dismiss(animated: false)
            }
            if let stationVC = navController.topViewController as? StationsTableViewController,
               stationVC.network.id == networkID
            {
                stationVC.handleDeeplink(deeplink)
            }
            else if let mapVC = navController.topViewController as? MapViewController,
                mapVC.network?.id == networkID
            {
                mapVC.handleDeeplink(deeplink: deeplink)
            }
            else if navController.viewControllers.count > 1
            {
                _ = navController.popToRootViewController(animated: false)
            }
            guard let networkVC = navController.viewControllers.first as? NetworkTableViewController else { return }
            networkVC.handleDeeplink(deeplink)
        }
    }
}



